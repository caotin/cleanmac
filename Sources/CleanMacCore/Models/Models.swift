import Foundation

public struct MachineOverview: Equatable, Sendable {
    public var model: String
    public var chip: String
    public var memoryBytes: UInt64
    public var memoryUsedPercent: Double
    public var macOSVersion: String
    public var disk: DiskOverview
    public var memoryPressure: String
    public var uptime: TimeInterval
    public var thermalState: String
    public var network: NetworkOverview
    public var docker: DockerStatus
    public var refreshedAt: Date
    public var cpuUsedPercent: Double
    public var temperature: Double

    public init(
        model: String,
        chip: String,
        memoryBytes: UInt64,
        memoryUsedPercent: Double,
        macOSVersion: String,
        disk: DiskOverview,
        memoryPressure: String,
        uptime: TimeInterval,
        thermalState: String,
        network: NetworkOverview,
        docker: DockerStatus,
        refreshedAt: Date,
        cpuUsedPercent: Double,
        temperature: Double
    ) {
        self.model = model
        self.chip = chip
        self.memoryBytes = memoryBytes
        self.memoryUsedPercent = memoryUsedPercent
        self.macOSVersion = macOSVersion
        self.disk = disk
        self.memoryPressure = memoryPressure
        self.uptime = uptime
        self.thermalState = thermalState
        self.network = network
        self.docker = docker
        self.refreshedAt = refreshedAt
        self.cpuUsedPercent = cpuUsedPercent
        self.temperature = temperature
    }
}

public struct DiskOverview: Equatable, Sendable {
    public var totalBytes: UInt64
    public var freeBytes: UInt64

    public init(totalBytes: UInt64, freeBytes: UInt64) {
        self.totalBytes = totalBytes
        self.freeBytes = freeBytes
    }

    public var usedBytes: UInt64 {
        totalBytes > freeBytes ? totalBytes - freeBytes : 0
    }
}

public struct NetworkOverview: Equatable, Sendable {
    public var primaryAddress: String
    public var interfaceName: String

    public init(primaryAddress: String, interfaceName: String) {
        self.primaryAddress = primaryAddress
        self.interfaceName = interfaceName
    }
}

public struct DockerStatus: Equatable, Sendable {
    public var isInstalled: Bool
    public var isRunning: Bool
    public var summary: String

    public init(isInstalled: Bool, isRunning: Bool, summary: String) {
        self.isInstalled = isInstalled
        self.isRunning = isRunning
        self.summary = summary
    }
}

public enum CleanupRisk: String, CaseIterable, Equatable, Sendable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
}

public enum CleanupCategory: String, CaseIterable, Equatable, Sendable {
    case memory = "Memory"
    case devCaches = "Dev Caches"
    case browserCaches = "Browser Caches"
    case aiDevCaches = "AI Dev Caches"
    case virtualizationCaches = "Virtualization Caches"
    case safeSystem = "Safe System"
    case nodeModules = "Node Modules"
    case dockerImages = "Docker Images"
    case dockerContainers = "Stopped Containers"
    case dockerVolumes = "Unused Volumes"
    case dockerBuildCache = "Build Cache"
    case largeFiles = "Large & Old Files"
    case trashBins = "Trash Bins"
    case applications = "Applications"
    case loginItems = "Login Items"
}

public enum CleanupSource: String, CaseIterable, Codable, Equatable, Sendable {
    case xcodeDerivedData
    case swiftPM
    case npm
    case yarn
    case pnpm
    case homebrew
    case userLogs
    case userCaches
    case pip
    case poetry
    case pipenv
    case cargo
    case go
    case pub
    case gradle
    case maven
    case cocoapods
    case carthage
    case composer
    case bun
    case corepack
    case tnpm
    case uv
    case ruff
    case mypy
    case pytest
    case jupyter
    case huggingFace
    case pytorch
    case tensorflow
    case wandb
    case pyenv
    case condaMetadata
    case rustup
    case ruby
    case bundler
    case cpan
    case mise
    case kubernetes
    case awsCLI
    case gcloud
    case azureCLI
    case typescript
    case electron
    case nodeGyp
    case turbo
    case vite
    case webpack
    case parcel
    case eslint
    case prettier
    case android
    case expo
    case xcodeIBSupport
    case playwright
    case puppeteer
    case codexCLI
    case cursorAgentLogs
    case lima
    case utm
    case vagrant
    case browserCaches

