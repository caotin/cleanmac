import CleanMacCore
import Foundation

enum AppSection: String, CaseIterable, Identifiable {
    case smartScan = "Smart Scan"
    case dashboard = "Dashboard"
    case cleanup = "Cleanup"
    case memory = "Memory"
    case nodeModules = "Node Modules"
    case docker = "Docker"
    case logs = "Logs"
    case settings = "Settings"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .dashboard: "square.grid.2x2"
        case .smartScan: "sparkle.magnifyingglass"
        case .cleanup: "trash"
        case .memory: "memorychip"
        case .nodeModules: "shippingbox"
        case .docker: "cube.box"
        case .logs: "doc.plaintext"
        case .settings: "gearshape"
        }
    }
}

@MainActor
final class AppState: ObservableObject {
    @Published var section: AppSection = .smartScan
    @Published var machine: MachineOverview?
    @Published var settings = CleanupSettings()
    @Published var cleanupSourceCandidates: [CleanupCandidate] = AppState.mockCleanupSourceCandidates
    @Published var practicalCandidates: [CleanupCandidate] = AppState.mockPracticalCandidates
    @Published var nodeCandidates: [CleanupCandidate] = AppState.mockNodeCandidates
    @Published var dockerCandidates: [CleanupCandidate] = AppState.mockDockerCandidates
    @Published var selectedCandidateIDs: Set<String> = []
    @Published var logs: [CleanupLogEntry] = []
    @Published var isRefreshingMachine = false
    @Published var isRefreshingRunningApps = false
    @Published var isScanningSources = false
    @Published var isScanningPractical = false
    @Published var isScanningNodeModules = false
    @Published var isScanningDocker = false
    @Published var isRunningQuickClean = false
    @Published var statusMessage = "Ready"
    @Published var pendingConfirmation: [CleanupCandidate] = []
    @Published var isShowingCleanupConfirmation = false
    @Published var runningApps: [RunningAppInfo] = []
    @Published var selectedRunningAppIDs: Set<String> = []
    @Published var pendingRunningAppTermination: [RunningAppInfo] = []
    @Published var isShowingAppKillConfirmation = false
    @Published var isForceKillingApps = false
    @Published var lastCleanupSummary: CleanupRunSummary?
    @Published var dashboardCategoryFilter: CleanupCategory?

    private let settingsStore = SettingsStore()
    private let machineService = MachineInfoService()
    private let runningAppService = RunningAppService()
    private let unifiedScanner = UnifiedCleanupScanner()
    private let practicalScanner = PracticalCleanupScanner()
    private let nodeScanner = NodeModulesScanner()
    private let dockerScanner = DockerInventoryScanner()
    private let dockerPlanner = DockerCleanupPlanner()
    private lazy var executor = CleanupExecutor(dockerPlanner: dockerPlanner)
    private lazy var memoryOptimizer = MemoryOptimizer(machineInfo: machineService)
    private var didStartBackgroundRefresh = false
    private var didScanCleanupSources = false
    private var didScanDockerInventory = false

    func bootstrap() async {
        settings = await settingsStore.load()
        await refreshMachine()
        refreshRunningApps()
        startBackgroundRefresh()
    }

    func scanAll() async {
        guard !isBusyWithCleanupScan else { return }
        statusMessage = "Scanning all cleanup sources..."
        await scanCleanupSources()
        await scanPracticalCleanup()
        await scanNodeModules()
        await scanDockerInventory()
        statusMessage = "Found \(allCandidates.count) cleanup item(s)"
    }

    func scanPracticalCleanup() async {
        guard !isScanningPractical else { return }
        isScanningPractical = true
        statusMessage = "Scanning large files, Trash, apps, and login items..."
        practicalCandidates = await practicalScanner.scan(settings: settings)
        selectedCandidateIDs = selectedCandidateIDs.intersection(Set(allCandidates.map(\.id)))
        statusMessage = "Found \(practicalCandidates.count) practical cleanup item(s)"
        isScanningPractical = false
    }

