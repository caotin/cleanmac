import Foundation

public actor SettingsStore {
    private let url: URL

    public init(url: URL = SettingsStore.defaultURL()) {
        self.url = url
    }

    public func load() -> CleanupSettings {
        guard let data = try? Data(contentsOf: url),
              var settings = try? JSONDecoder().decode(CleanupSettings.self, from: data) else {
            return CleanupSettings()
        }
        if settings.enabledSources.isEmpty {
            settings.enabledSources = CleanupSource.allCases
        }
        return settings
    }

    public func save(_ settings: CleanupSettings) throws {
        let directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(settings)
        try data.write(to: url, options: [.atomic])
    }

    public static func defaultURL() -> URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/CleanMac/settings.json")
    }
}