    public var title: String {
        switch self {
        case .xcodeDerivedData: "Xcode DerivedData"
        case .swiftPM: "SwiftPM Cache"
        case .npm: "npm Cache"
        case .yarn: "Yarn Cache"
        case .pnpm: "pnpm Store"
        case .homebrew: "Homebrew Cache"
        case .userLogs: "User Logs"
        case .userCaches: "User Caches"
        case .pip: "pip Cache"
        case .poetry: "Poetry Cache"
        case .pipenv: "Pipenv Cache"
        case .cargo: "Cargo Cache"
        case .go: "Go Cache"
        case .pub: "Pub Cache"
        case .gradle: "Gradle Cache"
        case .maven: "Maven Repository"
        case .cocoapods: "CocoaPods Cache"
        case .carthage: "Carthage Cache"
        case .composer: "Composer Cache"
        case .bun: "Bun Cache"
        case .corepack: "Corepack Cache"
        case .tnpm: "tnpm Cache"
        case .uv: "uv Cache"
        case .ruff: "Ruff Cache"
        case .mypy: "MyPy Cache"
        case .pytest: "Pytest Cache"
        case .jupyter: "Jupyter Runtime"
        case .huggingFace: "Hugging Face Cache"
        case .pytorch: "PyTorch Cache"
        case .tensorflow: "TensorFlow Cache"
        case .wandb: "Weights & Biases Cache"
        case .pyenv: "pyenv Cache"
        case .condaMetadata: "Conda Metadata Cache"
        case .rustup: "Rustup Downloads"
        case .ruby: "Ruby Cache"
        case .bundler: "Bundler Cache"
        case .cpan: "CPAN Cache"
        case .mise: "mise Cache"
        case .kubernetes: "Kubernetes Cache"
        case .awsCLI: "AWS CLI Cache"
        case .gcloud: "Google Cloud Logs"
        case .azureCLI: "Azure CLI Logs"
        case .typescript: "TypeScript Cache"
        case .electron: "Electron Cache"
        case .nodeGyp: "node-gyp Cache"
        case .turbo: "Turbo Cache"
        case .vite: "Vite Cache"
        case .webpack: "Webpack Cache"
        case .parcel: "Parcel Cache"
        case .eslint: "ESLint Cache"
        case .prettier: "Prettier Cache"
        case .android: "Android Cache"
        case .expo: "Expo Cache"
        case .xcodeIBSupport: "Xcode Interface Builder Cache"
        case .playwright: "Playwright Cache"
        case .puppeteer: "Puppeteer Cache"
        case .codexCLI: "Codex CLI Runtime Cache"
        case .cursorAgentLogs: "Cursor Agent Logs"
        case .lima: "Lima Download Cache"
        case .utm: "UTM Cache"
        case .vagrant: "Vagrant Temp Files"
        case .browserCaches: "Browser Caches"
        }
    }
}

public struct CleanupCandidate: Identifiable, Equatable, Sendable {
    public var id: String
    public var category: CleanupCategory
    public var title: String
    public var path: String?
    public var sizeBytes: UInt64?
    public var lastModified: Date?
    public var risk: CleanupRisk
    public var detail: String
    public var commandPreview: String?

    public init(
        id: String,
        category: CleanupCategory,
        title: String,
        path: String? = nil,
        sizeBytes: UInt64? = nil,
        lastModified: Date? = nil,
        risk: CleanupRisk,
        detail: String,
        commandPreview: String? = nil
    ) {
        self.id = id
        self.category = category
        self.title = title
        self.path = path
        self.sizeBytes = sizeBytes
        self.lastModified = lastModified
        self.risk = risk
        self.detail = detail
        self.commandPreview = commandPreview
    }
}

public struct CleanupLogEntry: Identifiable, Equatable, Codable, Sendable {
    public var id: UUID
    public var timestamp: Date
    public var action: String
    public var detail: String
    public var succeeded: Bool

    public init(id: UUID = UUID(), timestamp: Date = Date(), action: String, detail: String, succeeded: Bool) {
        self.id = id
        self.timestamp = timestamp
        self.action = action
        self.detail = detail
        self.succeeded = succeeded
    }
}