    func scanCleanupSources() async {
        guard !isScanningSources else { return }
        isScanningSources = true
        statusMessage = "Scanning dev and system cleanup sources..."
        cleanupSourceCandidates = await unifiedScanner.scan(settings: settings)
        didScanCleanupSources = true
        selectedCandidateIDs = selectedCandidateIDs.intersection(Set(allCandidates.map(\.id)))
        statusMessage = "Found \(cleanupSourceCandidates.count) dev/system cleanup item(s)"
        isScanningSources = false
    }

    func refreshMachine() async {
        guard !isRefreshingMachine else { return }
        isRefreshingMachine = true
        statusMessage = "Refreshing machine overview..."
        machine = await machineService.refresh()
        statusMessage = "Machine overview updated"
        isRefreshingMachine = false
    }

    func refreshRunningApps() {
        guard !isRefreshingRunningApps else { return }
        isRefreshingRunningApps = true
        statusMessage = "Refreshing running apps..."
        runningApps = runningAppService.scan()
        selectedRunningAppIDs = selectedRunningAppIDs.intersection(Set(runningApps.map(\.id)))
        statusMessage = "Found \(runningApps.count) running app(s)"
        isRefreshingRunningApps = false
    }

    func scanNodeModules() async {
        guard !isScanningNodeModules else { return }
        isScanningNodeModules = true
        statusMessage = "Scanning node_modules..."
        nodeCandidates = await nodeScanner.scan(settings: settings)
        selectedCandidateIDs = selectedCandidateIDs.intersection(Set(allCandidates.map(\.id)))
        statusMessage = "Found \(nodeCandidates.count) node_modules folder(s)"
        isScanningNodeModules = false
    }

    func scanDockerInventory() async {
        guard !isScanningDocker else { return }
        isScanningDocker = true
        statusMessage = "Scanning Docker inventory..."
        dockerCandidates = await dockerScanner.scan()
        didScanDockerInventory = true
        selectedCandidateIDs = selectedCandidateIDs.intersection(Set(allCandidates.map(\.id)))
        statusMessage = "Found \(dockerCandidates.count) Docker cleanup item(s)"
        isScanningDocker = false
    }

    func optimizeMemoryPreview() {
        section = .memory
        presentCleanupConfirmation([memoryOptimizer.preview()])
    }

    func runMemoryOptimize(confirmed: Bool) async {
        statusMessage = confirmed ? "Optimizing memory..." : "Memory optimize preview"
        let result = await memoryOptimizer.optimize(confirmed: confirmed)
        machine = result.after
        logs.insert(result.log, at: 0)
        statusMessage = result.log.detail
    }

    func confirmTerminateSelectedApps(force: Bool) {
        let selected = runningApps.filter { selectedRunningAppIDs.contains($0.id) }
        guard !selected.isEmpty else {
            statusMessage = "Select at least one app first"
            return
        }
        pendingRunningAppTermination = selected
        isForceKillingApps = force
        isShowingAppKillConfirmation = true
    }

    func dismissAppKillConfirmation() {
        isShowingAppKillConfirmation = false
        pendingRunningAppTermination = []
        isForceKillingApps = false
    }

    func executePendingAppTermination() async {
        let apps = pendingRunningAppTermination
        let force = isForceKillingApps
        dismissAppKillConfirmation()
        guard !apps.isEmpty else { return }

        statusMessage = force ? "Force killing \(apps.count) app(s)..." : "Quitting \(apps.count) app(s)..."
        let processIDs = Set(apps.map(\.processIdentifier))
        let entries = await runningAppService.terminate(processIDs: processIDs, force: force)
        logs.insert(contentsOf: entries.reversed(), at: 0)
        selectedRunningAppIDs.subtract(apps.map(\.id))
        refreshRunningApps()
        await refreshMachine()
        statusMessage = force ? "Force kill requests sent" : "Quit requests sent"
    }

    func cleanSelectedPreview() {
        let selected = allCandidates.filter { selectedCandidateIDs.contains($0.id) }
        presentCleanupConfirmation(selected)
    }

