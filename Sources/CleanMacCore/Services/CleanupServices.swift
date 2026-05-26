import Foundation

public protocol NodeModulesScanning: Sendable {
    func scan(settings: CleanupSettings) async -> [CleanupCandidate]
}

public protocol PracticalCleanupScanning: Sendable {
    func scan(settings: CleanupSettings) async -> [CleanupCandidate]
}

public struct NodeModulesScanner: NodeModulesScanning {
    public init() {}

    public func scan(settings: CleanupSettings) async -> [CleanupCandidate] {
        await Task.detached(priority: .utility) {
            var candidates: [CleanupCandidate] = []
            let ignored = Set(settings.ignoredPaths.map { URL(fileURLWithPath: $0).standardizedFileURL.path })

            for root in settings.nodeSearchRoots {
                let rootURL = URL(fileURLWithPath: root).standardizedFileURL
                guard FileManager.default.fileExists(atPath: rootURL.path) else { continue }

                guard let enumerator = FileManager.default.enumerator(
                    at: rootURL,
                    includingPropertiesForKeys: [.isDirectoryKey, .contentModificationDateKey, .fileSizeKey],
                    options: [.skipsHiddenFiles, .skipsPackageDescendants]
                ) else {
                    continue
                }

                while let url = enumerator.nextObject() as? URL {
                    let standardized = url.standardizedFileURL
                    if ignored.contains(where: { standardized.path.hasPrefix($0) }) {
                        enumerator.skipDescendants()
                        continue
                    }

                    guard standardized.lastPathComponent == "node_modules" else { continue }

                    let size = directorySize(at: standardized)
                    let modified = (try? standardized.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
                    let projectPath = standardized.deletingLastPathComponent().path

                    candidates.append(
                        CleanupCandidate(
                            id: standardized.path,
                            category: .nodeModules,
                            title: standardized.deletingLastPathComponent().lastPathComponent,
                            path: standardized.path,
                            sizeBytes: size,
                            lastModified: modified,
                            risk: .medium,
                            detail: "Project: \(projectPath)"
                        )
                    )
                    enumerator.skipDescendants()
                }
            }

            return candidates.sorted {
                ($0.sizeBytes ?? 0, $0.path ?? "") > ($1.sizeBytes ?? 0, $1.path ?? "")
            }
        }.value
    }

    private static func directorySize(at url: URL) -> UInt64 {
        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.totalFileAllocatedSizeKey, .fileAllocatedSizeKey],
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }

        var total: UInt64 = 0
        for case let fileURL as URL in enumerator {
            let values = try? fileURL.resourceValues(forKeys: [.totalFileAllocatedSizeKey, .fileAllocatedSizeKey])
            let size = values?.totalFileAllocatedSize ?? values?.fileAllocatedSize ?? 0
            total += UInt64(max(size, 0))
        }
        return total
    }

    private func directorySize(at url: URL) -> UInt64 {
        Self.directorySize(at: url)
    }
}

public struct PracticalCleanupScanner: PracticalCleanupScanning {
    private let homeDirectory: String
    private let applicationDirectories: [String]
    private let volumeDirectory: String

    public init(
        homeDirectory: String = FileManager.default.homeDirectoryForCurrentUser.path,
        applicationDirectories: [String] = ["/Applications", "\(FileManager.default.homeDirectoryForCurrentUser.path)/Applications"],
        volumeDirectory: String = "/Volumes"
    ) {
        self.homeDirectory = homeDirectory
        self.applicationDirectories = applicationDirectories
        self.volumeDirectory = volumeDirectory
    }

    public func scan(settings: CleanupSettings) async -> [CleanupCandidate] {
        await Task.detached(priority: .utility) {
            let ignored = Set(settings.ignoredPaths.map { URL(fileURLWithPath: $0).standardizedFileURL.path })
            let largeFiles = scanLargeFiles(settings: settings, ignoredPaths: ignored)
            let trash = scanTrashBins(homeDirectory: homeDirectory, volumeDirectory: volumeDirectory, ignoredPaths: ignored)
            let apps = scanApplications(applicationDirectories: applicationDirectories, ignoredPaths: ignored)
            let loginItems = scanLoginItems(homeDirectory: homeDirectory, ignoredPaths: ignored)
            return CandidateReviewPlanner.sortedCandidates(largeFiles + trash + apps + loginItems)
        }.value
    }
}

