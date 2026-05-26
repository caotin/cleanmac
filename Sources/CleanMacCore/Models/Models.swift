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
            "\(homeDirectory)/Library/Caches"
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