public struct CleanupSettings: Equatable, Codable, Sendable {
    public var ignoredPaths: [String]
    public var nodeSearchRoots: [String]
    public var enabledSources: [CleanupSource]
    public var requireConfirmation: Bool
    public var selectedPreset: String
    public var largeFileSearchRoots: [String]
    public var largeFileMinimumBytes: UInt64
    public var largeFileMinimumAgeDays: Int

    private enum CodingKeys: String, CodingKey {
        case ignoredPaths
        case nodeSearchRoots
        case enabledSources
        case requireConfirmation
        case selectedPreset
        case largeFileSearchRoots
        case largeFileMinimumBytes
        case largeFileMinimumAgeDays
    }

    public init(
        ignoredPaths: [String] = [],
        nodeSearchRoots: [String] = CleanupSettings.defaultSearchRoots(),
        enabledSources: [CleanupSource] = CleanupSource.allCases,
        requireConfirmation: Bool = true,
        selectedPreset: String = "Safe Daily",
        largeFileSearchRoots: [String] = CleanupSettings.defaultLargeFileSearchRoots(),
        largeFileMinimumBytes: UInt64 = 100 * 1_024 * 1_024,
        largeFileMinimumAgeDays: Int = 30
    ) {
        self.ignoredPaths = ignoredPaths
        self.nodeSearchRoots = nodeSearchRoots
        self.enabledSources = enabledSources
        self.requireConfirmation = requireConfirmation
        self.selectedPreset = selectedPreset
        self.largeFileSearchRoots = largeFileSearchRoots
        self.largeFileMinimumBytes = largeFileMinimumBytes
        self.largeFileMinimumAgeDays = largeFileMinimumAgeDays
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        ignoredPaths = try container.decodeIfPresent([String].self, forKey: .ignoredPaths) ?? []
        nodeSearchRoots = try container.decodeIfPresent([String].self, forKey: .nodeSearchRoots) ?? CleanupSettings.defaultSearchRoots()
        enabledSources = try container.decodeIfPresent([CleanupSource].self, forKey: .enabledSources) ?? CleanupSource.allCases
        requireConfirmation = try container.decodeIfPresent(Bool.self, forKey: .requireConfirmation) ?? true
        selectedPreset = try container.decodeIfPresent(String.self, forKey: .selectedPreset) ?? "Safe Daily"
        largeFileSearchRoots = try container.decodeIfPresent([String].self, forKey: .largeFileSearchRoots) ?? CleanupSettings.defaultLargeFileSearchRoots()
        largeFileMinimumBytes = try container.decodeIfPresent(UInt64.self, forKey: .largeFileMinimumBytes) ?? 100 * 1_024 * 1_024
        largeFileMinimumAgeDays = try container.decodeIfPresent(Int.self, forKey: .largeFileMinimumAgeDays) ?? 30
    }

    public static func defaultSearchRoots(homeDirectory: String = FileManager.default.homeDirectoryForCurrentUser.path) -> [String] {
        [
            homeDirectory
        ]
    }

