import XCTest
@testable import CleanMacCore

final class CleanMacCoreTests: XCTestCase {
    func testDockerPlannerSeparatesCleanupGroupsAndFlagsVolumesHighRisk() {
        let planner = DockerCleanupPlanner()
        let candidates = planner.preview()

        XCTAssertEqual(candidates.map(\.category), [.dockerImages, .dockerContainers, .dockerVolumes, .dockerBuildCache])
        XCTAssertEqual(candidates.first(where: { $0.category == .dockerVolumes })?.risk, .high)
        XCTAssertEqual(planner.command(for: candidates[0])?.preview, "/usr/bin/env docker image prune --force")
    }

    func testSettingsStoreRoundTrip() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let url = directory.appendingPathComponent("settings.json")
        let store = SettingsStore(url: url)
        let settings = CleanupSettings(
            ignoredPaths: ["/tmp/ignored"],
            nodeSearchRoots: ["/tmp/projects"],
            requireConfirmation: true,
            selectedPreset: "Manual Deep Clean"
        )

        try await store.save(settings)
        let loaded = await store.load()

        XCTAssertEqual(loaded, settings)
    }

    func testSettingsDecodeBackfillsEnabledSourcesForExistingSettingsFiles() throws {
        let data = Data("""
        {
          "ignoredPaths": ["/tmp/ignored"],
          "nodeSearchRoots": ["/tmp/projects"],
          "requireConfirmation": true,
          "selectedPreset": "Safe Daily"
        }
        """.utf8)

        let settings = try JSONDecoder().decode(CleanupSettings.self, from: data)

        XCTAssertEqual(settings.ignoredPaths, ["/tmp/ignored"])
        XCTAssertEqual(settings.nodeSearchRoots, ["/tmp/projects"])
        XCTAssertEqual(settings.enabledSources, CleanupSource.allCases)
    }

    func testNodeModulesScannerFindsProjectFoldersAndSkipsIgnoredRoots() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let project = root.appendingPathComponent("app")
        let ignored = root.appendingPathComponent("ignored")
        let nodeModules = project.appendingPathComponent("node_modules")
        let ignoredNodeModules = ignored.appendingPathComponent("node_modules")

        try FileManager.default.createDirectory(at: nodeModules, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: ignoredNodeModules, withIntermediateDirectories: true)
        try Data("fixture".utf8).write(to: nodeModules.appendingPathComponent("index.js"))
        try Data("ignored".utf8).write(to: ignoredNodeModules.appendingPathComponent("index.js"))

        let scanner = NodeModulesScanner()
        let candidates = await scanner.scan(settings: CleanupSettings(ignoredPaths: [ignored.path], nodeSearchRoots: [root.path]))

        XCTAssertEqual(candidates.map(\.path), [nodeModules.path])
        XCTAssertEqual(candidates.first?.title, "app")
    }

    func testCleanupExecutorRefusesNonNodeModulesPath() async throws {
        let tempFile = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try Data("do not delete".utf8).write(to: tempFile)

        let candidate = CleanupCandidate(
            id: tempFile.path,
            category: .nodeModules,
            title: "Unsafe",
            path: tempFile.path,
            risk: .medium,
            detail: "Not actually node_modules"
        )

        let logs = await CleanupExecutor().execute([candidate], confirmed: true)

        XCTAssertEqual(logs.first?.succeeded, false)
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempFile.path))
    }

    func testDockerInventoryScannerReturnsIndividualCleanupItems() async {
        let scanner = DockerInventoryScanner(shell: FakeShellRunner(results: [
            "/usr/bin/env docker info --format {{.ServerVersion}}": ShellResult(status: 0, output: "26.1.0"),
            "/usr/bin/env docker images --format {{.ID}}\t{{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedSince}}": ShellResult(status: 0, output: "abc123\tpostgres\t16\t438MB\t2 weeks ago"),
            "/usr/bin/env docker ps -a --filter status=created --filter status=exited --filter status=dead --format {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Size}}": ShellResult(status: 0, output: "def456\told-api\tapi:latest\tExited (0) 3 days ago\t12.5MB"),
            "/usr/bin/env docker volume ls --filter dangling=true --format {{.Name}}\t{{.Driver}}": ShellResult(status: 0, output: "db-data\tlocal")
        ]))

        let candidates = await scanner.scan()

        XCTAssertTrue(candidates.contains { $0.id == "docker.image.abc123" && $0.title == "postgres:16" })
        XCTAssertTrue(candidates.contains { $0.id == "docker.container.def456" && $0.title == "old-api" })
        XCTAssertTrue(candidates.contains { $0.id == "docker.volume.db-data" && $0.risk == .high })
        XCTAssertTrue(candidates.contains { $0.id == "docker.build-cache" })
    }

    func testDockerPlannerBuildsPerItemDeleteCommands() {
        let planner = DockerCleanupPlanner()
        let image = CleanupCandidate(id: "docker.image.abc123", category: .dockerImages, title: "postgres:16", path: "abc123", risk: .medium, detail: "")
        let container = CleanupCandidate(id: "docker.container.def456", category: .dockerContainers, title: "old-api", path: "def456", risk: .low, detail: "")
        let volume = CleanupCandidate(id: "docker.volume.db-data", category: .dockerVolumes, title: "db-data", path: "db-data", risk: .high, detail: "")

        XCTAssertEqual(planner.command(for: image)?.preview, "/usr/bin/env docker image rm abc123")
        XCTAssertEqual(planner.command(for: container)?.preview, "/usr/bin/env docker container rm def456")
        XCTAssertEqual(planner.command(for: volume)?.preview, "/usr/bin/env docker volume rm db-data")
    }

    func testUnifiedScannerDetectsDevAndSafeSystemSources() async throws {
        let home = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let paths = [
            "Library/Developer/Xcode/DerivedData/AppBuild",
            "Library/Caches/org.swift.swiftpm/repositories",
            ".npm/_cacache",
            "Library/Caches/Yarn/v6",
            "Library/pnpm/store/v3",
            "Library/Caches/Homebrew/downloads",
            "Library/Logs/CleanMacTest",
            "Library/Caches/com.example.app",
            "Downloads/old-file"
        ]

        for path in paths {
            let directory = home.appendingPathComponent(path)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try Data("fixture".utf8).write(to: directory.appendingPathComponent("payload"))
        }

        let scanner = UnifiedCleanupScanner(homeDirectory: home.path)
        let candidates = await scanner.scan(settings: CleanupSettings())
        let titles = candidates.map(\.title)

        XCTAssertTrue(titles.contains { $0.contains("Xcode DerivedData") })
        XCTAssertTrue(titles.contains { $0.contains("SwiftPM Cache") })
        XCTAssertTrue(titles.contains { $0.contains("npm Cache") })
        XCTAssertTrue(titles.contains { $0.contains("Yarn Cache") })
        XCTAssertTrue(titles.contains { $0.contains("pnpm Store") })
        XCTAssertTrue(titles.contains { $0.contains("Homebrew Cache") })
        XCTAssertTrue(titles.contains { $0.contains("User Logs") })
        XCTAssertTrue(titles.contains { $0.contains("User App Caches") })
        XCTAssertFalse(candidates.contains { $0.path?.contains("/Downloads/") == true })
    }

    func testUnifiedScannerRespectsDisabledSourcesAndIgnoreList() async throws {
        let home = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let npm = home.appendingPathComponent(".npm/_cacache")
        let ignoredLogs = home.appendingPathComponent("Library/Logs/ignored")
        try FileManager.default.createDirectory(at: npm, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: ignoredLogs, withIntermediateDirectories: true)
        try Data("npm".utf8).write(to: npm.appendingPathComponent("payload"))
        try Data("logs".utf8).write(to: ignoredLogs.appendingPathComponent("payload"))

        let scanner = UnifiedCleanupScanner(homeDirectory: home.path)
        let candidates = await scanner.scan(settings: CleanupSettings(
            ignoredPaths: [ignoredLogs.path],
            enabledSources: [.userLogs]
        ))

        XCTAssertTrue(candidates.isEmpty)
    }

    func testPracticalScannerFindsLargeTrashAppsAndLoginItems() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let home = root.appendingPathComponent("home")
        let applications = root.appendingPathComponent("Applications")
        let volumes = root.appendingPathComponent("Volumes")
        let largeRoot = home.appendingPathComponent("Documents")
        let largeFile = largeRoot.appendingPathComponent("archive.zip")
        let trashItem = home.appendingPathComponent(".Trash/old.log")
        let app = applications.appendingPathComponent("Demo.app")
        let loginItem = home.appendingPathComponent("Library/LaunchAgents/com.example.demo.plist")

        try FileManager.default.createDirectory(at: largeRoot, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: trashItem.deletingLastPathComponent(), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: app, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: loginItem.deletingLastPathComponent(), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: volumes, withIntermediateDirectories: true)
        try Data(repeating: 1, count: 2_048).write(to: largeFile)
        try Data("trash".utf8).write(to: trashItem)
        try Data("app".utf8).write(to: app.appendingPathComponent("payload"))
        try Data("plist".utf8).write(to: loginItem)

        let oldDate = Date(timeIntervalSinceNow: -60 * 60 * 24 * 40)
        try FileManager.default.setAttributes([.modificationDate: oldDate], ofItemAtPath: largeFile.path)

        let scanner = PracticalCleanupScanner(homeDirectory: home.path, applicationDirectories: [applications.path], volumeDirectory: volumes.path)
        let candidates = await scanner.scan(settings: CleanupSettings(
            largeFileSearchRoots: [largeRoot.path],
            largeFileMinimumBytes: 1_024,
            largeFileMinimumAgeDays: 30
        ))

        XCTAssertTrue(candidates.contains { $0.category == .largeFiles && $0.path == largeFile.path && $0.risk == .medium })
        XCTAssertTrue(candidates.contains { $0.category == .trashBins && $0.path == trashItem.path && $0.risk == .medium })
        XCTAssertTrue(candidates.contains { $0.category == .applications && $0.path == app.path && $0.risk == .high })
        XCTAssertTrue(candidates.contains { $0.category == .loginItems && $0.path == loginItem.path && $0.risk == .medium })
    }

    func testPracticalCandidatesAreNotIncludedInQuickClean() {
        let candidates = [
            CleanupCandidate(id: "trash", category: .trashBins, title: "Trash", risk: .medium, detail: ""),
            CleanupCandidate(id: "app", category: .applications, title: "App", risk: .high, detail: ""),
            CleanupCandidate(id: "login", category: .loginItems, title: "Login", risk: .medium, detail: ""),
            CleanupCandidate(id: "large", category: .largeFiles, title: "Large", risk: .medium, detail: ""),
            CleanupCandidate(id: "safe", category: .safeSystem, title: "Safe", risk: .low, detail: "")
        ]

        XCTAssertEqual(CleanupSelectionPlanner.quickCleanCandidates(from: candidates).map(\.id), ["safe"])
    }

    func testCleanupExecutorDeletesOnlyAllowedPathChildren() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let allowedRoot = root.appendingPathComponent("Library/Caches")
        let child = allowedRoot.appendingPathComponent("com.example.cache")
        let outside = root.appendingPathComponent("Documents/important")
        try FileManager.default.createDirectory(at: child, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: outside, withIntermediateDirectories: true)
        try Data("cache".utf8).write(to: child.appendingPathComponent("payload"))
        try Data("important".utf8).write(to: outside.appendingPathComponent("payload"))

        let executor = CleanupExecutor(allowedPathRoots: [allowedRoot.path])
        let logs = await executor.execute([
            CleanupCandidate(id: child.path, category: .safeSystem, title: "Allowed", path: child.path, risk: .low, detail: ""),
            CleanupCandidate(id: outside.path, category: .safeSystem, title: "Outside", path: outside.path, risk: .low, detail: "")
        ], confirmed: true)

        XCTAssertEqual(logs.map(\.succeeded), [true, false])
        XCTAssertFalse(FileManager.default.fileExists(atPath: child.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: outside.path))
    }

    func testQuickCleanSelectionOnlyIncludesLowRiskCandidates() {
        let candidates = [
            CleanupCandidate(id: "low", category: .safeSystem, title: "Low", risk: .low, detail: ""),
            CleanupCandidate(id: "medium", category: .devCaches, title: "Medium", risk: .medium, detail: ""),
            CleanupCandidate(id: "high", category: .dockerVolumes, title: "High", risk: .high, detail: "")
        ]

        XCTAssertEqual(CleanupSelectionPlanner.quickCleanCandidates(from: candidates).map(\.id), ["low"])
    }

    func testCandidateReviewSearchesTitlePathAndDetail() {
        let candidates = reviewFixtures()

        XCTAssertEqual(CandidateReviewPlanner.filteredCandidates(candidates, filter: CandidateReviewFilter(searchText: "docker")).map(\.id), ["docker"])
        XCTAssertEqual(CandidateReviewPlanner.filteredCandidates(candidates, filter: CandidateReviewFilter(searchText: "/cache/npm")).map(\.id), ["npm"])
        XCTAssertEqual(CandidateReviewPlanner.filteredCandidates(candidates, filter: CandidateReviewFilter(searchText: "database")).map(\.id), ["volume"])
    }

    func testCandidateReviewFiltersByRiskAndCategory() {
        let candidates = reviewFixtures()
        let filtered = CandidateReviewPlanner.filteredCandidates(
            candidates,
            filter: CandidateReviewFilter(risks: [.high], categories: [.dockerVolumes])
        )

        XCTAssertEqual(filtered.map(\.id), ["volume"])
    }

    func testCandidateReviewSortsBySizeDescendingWithUnknownLast() {
        let candidates = reviewFixtures()

        XCTAssertEqual(CandidateReviewPlanner.sortedCandidates(candidates).map(\.id), ["node", "docker", "npm", "volume", "unknown"])
    }

    func testCandidateReviewSelectAllUsesAllScannedCandidates() {
        let candidates = reviewFixtures()

        XCTAssertEqual(CandidateReviewPlanner.selectAllIDs(from: candidates), Set(["npm", "docker", "volume", "node", "unknown"]))
    }

    func testCleanupConfirmationSummaryCountsBytesRisksAndHighRiskNames() {
        let summary = CleanupConfirmationSummary(candidates: reviewFixtures())

        XCTAssertEqual(summary.itemCount, 5)
        XCTAssertEqual(summary.totalBytes, 1_850)
        XCTAssertEqual(summary.lowRiskCount, 2)
        XCTAssertEqual(summary.mediumRiskCount, 2)
        XCTAssertEqual(summary.highRiskCount, 1)
        XCTAssertEqual(summary.highRiskNames, ["Database Volume"])
    }
}

