import Foundation

struct UpdateInfo: Equatable {
    let latestVersion: String
    let releaseNotes: String
    let releasePageURL: URL
}

final class UpdateService {
    private let owner = "caotin"
    private let repo = "cleanmac"
    private let checkIntervalSeconds: TimeInterval = 24 * 60 * 60  // 24 hours

    private var apiURL: URL {
        URL(string: "https://api.github.com/repos/\(owner)/\(repo)/releases/latest")!
    }

    private var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }

    /// Checks GitHub Releases API for a newer version.
    /// Returns `UpdateInfo` if a newer version is available, otherwise `nil`.
    func checkForUpdate() async -> UpdateInfo? {
        do {
            var request = URLRequest(url: apiURL)
            request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
            request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
            request.timeoutInterval = 15

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return nil
            }

            let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
            let latestVersion = release.tagName.trimmingCharacters(in: CharacterSet(charactersIn: "v"))

            guard isNewer(version: latestVersion, than: currentVersion) else {
                return nil
            }

            guard let releaseURL = URL(string: release.htmlURL) else {
                return nil
            }

            return UpdateInfo(
                latestVersion: latestVersion,
                releaseNotes: release.body?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
                releasePageURL: releaseURL
            )
        } catch {
            return nil
        }
    }

    /// Starts a background loop that checks for updates every 24 hours.
    func startPeriodicCheck(onUpdate: @Sendable @escaping (UpdateInfo?) async -> Void) {
        Task {
            while !Task.isCancelled {
                let info = await checkForUpdate()
                await onUpdate(info)
                try? await Task.sleep(for: .seconds(checkIntervalSeconds))
            }
        }
    }

    // MARK: - Version Comparison

    private func isNewer(version: String, than current: String) -> Bool {
        let latestParts = version.split(separator: ".").compactMap { Int($0) }
        let currentParts = current.split(separator: ".").compactMap { Int($0) }

        let maxLen = max(latestParts.count, currentParts.count)
        for i in 0..<maxLen {
            let l = i < latestParts.count ? latestParts[i] : 0
            let c = i < currentParts.count ? currentParts[i] : 0
            if l > c { return true }
            if l < c { return false }
        }
        return false
    }
}

// MARK: - GitHub API Model

private struct GitHubRelease: Decodable {
    let tagName: String
    let htmlURL: String
    let body: String?

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlURL = "html_url"
        case body
    }
}