    public static func defaultSafeDeletionRoots(homeDirectory: String = FileManager.default.homeDirectoryForCurrentUser.path) -> [String] {
        [
            "\(homeDirectory)/Library/Developer/Xcode/DerivedData",
            "\(homeDirectory)/Library/Caches/org.swift.swiftpm",
            "\(homeDirectory)/.npm",
            "\(homeDirectory)/Library/Caches/Yarn",
            "\(homeDirectory)/Library/pnpm/store",
            "\(homeDirectory)/Library/Caches/Homebrew",
            "\(homeDirectory)/Library/Logs",
            "\(homeDirectory)/Library/Caches",
            "\(homeDirectory)/Library/Caches/pip",
            "\(homeDirectory)/Library/Caches/pypoetry",
            "\(homeDirectory)/Library/Caches/pipenv",
            "\(homeDirectory)/.cargo/registry",
            "\(homeDirectory)/.cargo/git",
            "\(homeDirectory)/Library/Caches/go-build",
            "\(homeDirectory)/go/pkg/mod",
            "\(homeDirectory)/.pub-cache",
            "\(homeDirectory)/.gradle/caches",
            "\(homeDirectory)/.m2/repository",
            "\(homeDirectory)/Library/Caches/CocoaPods",
            "\(homeDirectory)/Library/Caches/carthage",
            "\(homeDirectory)/Library/Caches/composer",
            "\(homeDirectory)/.bun/install/cache",
            "\(homeDirectory)/.cache/node/corepack",
            "\(homeDirectory)/.tnpm/_cacache",
            "\(homeDirectory)/.tnpm/_logs",
            "\(homeDirectory)/.cache/uv",
            "\(homeDirectory)/.cache/ruff",
            "\(homeDirectory)/.cache/mypy",
            "\(homeDirectory)/.pytest_cache",
            "\(homeDirectory)/.jupyter/runtime",
            "\(homeDirectory)/.cache/huggingface",
            "\(homeDirectory)/.cache/torch",
            "\(homeDirectory)/.cache/tensorflow",
            "\(homeDirectory)/.cache/wandb",
            "\(homeDirectory)/.pyenv/cache",
            "\(homeDirectory)/.conda/pkgs/cache",
            "\(homeDirectory)/.rustup/downloads",
            "\(homeDirectory)/.gem/specs",
            "\(homeDirectory)/.bundle/cache",
            "\(homeDirectory)/.cpan/build",
            "\(homeDirectory)/.cpan/sources",
            "\(homeDirectory)/Library/Caches/mise",
            "\(homeDirectory)/.kube/cache",
            "\(homeDirectory)/.aws/cli/cache",
            "\(homeDirectory)/.config/gcloud/logs",
            "\(homeDirectory)/.azure/logs",
            "\(homeDirectory)/.cache/typescript",
            "\(homeDirectory)/.cache/electron",
            "\(homeDirectory)/.cache/node-gyp",
            "\(homeDirectory)/.node-gyp",
            "\(homeDirectory)/.turbo/cache",
            "\(homeDirectory)/.vite/cache",
            "\(homeDirectory)/.cache/vite",
            "\(homeDirectory)/.cache/webpack",
            "\(homeDirectory)/.parcel-cache",
            "\(homeDirectory)/.cache/eslint",
            "\(homeDirectory)/.cache/prettier",
            "\(homeDirectory)/.android/build-cache",
            "\(homeDirectory)/.android/cache",
            "\(homeDirectory)/Library/Caches/Google/AndroidStudio",
            "\(homeDirectory)/.expo/expo-go",
            "\(homeDirectory)/.expo/android-apk-cache",
            "\(homeDirectory)/.expo/ios-simulator-app-cache",
            "\(homeDirectory)/.expo/native-modules-cache",
            "\(homeDirectory)/.expo/schema-cache",
            "\(homeDirectory)/.expo/template-cache",
            "\(homeDirectory)/.expo/versions-cache",
            "\(homeDirectory)/Library/Developer/Xcode/UserData/IB Support",
            "\(homeDirectory)/Library/Caches/ms-playwright",
            "\(homeDirectory)/.cache/puppeteer",
            "\(homeDirectory)/.cache/codex",
            "\(homeDirectory)/.codex/log",
            "\(homeDirectory)/.cursor/agent/logs",
            "\(homeDirectory)/Library/Application Support/Cursor/logs",
            "\(homeDirectory)/Library/Caches/lima/download/by-url-sha256",
            "\(homeDirectory)/Library/Caches/com.utmapp.UTM",
            "\(homeDirectory)/Library/Containers/com.utmapp.UTM/Data/Library/Caches",
            "\(homeDirectory)/.vagrant.d/tmp",
            "\(homeDirectory)/Library/Caches/Google/Chrome",
            "\(homeDirectory)/Library/Caches/Chromium",
            "\(homeDirectory)/Library/Caches/com.microsoft.edgemac",
            "\(homeDirectory)/Library/Caches/company.thebrowser.Browser",
            "\(homeDirectory)/Library/Caches/BraveSoftware/Brave-Browser",
            "\(homeDirectory)/Library/Caches/Firefox",
            "\(homeDirectory)/Library/Caches/com.operasoftware.Opera",
            "\(homeDirectory)/Library/Caches/com.vivaldi.Vivaldi",
            "\(homeDirectory)/Library/Caches/com.kagi.kagimacOS",
            "\(homeDirectory)/Library/Caches/zen"
        ]
    }

