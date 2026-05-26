import AppKit
import CleanMacCore
import Foundation

struct RunningAppInfo: Identifiable, Equatable {
    var id: String
    var processIdentifier: pid_t
    var name: String
    var bundleIdentifier: String
    var memoryBytes: UInt64?
    var cpuPercent: Double?
    var isActive: Bool
    var isHidden: Bool
}

@MainActor
struct RunningAppService {
    private let protectedBundleIDs: Set<String> = [
        "com.apple.finder",
        "com.apple.dock",
        "com.apple.SystemUIServer",
        "com.apple.loginwindow",
        "com.apple.WindowManager"
    ]

    struct ProcessStats {
        var memoryBytes: UInt64
        var cpuPercent: Double
    }

    func scan() -> [RunningAppInfo] {
        let statsByPID = processStatsByPID()
        let currentPID = ProcessInfo.processInfo.processIdentifier

        return NSWorkspace.shared.runningApplications
            .filter { app in
                app.activationPolicy == .regular
                    && !app.isTerminated
                    && app.processIdentifier != currentPID
                    && !(app.bundleIdentifier.map { protectedBundleIDs.contains($0) } ?? false)
            }
            .compactMap { app in
                guard let name = app.localizedName, !name.isEmpty else { return nil }
                let bundleIdentifier = app.bundleIdentifier ?? "Unknown bundle"
                let stats = statsByPID[app.processIdentifier]
                return RunningAppInfo(
                    id: "\(app.processIdentifier)",
                    processIdentifier: app.processIdentifier,
                    name: name,
                    bundleIdentifier: bundleIdentifier,
                    memoryBytes: stats?.memoryBytes,
                    cpuPercent: stats?.cpuPercent,
                    isActive: app.isActive,
                    isHidden: app.isHidden
                )
            }
            .sorted {
                switch ($0.memoryBytes, $1.memoryBytes) {
                case let (left?, right?) where left != right:
                    return left > right
                case (_?, nil):
                    return true
                case (nil, _?):
                    return false
                default:
                    return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                }
            }
    }

    func terminate(processIDs: Set<pid_t>, force: Bool) async -> [CleanupLogEntry] {
        let apps = NSWorkspace.shared.runningApplications.filter { processIDs.contains($0.processIdentifier) }

        return apps.map { app in
            let name = app.localizedName ?? "\(app.processIdentifier)"
            let succeeded = force ? app.forceTerminate() : app.terminate()
            let action = force ? "Force kill app" : "Quit app"
            let mode = force ? "force kill" : "quit request"
            return CleanupLogEntry(
                action: action,
                detail: "\(name) (pid \(app.processIdentifier)): \(succeeded ? mode : "request failed")",
                succeeded: succeeded
            )
        }
    }

    private func processStatsByPID() -> [pid_t: ProcessStats] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/ps")
        process.arguments = ["-axo", "pid=,rss=,%cpu="]

        let pipe = Pipe()
        process.standardOutput = pipe

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return [:]
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""

        return output.split(separator: "\n").reduce(into: [pid_t: ProcessStats]()) { result, line in
            let parts = line.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: " ").filter { !$0.isEmpty }
            guard parts.count >= 3 else { return }
            if let pid = pid_t(parts[0]),
               let rss = UInt64(parts[1]),
               let cpu = Double(parts[2]) {
                result[pid] = ProcessStats(memoryBytes: rss * 1024, cpuPercent: cpu)
            }
        }
    }
}