private func reviewFixtures() -> [CleanupCandidate] {
    [
        CleanupCandidate(id: "npm", category: .devCaches, title: "npm Cache", path: "/cache/npm", sizeBytes: 200, risk: .low, detail: "Package cache"),
        CleanupCandidate(id: "docker", category: .dockerImages, title: "Docker Image", path: "abc123", sizeBytes: 500, risk: .medium, detail: "Container image"),
        CleanupCandidate(id: "volume", category: .dockerVolumes, title: "Database Volume", path: "db-data", sizeBytes: 150, risk: .high, detail: "May contain database data"),
        CleanupCandidate(id: "node", category: .nodeModules, title: "node_modules", path: "/app/node_modules", sizeBytes: 1_000, risk: .medium, detail: "Project dependencies"),
        CleanupCandidate(id: "unknown", category: .safeSystem, title: "Unknown Size", path: "/logs/app", risk: .low, detail: "Logs")
    ]
}

private struct FakeShellRunner: ShellRunning {
    var results: [String: ShellResult]

    func run(_ executable: String, _ arguments: [String]) async throws -> ShellResult {
        let key = ([executable] + arguments).joined(separator: " ")
        return results[key] ?? ShellResult(status: 1, output: "", error: "Missing fixture: \(key)")
    }
}