    func quickClean() async {
        guard canRunQuickClean else { return }
        isRunningQuickClean = true
        defer { isRunningQuickClean = false }

        if !didScanCleanupSources || !didScanDockerInventory {
            statusMessage = "Scanning safe cleanup sources..."
            if !didScanCleanupSources {
                await scanCleanupSources()
            }
            if !didScanDockerInventory {
                await scanDockerInventory()
            }
        }

        let safe = CleanupSelectionPlanner.quickCleanCandidates(from: allCandidates)
        guard !safe.isEmpty else {
            statusMessage = "No safe cleanup items found"
            return
        }

        statusMessage = "Quick cleaning \(safe.count) safe item(s)..."
        let expectedBytes = safe.reduce(UInt64(0)) { $0 + ($1.sizeBytes ?? 0) }
        let entries = await executor.execute(safe, confirmed: true)
        logs.insert(contentsOf: entries.reversed(), at: 0)
        selectedCandidateIDs.subtract(safe.map(\.id))
        lastCleanupSummary = CleanupRunSummary(
            bytesRequested: expectedBytes,
            itemCount: safe.count,
            failedCount: entries.filter { !$0.succeeded }.count
        )
        await scanCleanupSources()
        await scanPracticalCleanup()
        await scanDockerInventory()
        await refreshMachine()
        statusMessage = "Quick Clean finished"
    }

    func dismissCleanupConfirmation() {
        isShowingCleanupConfirmation = false
        pendingConfirmation = []
    }

    func executePendingCleanup() async {
        let selected = pendingConfirmation
        dismissCleanupConfirmation()
        guard !selected.isEmpty else { return }

        if selected.contains(where: { $0.category == .memory }) {
            await runMemoryOptimize(confirmed: true)
            return
        }

        statusMessage = "Cleaning \(selected.count) selected item(s)..."
        let expectedBytes = selected.reduce(UInt64(0)) { $0 + ($1.sizeBytes ?? 0) }
        let entries = await executor.execute(selected, confirmed: true)
        logs.insert(contentsOf: entries.reversed(), at: 0)
        selectedCandidateIDs.subtract(selected.map(\.id))
        lastCleanupSummary = CleanupRunSummary(
            bytesRequested: expectedBytes,
            itemCount: selected.count,
            failedCount: entries.filter { !$0.succeeded }.count
        )
        await scanCleanupSources()
        await scanPracticalCleanup()
        await scanNodeModules()
        await scanDockerInventory()
        await refreshMachine()
        statusMessage = "Cleanup finished"
    }

    func saveSettings() async {
        do {
            try await settingsStore.save(settings)
            statusMessage = "Settings saved"
        } catch {
            statusMessage = "Failed to save settings: \(error.localizedDescription)"
        }
    }

    var allCandidates: [CleanupCandidate] {
        cleanupSourceCandidates + practicalCandidates + nodeCandidates + dockerCandidates
    }

    var isScanned: Bool {
        allCandidates.contains { !$0.id.hasPrefix("mock.") }
    }

    var isBusyWithCleanupScan: Bool {
        isScanningSources || isScanningPractical || isScanningNodeModules || isScanningDocker || isRunningQuickClean
    }

    var canRunQuickClean: Bool {
        !isBusyWithCleanupScan
    }

    private func presentCleanupConfirmation(_ candidates: [CleanupCandidate]) {
        guard !candidates.isEmpty else {
            statusMessage = "Select at least one cleanup item first"
            return
        }
        pendingConfirmation = candidates
        isShowingCleanupConfirmation = true
    }

