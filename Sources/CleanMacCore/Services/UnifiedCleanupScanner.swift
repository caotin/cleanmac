import Foundation

public protocol CleanupSourceScanning: Sendable {
    func scan(settings: CleanupSettings) async -> [CleanupCandidate]
}

public struct UnifiedCleanupScanner: CleanupSourceScanning {
    private let homeDirectory: String

    public init(homeDirectory: String = FileManager.default.homeDirectoryForCurrentUser.path) {
        self.homeDirectory = homeDirectory
    }

    public func scan(settings: CleanupSettings) async -> [CleanupCandidate] {
        await Task.detached(priority: .utility) {
            let enabled = Set(settings.enabledSources)
            let ignored = Set(settings.ignoredPaths.map { URL(fileURLWithPath: $0).standardizedFileURL.path })

            return cleanupTargets(homeDirectory: homeDirectory)
                .filter { enabled.contains($0.source) }
                .filter { FileManager.default.fileExists(atPath: $0.path) }
                .flatMap { target in
                    candidates(for: target, ignoredPaths: ignored)
                }
                .sorted { ($0.sizeBytes ?? 0, $0.title) > ($1.sizeBytes ?? 0, $1.title) }
        }.value
    }
}

private struct CleanupTarget {
    var source: CleanupSource
    var category: CleanupCategory
    var title: String
    var path: String
    var risk: CleanupRisk
    var scanChildren: Bool
}

private func cleanupTargets(homeDirectory: String) -> [CleanupTarget] {
    [
        CleanupTarget(source: .xcodeDerivedData, category: .devCaches, title: "Xcode DerivedData", path: "\(homeDirectory)/Library/Developer/Xcode/DerivedData", risk: .low, scanChildren: true),
        CleanupTarget(source: .swiftPM, category: .devCaches, title: "SwiftPM Cache", path: "\(homeDirectory)/Library/Caches/org.swift.swiftpm", risk: .low, scanChildren: true),
        CleanupTarget(source: .npm, category: .devCaches, title: "npm Cache", path: "\(homeDirectory)/.npm", risk: .low, scanChildren: true),
        CleanupTarget(source: .yarn, category: .devCaches, title: "Yarn Cache", path: "\(homeDirectory)/Library/Caches/Yarn", risk: .low, scanChildren: true),
        CleanupTarget(source: .pnpm, category: .devCaches, title: "pnpm Store", path: "\(homeDirectory)/Library/pnpm/store", risk: .medium, scanChildren: true),
        CleanupTarget(source: .homebrew, category: .devCaches, title: "Homebrew Cache", path: "\(homeDirectory)/Library/Caches/Homebrew", risk: .low, scanChildren: true),
        CleanupTarget(source: .userLogs, category: .safeSystem, title: "User Logs", path: "\(homeDirectory)/Library/Logs", risk: .low, scanChildren: true),
        CleanupTarget(source: .userCaches, category: .safeSystem, title: "User App Caches", path: "\(homeDirectory)/Library/Caches", risk: .medium, scanChildren: true),
        CleanupTarget(source: .pip, category: .devCaches, title: "pip Cache", path: "\(homeDirectory)/Library/Caches/pip", risk: .low, scanChildren: true),
        CleanupTarget(source: .poetry, category: .devCaches, title: "Poetry Cache", path: "\(homeDirectory)/Library/Caches/pypoetry", risk: .low, scanChildren: true),
        CleanupTarget(source: .pipenv, category: .devCaches, title: "Pipenv Cache", path: "\(homeDirectory)/Library/Caches/pipenv", risk: .low, scanChildren: true),
        CleanupTarget(source: .cargo, category: .devCaches, title: "Cargo Registry", path: "\(homeDirectory)/.cargo/registry", risk: .low, scanChildren: true),
        CleanupTarget(source: .cargo, category: .devCaches, title: "Cargo Git Cache", path: "\(homeDirectory)/.cargo/git", risk: .low, scanChildren: true),
        CleanupTarget(source: .go, category: .devCaches, title: "Go Build Cache", path: "\(homeDirectory)/Library/Caches/go-build", risk: .low, scanChildren: true),
        CleanupTarget(source: .go, category: .devCaches, title: "Go Mod Cache", path: "\(homeDirectory)/go/pkg/mod", risk: .medium, scanChildren: true),
        CleanupTarget(source: .pub, category: .devCaches, title: "Pub Cache", path: "\(homeDirectory)/.pub-cache", risk: .low, scanChildren: true),
        CleanupTarget(source: .gradle, category: .devCaches, title: "Gradle Cache", path: "\(homeDirectory)/.gradle/caches", risk: .low, scanChildren: true),
        CleanupTarget(source: .maven, category: .devCaches, title: "Maven Repository", path: "\(homeDirectory)/.m2/repository", risk: .low, scanChildren: true),
        CleanupTarget(source: .cocoapods, category: .devCaches, title: "CocoaPods Cache", path: "\(homeDirectory)/Library/Caches/CocoaPods", risk: .low, scanChildren: true),
        CleanupTarget(source: .carthage, category: .devCaches, title: "Carthage Cache", path: "\(homeDirectory)/Library/Caches/carthage", risk: .low, scanChildren: true),
        CleanupTarget(source: .composer, category: .devCaches, title: "Composer Cache", path: "\(homeDirectory)/Library/Caches/composer", risk: .low, scanChildren: true)
    ]
}

private func candidates(for target: CleanupTarget, ignoredPaths: Set<String>) -> [CleanupCandidate] {
    let root = URL(fileURLWithPath: target.path).standardizedFileURL
    guard !ignoredPaths.contains(where: { root.path.hasPrefix($0) }) else {
        return []
    }

    if target.scanChildren {
        guard let children = try? FileManager.default.contentsOfDirectory(
            at: root,
            includingPropertiesForKeys: [.contentModificationDateKey, .isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        return children
            .map(\.standardizedFileURL)
            .filter { child in !ignoredPaths.contains(where: { ignored in child.path.hasPrefix(ignored) }) }
            .compactMap { child in
                cleanupCandidate(titlePrefix: target.title, target: target, url: child)
            }
    }

    return cleanupCandidate(titlePrefix: target.title, target: target, url: root).map { [$0] } ?? []
}

private func cleanupCandidate(titlePrefix: String, target: CleanupTarget, url: URL) -> CleanupCandidate? {
    let size = directorySize(at: url)
    guard size > 0 else { return nil }
    let modified = (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
    let title = target.scanChildren ? "\(titlePrefix): \(url.lastPathComponent)" : titlePrefix

    return CleanupCandidate(
        id: url.path,
        category: target.category,
        title: title,
        path: url.path,
        sizeBytes: size,
        lastModified: modified,
        risk: target.risk,
        detail: "Source: \(target.source.title)",
        commandPreview: "Delete \(url.path)"
    )
}

private func directorySize(at url: URL) -> UInt64 {
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