    public static func defaultLargeFileSearchRoots(homeDirectory: String = FileManager.default.homeDirectoryForCurrentUser.path) -> [String] {
        [
            "\(homeDirectory)/Desktop",
            "\(homeDirectory)/Documents",
            "\(homeDirectory)/Downloads"
        ]
    }
}

public enum CleanMacFormatting {
    public static func bytes(_ value: UInt64?) -> String {
        guard let value else { return "Unknown" }
        return ByteCountFormatter.string(fromByteCount: Int64(value), countStyle: .file)
    }

    public static func duration(_ seconds: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: seconds) ?? "Unknown"
    }
}

public enum CleanupSelectionPlanner {
    public static func quickCleanCandidates(from candidates: [CleanupCandidate]) -> [CleanupCandidate] {
        candidates.filter { $0.risk == .low }
    }
}

public struct CandidateReviewFilter: Equatable, Sendable {
    public var searchText: String
    public var risks: Set<CleanupRisk>
    public var categories: Set<CleanupCategory>

    public init(searchText: String = "", risks: Set<CleanupRisk> = [], categories: Set<CleanupCategory> = []) {
        self.searchText = searchText
        self.risks = risks
        self.categories = categories
    }
}

public struct CandidateGroupSummary: Equatable, Sendable {
    public var category: CleanupCategory
    public var candidates: [CleanupCandidate]
    public var totalBytes: UInt64

    public init(category: CleanupCategory, candidates: [CleanupCandidate]) {
        self.category = category
        self.candidates = candidates
        self.totalBytes = candidates.reduce(UInt64(0)) { $0 + ($1.sizeBytes ?? 0) }
    }
}

public struct CleanupConfirmationSummary: Equatable, Sendable {
    public var itemCount: Int
    public var totalBytes: UInt64
    public var lowRiskCount: Int
    public var mediumRiskCount: Int
    public var highRiskCount: Int
    public var highRiskNames: [String]

    public init(candidates: [CleanupCandidate]) {
        itemCount = candidates.count
        totalBytes = candidates.reduce(UInt64(0)) { $0 + ($1.sizeBytes ?? 0) }
        lowRiskCount = candidates.filter { $0.risk == .low }.count
        mediumRiskCount = candidates.filter { $0.risk == .medium }.count
        highRiskCount = candidates.filter { $0.risk == .high }.count
        highRiskNames = candidates.filter { $0.risk == .high }.map(\.title)
    }
}

public enum CandidateReviewPlanner {
    public static func filteredCandidates(_ candidates: [CleanupCandidate], filter: CandidateReviewFilter) -> [CleanupCandidate] {
        let query = filter.searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return sortedCandidates(candidates.filter { candidate in
            let matchesSearch = query.isEmpty
                || candidate.title.lowercased().contains(query)
                || candidate.detail.lowercased().contains(query)
                || (candidate.path?.lowercased().contains(query) ?? false)
            let matchesRisk = filter.risks.isEmpty || filter.risks.contains(candidate.risk)
            let matchesCategory = filter.categories.isEmpty || filter.categories.contains(candidate.category)
            return matchesSearch && matchesRisk && matchesCategory
        })
    }

    public static func sortedCandidates(_ candidates: [CleanupCandidate]) -> [CleanupCandidate] {
        candidates.sorted { lhs, rhs in
            switch (lhs.sizeBytes, rhs.sizeBytes) {
            case let (left?, right?) where left != right:
                return left > right
            case (_?, nil):
                return true
            case (nil, _?):
                return false
            default:
                return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            }
        }
    }

    public static func groupedCandidates(_ candidates: [CleanupCandidate]) -> [CandidateGroupSummary] {
        let grouped = Dictionary(grouping: sortedCandidates(candidates), by: \.category)
        return grouped
            .map { CandidateGroupSummary(category: $0.key, candidates: $0.value) }
            .sorted { $0.totalBytes == $1.totalBytes ? $0.category.rawValue < $1.category.rawValue : $0.totalBytes > $1.totalBytes }
    }

    public static func selectAllIDs(from candidates: [CleanupCandidate]) -> Set<String> {
        Set(candidates.map(\.id))
    }
}