    private func startBackgroundRefresh() {
        guard !didStartBackgroundRefresh else { return }
        didStartBackgroundRefresh = true

        Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(30))
                await self?.refreshMachine()
            }
        }
    }

    private static var mockCleanupSourceCandidates: [CleanupCandidate] {
        [
            CleanupCandidate(
                id: "mock.docker-logs",
                category: .safeSystem,
                title: "Old Docker Logs",
                path: "~/Library/Containers/com.docker.docker/Data",
                sizeBytes: UInt64(2.43 * 1024 * 1024 * 1024),
                lastModified: Date(),
                risk: .low,
                detail: "Aggregated Docker runtime container logs."
            ),
            CleanupCandidate(
                id: "mock.system-logs",
                category: .safeSystem,
                title: "System Logs",
                path: "/private/var/log",
                sizeBytes: 680 * 1024 * 1024,
                lastModified: Date(),
                risk: .low,
                detail: "System messages and logging archives."
            ),
            CleanupCandidate(
                id: "mock.browser-cache",
                category: .devCaches,
                title: "Browser Cache",
                path: "~/Library/Caches/Google/Chrome",
                sizeBytes: 523 * 1024 * 1024,
                lastModified: Date(),
                risk: .low,
                detail: "Google Chrome local caching databases."
            ),
            CleanupCandidate(
                id: "mock.safe-system-extra",
                category: .safeSystem,
                title: "Temporary System Files",
                path: "/private/var/folders",
                sizeBytes: UInt64(0.9 * 1024 * 1024 * 1024),
                lastModified: Date(),
                risk: .low,
                detail: "Miscellaneous macOS temporary files."
            )
        ]
    }

    private static var mockPracticalCandidates: [CleanupCandidate] {
        [
            CleanupCandidate(
                id: "mock.downloads-old",
                category: .largeFiles,
                title: "Downloads (Old Files)",
                path: "~/Downloads",
                sizeBytes: UInt64(1.21 * 1024 * 1024 * 1024),
                lastModified: Calendar.current.date(byAdding: .day, value: -45, to: Date()),
                risk: .high,
                detail: "Large files in Downloads directory older than 30 days."
            ),
            CleanupCandidate(
                id: "mock.large-archive",
                category: .largeFiles,
                title: "Old Backup Archive",
                path: "~/Documents/Backup_2025.zip",
                sizeBytes: UInt64(6.99 * 1024 * 1024 * 1024),
                lastModified: Calendar.current.date(byAdding: .day, value: -90, to: Date()),
                risk: .high,
                detail: "Old system backup archive."
            ),
            CleanupCandidate(
                id: "mock.trash-item",
                category: .trashBins,
                title: "Trash Bin",
                path: "~/.Trash",
                sizeBytes: UInt64(1.6 * 1024 * 1024 * 1024),
                lastModified: Date(),
                risk: .medium,
                detail: "Items in Trash bin."
            ),
            CleanupCandidate(
                id: "mock.apps-cache",
                category: .applications,
                title: "Unused Apps",
                path: "/Applications/Xcode.app",
                sizeBytes: UInt64(512 * 1024 * 1024),
                lastModified: Calendar.current.date(byAdding: .day, value: -60, to: Date()),
                risk: .high,
                detail: "Cached app archives."
            )
        ]
    }

    private static var mockNodeCandidates: [CleanupCandidate] {
        [
            CleanupCandidate(
                id: "mock.node-modules.research-solutions",
                category: .nodeModules,
                title: "Reseach-solutions",
                path: "/Users/tinhuynh/Downloads/Reseach-solutions",
                sizeBytes: 263_500_000,
                lastModified: Date(),
                risk: .low,
                detail: "Project: /Users/tinhuynh/Downloads/Reseach-solutions"
            ),
            CleanupCandidate(
                id: "mock.node-modules.c2-signaling-server",
                category: .nodeModules,
                title: "C2 Signaling Server",
                path: "/Users/tinhuynh/Downloads/C2 Signaling Server",
                sizeBytes: 197_000,
                lastModified: Date(),
                risk: .low,
                detail: "Project: /Users/tinhuynh/Downloads/C2 Signaling Server"
            ),
            CleanupCandidate(
                id: "mock.node-modules.c2-signaling-server-2",
                category: .nodeModules,
                title: "C2 Signaling Server 2",
                path: "/Users/tinhuynh/Downloads/C2 Signaling Server 2",
                sizeBytes: 0,
                lastModified: Date(),
                risk: .low,
                detail: "Project: /Users/tinhuynh/Downloads/C2 Signaling Server 2"
            )
        ]
    }

    private static var mockDockerCandidates: [CleanupCandidate] {
        DockerCleanupPlanner().preview()
    }
}

struct CleanupRunSummary: Equatable {
    var bytesRequested: UInt64
    var itemCount: Int
    var failedCount: Int
}