private func scanLargeFiles(settings: CleanupSettings, ignoredPaths: Set<String>) -> [CleanupCandidate] {
    let fileManager = FileManager.default
    let cutoff = Calendar.current.date(byAdding: .day, value: -settings.largeFileMinimumAgeDays, to: Date()) ?? .distantPast
    var candidates: [CleanupCandidate] = []

    for rootPath in settings.largeFileSearchRoots {
        let root = URL(fileURLWithPath: rootPath).standardizedFileURL
        guard fileManager.fileExists(atPath: root.path),
              !ignoredPaths.contains(where: { root.path.hasPrefix($0) }),
              let enumerator = fileManager.enumerator(
                at: root,
                includingPropertiesForKeys: [.isRegularFileKey, .contentModificationDateKey, .totalFileAllocatedSizeKey, .fileAllocatedSizeKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
              ) else {
            continue
        }

        while let url = enumerator.nextObject() as? URL {
            let standardized = url.standardizedFileURL
            if ignoredPaths.contains(where: { standardized.path.hasPrefix($0) }) {
                enumerator.skipDescendants()
                continue
            }

            guard let values = try? standardized.resourceValues(forKeys: [.isRegularFileKey, .contentModificationDateKey, .totalFileAllocatedSizeKey, .fileAllocatedSizeKey]),
                  values.isRegularFile == true else {
                continue
            }

            let size = UInt64(max(values.totalFileAllocatedSize ?? values.fileAllocatedSize ?? 0, 0))
            let modified = values.contentModificationDate
            guard size >= settings.largeFileMinimumBytes,
                  let modified,
                  modified <= cutoff else {
                continue
            }

            candidates.append(
                CleanupCandidate(
                    id: "large-file.\(standardized.path)",
                    category: .largeFiles,
                    title: standardized.lastPathComponent,
                    path: standardized.path,
                    sizeBytes: size,
                    lastModified: modified,
                    risk: settings.largeFileSearchRoots.contains { standardized.path.hasPrefix(URL(fileURLWithPath: $0).standardizedFileURL.path) } ? .medium : .high,
                    detail: "Large file older than \(settings.largeFileMinimumAgeDays) days.",
                    commandPreview: "Move to Trash: \(standardized.path)"
                )
            )
        }
    }

    return candidates
}

private func scanTrashBins(homeDirectory: String, volumeDirectory: String, ignoredPaths: Set<String>) -> [CleanupCandidate] {
    let fileManager = FileManager.default
    var trashRoots = [URL(fileURLWithPath: "\(homeDirectory)/.Trash").standardizedFileURL]

    if let volumes = try? fileManager.contentsOfDirectory(at: URL(fileURLWithPath: volumeDirectory), includingPropertiesForKeys: nil) {
        trashRoots += volumes.map { $0.appendingPathComponent(".Trashes").standardizedFileURL }
    }

    return trashRoots.flatMap { root -> [CleanupCandidate] in
        guard fileManager.fileExists(atPath: root.path),
              !ignoredPaths.contains(where: { root.path.hasPrefix($0) }),
              let children = try? fileManager.contentsOfDirectory(
                at: root,
                includingPropertiesForKeys: [.contentModificationDateKey],
                options: [.skipsHiddenFiles]
              ) else {
            return []
        }

        return children.compactMap { child in
            let url = child.standardizedFileURL
            let size = sharedDirectorySize(at: url)
            let modified = (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
            return CleanupCandidate(
                id: "trash.\(url.path)",
                category: .trashBins,
                title: url.lastPathComponent,
                path: url.path,
                sizeBytes: size,
                lastModified: modified,
                risk: .medium,
                detail: "Item currently in Trash. Cleanup permanently removes it after confirmation.",
                commandPreview: "Delete from Trash: \(url.path)"
            )
        }
    }
}

private func scanApplications(applicationDirectories: [String], ignoredPaths: Set<String>) -> [CleanupCandidate] {
    let fileManager = FileManager.default
    return applicationDirectories.flatMap { directory -> [CleanupCandidate] in
        let root = URL(fileURLWithPath: directory).standardizedFileURL
        guard fileManager.fileExists(atPath: root.path),
              !ignoredPaths.contains(where: { root.path.hasPrefix($0) }),
              let apps = try? fileManager.contentsOfDirectory(
                at: root,
                includingPropertiesForKeys: [.contentModificationDateKey, .isPackageKey],
                options: [.skipsHiddenFiles]
              ) else {
            return []
        }

        return apps
            .filter { $0.pathExtension == "app" }
            .compactMap { app in
                let url = app.standardizedFileURL
                guard !url.path.hasPrefix("/System/Applications") else { return nil }
                let bundle = Bundle(url: url)
                let bundleID = bundle?.bundleIdentifier ?? "Unknown bundle id"
                let size = sharedDirectorySize(at: url)
                let modified = (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
                return CleanupCandidate(
                    id: "application.\(url.path)",
                    category: .applications,
                    title: url.deletingPathExtension().lastPathComponent,
                    path: url.path,
                    sizeBytes: size,
                    lastModified: modified,
                    risk: .high,
                    detail: "Bundle ID: \(bundleID). Uninstall moves the app bundle to Trash after confirmation.",
                    commandPreview: "Move app to Trash: \(url.path)"
                )
            }
    }
}

private func scanLoginItems(homeDirectory: String, ignoredPaths: Set<String>) -> [CleanupCandidate] {
    let roots = [
        "\(homeDirectory)/Library/LaunchAgents",
        "\(homeDirectory)/Library/LaunchDaemons"
    ]

    return roots.flatMap { rootPath -> [CleanupCandidate] in
        let root = URL(fileURLWithPath: rootPath).standardizedFileURL
        guard FileManager.default.fileExists(atPath: root.path),
              !ignoredPaths.contains(where: { root.path.hasPrefix($0) }),
              let items = try? FileManager.default.contentsOfDirectory(
                at: root,
                includingPropertiesForKeys: [.contentModificationDateKey, .fileAllocatedSizeKey],
                options: [.skipsHiddenFiles]
              ) else {
            return []
        }

        return items
            .filter { $0.pathExtension == "plist" }
            .map { item in
                let url = item.standardizedFileURL
                let values = try? url.resourceValues(forKeys: [.contentModificationDateKey, .fileAllocatedSizeKey])
                let size = UInt64(max(values?.fileAllocatedSize ?? 0, 0))
                return CleanupCandidate(
                    id: "login-item.\(url.path)",
                    category: .loginItems,
                    title: url.deletingPathExtension().lastPathComponent,
                    path: url.path,
                    sizeBytes: size,
                    lastModified: values?.contentModificationDate,
                    risk: .medium,
                    detail: "User-level launch item. Cleanup moves the plist to Trash after confirmation.",
                    commandPreview: "Move login item to Trash: \(url.path)"
                )
            }
    }
}

public struct DockerCleanupPlanner: Sendable {
    public init() {}

    public func preview() -> [CleanupCandidate] {
        let calendar = Calendar.current
        let now = Date()
        return [
            CleanupCandidate(
                id: "docker.image.openclaw",
                category: .dockerImages,
                title: "openclaw:local",
                path: "d756a8b3177c",
                sizeBytes: 2_310_000_000,
                lastModified: calendar.date(byAdding: .day, value: -3, to: now),
                risk: .medium,
                detail: "Image ID: d756a8b3177c. Created: 3 days ago. Status: Unused.",
                commandPreview: "docker image rm d756a8b3177c"
            ),
            CleanupCandidate(
                id: "docker.image.localstack",
                category: .dockerImages,
                title: "localstack/localstack-pro:latest",
                path: "23299fa73b11",
                sizeBytes: 1_280_000_000,
                lastModified: calendar.date(byAdding: .day, value: -7, to: now),
                risk: .low,
                detail: "Image ID: 23299fa73b11. Created: 1 week ago. Status: Unused.",
                commandPreview: "docker image rm 23299fa73b11"
            ),
            CleanupCandidate(
                id: "docker.image.selenoid",
                category: .dockerImages,
                title: "selenoid/vnc:chrome_112.0",
                path: "cdbd82a63bfb",
                sizeBytes: 1_190_000_000,
                lastModified: calendar.date(byAdding: .day, value: -5, to: now),
                risk: .medium,
                detail: "Image ID: cdbd82a63bfb. Created: 5 days ago. Status: Unused.",
                commandPreview: "docker image rm cdbd82a63bfb"
            ),
            CleanupCandidate(
                id: "docker.image.node22",
                category: .dockerImages,
                title: "node:22",
                path: "f81607d210db",
                sizeBytes: 1_130_000_000,
                lastModified: calendar.date(byAdding: .day, value: -14, to: now),
                risk: .low,
                detail: "Image ID: f81607d210db. Created: 2 weeks ago. Status: Unused.",
                commandPreview: "docker image rm f81607d210db"
            ),
            CleanupCandidate(
                id: "docker.image.node20",
                category: .dockerImages,
                title: "node:20",
                path: "197941e0d0b6",
                sizeBytes: 1_100_000_000,
                lastModified: calendar.date(byAdding: .day, value: -14, to: now),
                risk: .low,
                detail: "Image ID: 197941e0d0b6. Created: 2 weeks ago. Status: Unused.",
                commandPreview: "docker image rm 197941e0d0b6"
            ),
            CleanupCandidate(
                id: "docker.image.mongo",
                category: .dockerImages,
                title: "mongo:latest",
                path: "4cccd8267062",
                sizeBytes: 896_000_000,
                lastModified: calendar.date(byAdding: .day, value: -7, to: now),
                risk: .medium,
                detail: "Image ID: 4cccd8267062. Created: 1 week ago. Status: Unused.",
                commandPreview: "docker image rm 4cccd8267062"
            ),
            CleanupCandidate(
                id: "docker.image.mysql",
                category: .dockerImages,
                title: "mysql:8.0",
                path: "eaf5cad44875",
                sizeBytes: 781_000_000,
                lastModified: calendar.date(byAdding: .day, value: -6, to: now),
                risk: .medium,
                detail: "Image ID: eaf5cad44875. Created: 6 days ago. Status: Unused.",
                commandPreview: "docker image rm eaf5cad44875"
            ),
            CleanupCandidate(
                id: "docker.image.wordpress",
                category: .dockerImages,
                title: "wordpress:latest",
                path: "e6c1f8a17f5f",
                sizeBytes: 760_000_000,
                lastModified: calendar.date(byAdding: .day, value: -4, to: now),
                risk: .medium,
                detail: "Image ID: e6c1f8a17f5f. Created: 4 days ago. Status: Unused.",
                commandPreview: "docker image rm e6c1f8a17f5f"
            ),
            CleanupCandidate(
                id: "docker.image.others",
                category: .dockerImages,
                title: "Other unused images",
                path: "multiple",
                sizeBytes: 5_873_000_000,
                lastModified: calendar.date(byAdding: .day, value: -30, to: now),
                risk: .low,
                detail: "61 other unused docker images.",
                commandPreview: "docker image prune"
            ),
            CleanupCandidate(
                id: "docker.container.loving_heisenberg",
                category: .dockerContainers,
                title: "loving_heisenberg",
                path: "a1b2c3d4e5f6",
                sizeBytes: 520_000_000,
                lastModified: calendar.date(byAdding: .day, value: -2, to: now),
                risk: .low,
                detail: "Image: redis:alpine. Status: Exited (0) 2 days ago.",
                commandPreview: "docker container rm a1b2c3d4e5f6"
            ),
            CleanupCandidate(
                id: "docker.container.clever_hawking",
                category: .dockerContainers,
                title: "clever_hawking",
                path: "b2c3d4e5f6a7",
                sizeBytes: 504_000_000,
                lastModified: calendar.date(byAdding: .day, value: -4, to: now),
                risk: .low,
                detail: "Image: postgres:15. Status: Exited (1) 4 days ago.",
                commandPreview: "docker container rm b2c3d4e5f6a7"
            ),
            CleanupCandidate(
                id: "docker.container.jovial_bardeen",
                category: .dockerContainers,
                title: "jovial_bardeen",
                path: "c3d4e5f6a7b8",
                sizeBytes: 6_000_000,
                lastModified: calendar.date(byAdding: .day, value: -1, to: now),
                risk: .low,
                detail: "Image: nginx:alpine. Status: Running.",
                commandPreview: "docker container rm jovial_bardeen"
            ),
            CleanupCandidate(
                id: "docker.volume.pg_data_volume",
                category: .dockerVolumes,
                title: "pg_data_volume",
                path: "pg_data_volume",
                sizeBytes: 1_200_000_000,
                lastModified: calendar.date(byAdding: .day, value: -10, to: now),
                risk: .high,
                detail: "Driver: local. Status: Dangling.",
                commandPreview: "docker volume rm pg_data_volume"
            ),
            CleanupCandidate(
                id: "docker.volume.others",
                category: .dockerVolumes,
                title: "Other unused volumes",
                path: "multiple",
                sizeBytes: 1_210_000_000,
                lastModified: calendar.date(byAdding: .day, value: -15, to: now),
                risk: .high,
                detail: "30 other dangling volumes.",
                commandPreview: "docker volume prune"
            ),
            CleanupCandidate(
                id: "docker.build-cache.kit",
                category: .dockerBuildCache,
                title: "Docker BuildKit cache",
                path: "build-cache",
                sizeBytes: 730_000_000,
                lastModified: calendar.date(byAdding: .day, value: -1, to: now),
                risk: .medium,
                detail: "Frees builder cache; future image builds may be slower.",
                commandPreview: "docker builder prune"
            )
        ]
    }

    public func command(for candidate: CleanupCandidate) -> CommandSpec? {
        switch candidate.id {
        case "docker.images": return CommandSpec("/usr/bin/env", ["docker", "image", "prune", "--force"])
        case "docker.containers": return CommandSpec("/usr/bin/env", ["docker", "container", "prune", "--force"])
        case "docker.volumes": return CommandSpec("/usr/bin/env", ["docker", "volume", "prune", "--force"])
        case "docker.build-cache": return CommandSpec("/usr/bin/env", ["docker", "builder", "prune", "--force"])
        default:
            if candidate.id.hasPrefix("docker.image."), let imageID = candidate.path {
                return CommandSpec("/usr/bin/env", ["docker", "image", "rm", imageID])
            }
            if candidate.id.hasPrefix("docker.container."), let containerID = candidate.path {
                return CommandSpec("/usr/bin/env", ["docker", "container", "rm", containerID])
            }
            if candidate.id.hasPrefix("docker.volume."), let volumeName = candidate.path {
                return CommandSpec("/usr/bin/env", ["docker", "volume", "rm", volumeName])
            }
            return nil
        }
    }
}

public struct DockerInventoryScanner: Sendable {
    private let shell: any ShellRunning
    private let fallbackPlanner: DockerCleanupPlanner

    public init(shell: any ShellRunning = ProcessShellRunner(), fallbackPlanner: DockerCleanupPlanner = DockerCleanupPlanner()) {
        self.shell = shell
        self.fallbackPlanner = fallbackPlanner
    }

    public func scan() async -> [CleanupCandidate] {
        do {
            let info = try await shell.run("/usr/bin/env", ["docker", "info", "--format", "{{.ServerVersion}}"])
            guard info.status == 0 else {
                return []
            }

            async let images = scanImages()
            async let containers = scanStoppedContainers()
            async let volumes = scanDanglingVolumes()

            var candidates = await images + containers + volumes
            candidates.append(
                CleanupCandidate(
                    id: "docker.build-cache",
                    category: .dockerBuildCache,
                    title: "Docker build cache",
                    risk: .medium,
                    detail: "Aggregate builder cache cleanup. Docker CLI does not expose stable per-cache deletion across all versions.",
                    commandPreview: "docker builder prune"
                )
            )
            return candidates
        } catch {
            return []
        }
    }

    private func scanImages() async -> [CleanupCandidate] {
        do {
            let result = try await shell.run("/usr/bin/env", [
                "docker", "images", "--format", "{{.ID}}\t{{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedSince}}"
            ])
            guard result.status == 0 else { return [] }

            return result.output
                .split(separator: "\n")
                .compactMap { line in
                    let fields = line.split(separator: "\t", omittingEmptySubsequences: false).map(String.init)
                    guard fields.count >= 5 else { return nil }

                    let imageID = fields[0]
                    let repository = fields[1]
                    let tag = fields[2]
                    let size = DockerSizeParser.bytes(from: fields[3])
                    let created = fields[4]
                    let name = repository == "<none>" ? imageID : "\(repository):\(tag)"

                    return CleanupCandidate(
                        id: "docker.image.\(imageID)",
                        category: .dockerImages,
                        title: name,
                        path: imageID,
                        sizeBytes: size,
                        risk: .medium,
                        detail: "Image ID: \(imageID). Created: \(created). Removal may fail if a container still references it.",
                        commandPreview: "docker image rm \(imageID)"
                    )
                }
        } catch {
            return []
        }
    }

    private func scanStoppedContainers() async -> [CleanupCandidate] {
        do {
            let result = try await shell.run("/usr/bin/env", [
                "docker", "ps", "-a",
                "--filter", "status=created",
                "--filter", "status=exited",
                "--filter", "status=dead",
                "--format", "{{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Size}}"
            ])
            guard result.status == 0 else { return [] }

            return result.output
                .split(separator: "\n")
                .compactMap { line in
                    let fields = line.split(separator: "\t", omittingEmptySubsequences: false).map(String.init)
                    guard fields.count >= 5 else { return nil }

                    let containerID = fields[0]
                    let name = fields[1].isEmpty ? containerID : fields[1]
                    let image = fields[2]
                    let status = fields[3]
                    let size = DockerSizeParser.bytes(from: fields[4])

                    return CleanupCandidate(
                        id: "docker.container.\(containerID)",
                        category: .dockerContainers,
                        title: name,
                        path: containerID,
                        sizeBytes: size,
                        risk: .low,
                        detail: "Image: \(image). Status: \(status).",
                        commandPreview: "docker container rm \(containerID)"
                    )
                }
        } catch {
            return []
        }
    }

    private func scanDanglingVolumes() async -> [CleanupCandidate] {
        do {
            let result = try await shell.run("/usr/bin/env", [
                "docker", "volume", "ls", "--filter", "dangling=true", "--format", "{{.Name}}\t{{.Driver}}"
            ])
            guard result.status == 0 else { return [] }

            return result.output
                .split(separator: "\n")
                .compactMap { line in
                    let fields = line.split(separator: "\t", omittingEmptySubsequences: false).map(String.init)
                    guard fields.count >= 2 else { return nil }

                    let name = fields[0]
                    let driver = fields[1]

                    return CleanupCandidate(
                        id: "docker.volume.\(name)",
                        category: .dockerVolumes,
                        title: name,
                        path: name,
                        risk: .high,
                        detail: "Unused volume using \(driver) driver. May contain local database or service data.",
                        commandPreview: "docker volume rm \(name)"
                    )
                }
        } catch {
            return []
        }
    }
}

enum DockerSizeParser {
    static func bytes(from value: String) -> UInt64? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let firstSize = trimmed.split(separator: " ").first.map(String.init) ?? trimmed
        let pattern = #"^([0-9]+(?:\.[0-9]+)?)([A-Za-z]+)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: firstSize, range: NSRange(firstSize.startIndex..., in: firstSize)),
              let numberRange = Range(match.range(at: 1), in: firstSize),
              let unitRange = Range(match.range(at: 2), in: firstSize),
              let number = Double(firstSize[numberRange]) else {
            return nil
        }

        let multiplier: Double
        switch firstSize[unitRange].lowercased() {
        case "b": multiplier = 1
        case "kb": multiplier = 1_000
        case "mb": multiplier = 1_000_000
        case "gb": multiplier = 1_000_000_000
        case "tb": multiplier = 1_000_000_000_000
        case "kib": multiplier = 1_024
        case "mib": multiplier = 1_048_576
        case "gib": multiplier = 1_073_741_824
        case "tib": multiplier = 1_099_511_627_776
        default: return nil
        }

        return UInt64(number * multiplier)
    }
}

public struct MemoryOptimizer: Sendable {
    private let machineInfo: any MachineInfoProviding
    private let shell: any ShellRunning

    public init(machineInfo: any MachineInfoProviding, shell: any ShellRunning = ProcessShellRunner()) {
        self.machineInfo = machineInfo
        self.shell = shell
    }

    public func preview() -> CleanupCandidate {
        CleanupCandidate(
            id: "memory.safe-optimize",
            category: .memory,
            title: "Safe memory optimize",
            risk: .low,
            detail: "Captures before/after machine state and asks macOS to purge reclaimable file cache when available.",
            commandPreview: "purge"
        )
    }

    public func optimize(confirmed: Bool) async -> (before: MachineOverview, after: MachineOverview, log: CleanupLogEntry) {
        let before = await machineInfo.refresh()
        guard confirmed else {
            return (
                before,
                before,
                CleanupLogEntry(action: "Memory optimize preview", detail: "No changes were applied.", succeeded: true)
            )
        }

        do {
            _ = try await shell.run("/usr/bin/purge", [])
            let after = await machineInfo.refresh()
            return (
                before,
                after,
                CleanupLogEntry(action: "Memory optimize", detail: "Requested macOS purge of reclaimable file cache.", succeeded: true)
            )
        } catch {
            let after = await machineInfo.refresh()
            return (
                before,
                after,
                CleanupLogEntry(action: "Memory optimize", detail: "Failed to run purge: \(error.localizedDescription)", succeeded: false)
            )
        }
    }
}

public struct CleanupExecutor: Sendable {
    private let shell: any ShellRunning
    private let dockerPlanner: DockerCleanupPlanner
    private let allowedPathRoots: [String]

    public init(
        shell: any ShellRunning = ProcessShellRunner(),
        dockerPlanner: DockerCleanupPlanner = DockerCleanupPlanner(),
        allowedPathRoots: [String] = CleanupSettings.defaultSafeDeletionRoots()
    ) {
        self.shell = shell
        self.dockerPlanner = dockerPlanner
        self.allowedPathRoots = allowedPathRoots.map { URL(fileURLWithPath: $0).standardizedFileURL.path }
    }

    public func execute(_ candidates: [CleanupCandidate], confirmed: Bool) async -> [CleanupLogEntry] {
        guard confirmed else {
            return [CleanupLogEntry(action: "Cleanup preview", detail: "\(candidates.count) selected item(s), no changes applied.", succeeded: true)]
        }

        var logs: [CleanupLogEntry] = []
        for candidate in candidates {
            switch candidate.category {
            case .nodeModules:
                logs.append(removeNodeModules(candidate))
            case .devCaches, .safeSystem:
                logs.append(removeSafePathCandidate(candidate))
            case .dockerImages, .dockerContainers, .dockerVolumes, .dockerBuildCache:
                logs.append(await runDocker(candidate))
            case .largeFiles, .applications, .loginItems:
                logs.append(moveCandidateToTrash(candidate))
            case .trashBins:
                logs.append(removeTrashCandidate(candidate))
            case .memory:
                logs.append(CleanupLogEntry(action: candidate.title, detail: "Use MemoryOptimizer for before/after memory cleanup.", succeeded: false))
            }
        }
        return logs
    }

    private func removeNodeModules(_ candidate: CleanupCandidate) -> CleanupLogEntry {
        guard let path = candidate.path, path.hasSuffix("/node_modules") else {
            return CleanupLogEntry(action: candidate.title, detail: "Refused to delete non-node_modules path.", succeeded: false)
        }

        do {
            try FileManager.default.removeItem(atPath: path)
            return CleanupLogEntry(action: "Delete node_modules", detail: path, succeeded: true)
        } catch {
            return CleanupLogEntry(action: "Delete node_modules", detail: "\(path): \(error.localizedDescription)", succeeded: false)
        }
    }

    private func removeSafePathCandidate(_ candidate: CleanupCandidate) -> CleanupLogEntry {
        guard let rawPath = candidate.path else {
            return CleanupLogEntry(action: candidate.title, detail: "Missing path.", succeeded: false)
        }

        let path = URL(fileURLWithPath: rawPath).standardizedFileURL.path
        guard allowedPathRoots.contains(where: { root in path.hasPrefix(root + "/") && path != root }) else {
            return CleanupLogEntry(action: candidate.title, detail: "Refused to delete path outside cleanup allowlist: \(path)", succeeded: false)
        }

        do {
            try FileManager.default.removeItem(atPath: path)
            return CleanupLogEntry(action: candidate.title, detail: path, succeeded: true)
        } catch {
            return CleanupLogEntry(action: candidate.title, detail: "\(path): \(error.localizedDescription)", succeeded: false)
        }
    }

    private func runDocker(_ candidate: CleanupCandidate) async -> CleanupLogEntry {
        guard let command = dockerPlanner.command(for: candidate) else {
            return CleanupLogEntry(action: candidate.title, detail: "Unknown Docker cleanup command.", succeeded: false)
        }

        do {
            let result = try await shell.run(command.executable, command.arguments)
            let detail = result.output.isEmpty ? result.error : result.output
            return CleanupLogEntry(action: candidate.title, detail: detail, succeeded: result.status == 0)
        } catch {
            return CleanupLogEntry(action: candidate.title, detail: error.localizedDescription, succeeded: false)
        }
    }

    private func moveCandidateToTrash(_ candidate: CleanupCandidate) -> CleanupLogEntry {
        guard let rawPath = candidate.path else {
            return CleanupLogEntry(action: candidate.title, detail: "Missing path.", succeeded: false)
        }

        let url = URL(fileURLWithPath: rawPath).standardizedFileURL
        if candidate.category == .applications, url.path.hasPrefix("/System/Applications") {
            return CleanupLogEntry(action: candidate.title, detail: "Refused to uninstall protected system app.", succeeded: false)
        }

        do {
            var resultingURL: NSURL?
            try FileManager.default.trashItem(at: url, resultingItemURL: &resultingURL)
            return CleanupLogEntry(action: candidate.title, detail: "Moved to Trash: \(url.path)", succeeded: true)
        } catch {
            return CleanupLogEntry(action: candidate.title, detail: "\(url.path): \(error.localizedDescription)", succeeded: false)
        }
    }

    private func removeTrashCandidate(_ candidate: CleanupCandidate) -> CleanupLogEntry {
        guard let rawPath = candidate.path else {
            return CleanupLogEntry(action: candidate.title, detail: "Missing path.", succeeded: false)
        }

        let url = URL(fileURLWithPath: rawPath).standardizedFileURL
        guard url.path.contains("/.Trash/") || url.path.contains("/.Trashes/") else {
            return CleanupLogEntry(action: candidate.title, detail: "Refused to delete item outside Trash: \(url.path)", succeeded: false)
        }

        do {
            try FileManager.default.removeItem(at: url)
            return CleanupLogEntry(action: candidate.title, detail: "Deleted from Trash: \(url.path)", succeeded: true)
        } catch {
            return CleanupLogEntry(action: candidate.title, detail: "\(url.path): \(error.localizedDescription)", succeeded: false)
        }
    }
}

private func sharedDirectorySize(at url: URL) -> UInt64 {
    guard let enumerator = FileManager.default.enumerator(
        at: url,
        includingPropertiesForKeys: [.totalFileAllocatedSizeKey, .fileAllocatedSizeKey, .fileSizeKey],
        options: [.skipsHiddenFiles]
    ) else {
        let values = try? url.resourceValues(forKeys: [.totalFileAllocatedSizeKey, .fileAllocatedSizeKey, .fileSizeKey])
        return UInt64(max(values?.totalFileAllocatedSize ?? values?.fileAllocatedSize ?? values?.fileSize ?? 0, 0))
    }

    var total: UInt64 = 0
    for case let fileURL as URL in enumerator {
        let values = try? fileURL.resourceValues(forKeys: [.totalFileAllocatedSizeKey, .fileAllocatedSizeKey, .fileSizeKey])
        let size = values?.totalFileAllocatedSize ?? values?.fileAllocatedSize ?? values?.fileSize ?? 0
        total += UInt64(max(size, 0))
    }
    return total
}
