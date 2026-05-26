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

            let scannedCandidates = cleanupTargets(homeDirectory: homeDirectory)
                .filter { enabled.contains($0.source) }
                .filter { FileManager.default.fileExists(atPath: $0.path) }
                .flatMap { target in
                    candidates(for: target, ignoredPaths: ignored)
                }

            return uniqueCandidatesByPath(scannedCandidates)
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
        CleanupTarget(source: .composer, category: .devCaches, title: "Composer Cache", path: "\(homeDirectory)/Library/Caches/composer", risk: .low, scanChildren: true),
        CleanupTarget(source: .bun, category: .devCaches, title: "Bun Cache", path: "\(homeDirectory)/.bun/install/cache", risk: .low, scanChildren: true),
        CleanupTarget(source: .corepack, category: .devCaches, title: "Corepack Cache", path: "\(homeDirectory)/.cache/node/corepack", risk: .low, scanChildren: true),
        CleanupTarget(source: .tnpm, category: .devCaches, title: "tnpm Cache", path: "\(homeDirectory)/.tnpm/_cacache", risk: .low, scanChildren: true),
        CleanupTarget(source: .tnpm, category: .devCaches, title: "tnpm Logs", path: "\(homeDirectory)/.tnpm/_logs", risk: .low, scanChildren: true),
        CleanupTarget(source: .uv, category: .devCaches, title: "uv Cache", path: "\(homeDirectory)/.cache/uv", risk: .low, scanChildren: true),
        CleanupTarget(source: .ruff, category: .devCaches, title: "Ruff Cache", path: "\(homeDirectory)/.cache/ruff", risk: .low, scanChildren: true),
        CleanupTarget(source: .mypy, category: .devCaches, title: "MyPy Cache", path: "\(homeDirectory)/.cache/mypy", risk: .low, scanChildren: true),
        CleanupTarget(source: .pytest, category: .devCaches, title: "Pytest Cache", path: "\(homeDirectory)/.pytest_cache", risk: .low, scanChildren: true),
        CleanupTarget(source: .jupyter, category: .devCaches, title: "Jupyter Runtime", path: "\(homeDirectory)/.jupyter/runtime", risk: .low, scanChildren: true),
        CleanupTarget(source: .huggingFace, category: .aiDevCaches, title: "Hugging Face Cache", path: "\(homeDirectory)/.cache/huggingface", risk: .medium, scanChildren: true),
        CleanupTarget(source: .pytorch, category: .aiDevCaches, title: "PyTorch Cache", path: "\(homeDirectory)/.cache/torch", risk: .low, scanChildren: true),
        CleanupTarget(source: .tensorflow, category: .aiDevCaches, title: "TensorFlow Cache", path: "\(homeDirectory)/.cache/tensorflow", risk: .low, scanChildren: true),
        CleanupTarget(source: .wandb, category: .aiDevCaches, title: "Weights & Biases Cache", path: "\(homeDirectory)/.cache/wandb", risk: .medium, scanChildren: true),
        CleanupTarget(source: .pyenv, category: .devCaches, title: "pyenv Cache", path: "\(homeDirectory)/.pyenv/cache", risk: .low, scanChildren: true),
        CleanupTarget(source: .condaMetadata, category: .devCaches, title: "Conda Metadata Cache", path: "\(homeDirectory)/.conda/pkgs/cache", risk: .medium, scanChildren: true),
        CleanupTarget(source: .rustup, category: .devCaches, title: "Rustup Downloads", path: "\(homeDirectory)/.rustup/downloads", risk: .low, scanChildren: true),
        CleanupTarget(source: .ruby, category: .devCaches, title: "Ruby Gem Spec Cache", path: "\(homeDirectory)/.gem/specs", risk: .low, scanChildren: true),
        CleanupTarget(source: .bundler, category: .devCaches, title: "Bundler Cache", path: "\(homeDirectory)/.bundle/cache", risk: .low, scanChildren: true),
        CleanupTarget(source: .cpan, category: .devCaches, title: "CPAN Build Cache", path: "\(homeDirectory)/.cpan/build", risk: .low, scanChildren: true),
        CleanupTarget(source: .cpan, category: .devCaches, title: "CPAN Source Cache", path: "\(homeDirectory)/.cpan/sources", risk: .low, scanChildren: true),
        CleanupTarget(source: .mise, category: .devCaches, title: "mise Cache", path: "\(homeDirectory)/Library/Caches/mise", risk: .low, scanChildren: true),
        CleanupTarget(source: .kubernetes, category: .devCaches, title: "Kubernetes Cache", path: "\(homeDirectory)/.kube/cache", risk: .low, scanChildren: true),
        CleanupTarget(source: .awsCLI, category: .devCaches, title: "AWS CLI Cache", path: "\(homeDirectory)/.aws/cli/cache", risk: .low, scanChildren: true),
        CleanupTarget(source: .gcloud, category: .devCaches, title: "Google Cloud Logs", path: "\(homeDirectory)/.config/gcloud/logs", risk: .low, scanChildren: true),
        CleanupTarget(source: .azureCLI, category: .devCaches, title: "Azure CLI Logs", path: "\(homeDirectory)/.azure/logs", risk: .low, scanChildren: true),
        CleanupTarget(source: .typescript, category: .devCaches, title: "TypeScript Cache", path: "\(homeDirectory)/.cache/typescript", risk: .low, scanChildren: true),
        CleanupTarget(source: .electron, category: .devCaches, title: "Electron Cache", path: "\(homeDirectory)/.cache/electron", risk: .low, scanChildren: true),
        CleanupTarget(source: .nodeGyp, category: .devCaches, title: "node-gyp Cache", path: "\(homeDirectory)/.cache/node-gyp", risk: .low, scanChildren: true),
        CleanupTarget(source: .nodeGyp, category: .devCaches, title: "node-gyp Build Cache", path: "\(homeDirectory)/.node-gyp", risk: .low, scanChildren: true),
        CleanupTarget(source: .turbo, category: .devCaches, title: "Turbo Cache", path: "\(homeDirectory)/.turbo/cache", risk: .low, scanChildren: true),
        CleanupTarget(source: .vite, category: .devCaches, title: "Vite Cache", path: "\(homeDirectory)/.vite/cache", risk: .low, scanChildren: true),
        CleanupTarget(source: .vite, category: .devCaches, title: "Vite Global Cache", path: "\(homeDirectory)/.cache/vite", risk: .low, scanChildren: true),
        CleanupTarget(source: .webpack, category: .devCaches, title: "Webpack Cache", path: "\(homeDirectory)/.cache/webpack", risk: .low, scanChildren: true),
        CleanupTarget(source: .parcel, category: .devCaches, title: "Parcel Cache", path: "\(homeDirectory)/.parcel-cache", risk: .low, scanChildren: true),
        CleanupTarget(source: .eslint, category: .devCaches, title: "ESLint Cache", path: "\(homeDirectory)/.cache/eslint", risk: .low, scanChildren: true),
        CleanupTarget(source: .prettier, category: .devCaches, title: "Prettier Cache", path: "\(homeDirectory)/.cache/prettier", risk: .low, scanChildren: true),
        CleanupTarget(source: .android, category: .devCaches, title: "Android Build Cache", path: "\(homeDirectory)/.android/build-cache", risk: .low, scanChildren: true),
        CleanupTarget(source: .android, category: .devCaches, title: "Android SDK Cache", path: "\(homeDirectory)/.android/cache", risk: .low, scanChildren: true),
        CleanupTarget(source: .android, category: .devCaches, title: "Android Studio Cache", path: "\(homeDirectory)/Library/Caches/Google/AndroidStudio", risk: .medium, scanChildren: true),
        CleanupTarget(source: .expo, category: .devCaches, title: "Expo Go Cache", path: "\(homeDirectory)/.expo/expo-go", risk: .low, scanChildren: true),
        CleanupTarget(source: .expo, category: .devCaches, title: "Expo Android APK Cache", path: "\(homeDirectory)/.expo/android-apk-cache", risk: .low, scanChildren: true),
        CleanupTarget(source: .expo, category: .devCaches, title: "Expo iOS Simulator Cache", path: "\(homeDirectory)/.expo/ios-simulator-app-cache", risk: .low, scanChildren: true),
        CleanupTarget(source: .expo, category: .devCaches, title: "Expo Native Modules Cache", path: "\(homeDirectory)/.expo/native-modules-cache", risk: .low, scanChildren: true),
        CleanupTarget(source: .expo, category: .devCaches, title: "Expo Schema Cache", path: "\(homeDirectory)/.expo/schema-cache", risk: .low, scanChildren: true),
        CleanupTarget(source: .expo, category: .devCaches, title: "Expo Template Cache", path: "\(homeDirectory)/.expo/template-cache", risk: .low, scanChildren: true),
        CleanupTarget(source: .expo, category: .devCaches, title: "Expo Versions Cache", path: "\(homeDirectory)/.expo/versions-cache", risk: .low, scanChildren: true),
        CleanupTarget(source: .xcodeIBSupport, category: .devCaches, title: "Xcode Interface Builder Cache", path: "\(homeDirectory)/Library/Developer/Xcode/UserData/IB Support", risk: .low, scanChildren: true),
        CleanupTarget(source: .playwright, category: .devCaches, title: "Playwright Browser Cache", path: "\(homeDirectory)/Library/Caches/ms-playwright", risk: .low, scanChildren: true),
        CleanupTarget(source: .puppeteer, category: .devCaches, title: "Puppeteer Browser Cache", path: "\(homeDirectory)/.cache/puppeteer", risk: .low, scanChildren: true),
        CleanupTarget(source: .codexCLI, category: .aiDevCaches, title: "Codex CLI Cache", path: "\(homeDirectory)/.cache/codex", risk: .low, scanChildren: true),
        CleanupTarget(source: .codexCLI, category: .aiDevCaches, title: "Codex CLI Logs", path: "\(homeDirectory)/.codex/log", risk: .low, scanChildren: true),
        CleanupTarget(source: .cursorAgentLogs, category: .aiDevCaches, title: "Cursor Agent Logs", path: "\(homeDirectory)/.cursor/agent/logs", risk: .low, scanChildren: true),
        CleanupTarget(source: .cursorAgentLogs, category: .aiDevCaches, title: "Cursor Logs", path: "\(homeDirectory)/Library/Application Support/Cursor/logs", risk: .low, scanChildren: true),
        CleanupTarget(source: .lima, category: .virtualizationCaches, title: "Lima Download Cache", path: "\(homeDirectory)/Library/Caches/lima/download/by-url-sha256", risk: .low, scanChildren: true),
        CleanupTarget(source: .utm, category: .virtualizationCaches, title: "UTM App Cache", path: "\(homeDirectory)/Library/Caches/com.utmapp.UTM", risk: .low, scanChildren: true),
        CleanupTarget(source: .utm, category: .virtualizationCaches, title: "UTM Sandbox Cache", path: "\(homeDirectory)/Library/Containers/com.utmapp.UTM/Data/Library/Caches", risk: .medium, scanChildren: true),
        CleanupTarget(source: .vagrant, category: .virtualizationCaches, title: "Vagrant Temp Files", path: "\(homeDirectory)/.vagrant.d/tmp", risk: .low, scanChildren: true),
        CleanupTarget(source: .browserCaches, category: .browserCaches, title: "Chrome Cache", path: "\(homeDirectory)/Library/Caches/Google/Chrome", risk: .low, scanChildren: true),
        CleanupTarget(source: .browserCaches, category: .browserCaches, title: "Chromium Cache", path: "\(homeDirectory)/Library/Caches/Chromium", risk: .low, scanChildren: true),
        CleanupTarget(source: .browserCaches, category: .browserCaches, title: "Edge Cache", path: "\(homeDirectory)/Library/Caches/com.microsoft.edgemac", risk: .low, scanChildren: true),
        CleanupTarget(source: .browserCaches, category: .browserCaches, title: "Arc Cache", path: "\(homeDirectory)/Library/Caches/company.thebrowser.Browser", risk: .low, scanChildren: true),
        CleanupTarget(source: .browserCaches, category: .browserCaches, title: "Brave Cache", path: "\(homeDirectory)/Library/Caches/BraveSoftware/Brave-Browser", risk: .low, scanChildren: true),
        CleanupTarget(source: .browserCaches, category: .browserCaches, title: "Firefox Cache", path: "\(homeDirectory)/Library/Caches/Firefox", risk: .low, scanChildren: true),
        CleanupTarget(source: .browserCaches, category: .browserCaches, title: "Opera Cache", path: "\(homeDirectory)/Library/Caches/com.operasoftware.Opera", risk: .low, scanChildren: true),
        CleanupTarget(source: .browserCaches, category: .browserCaches, title: "Vivaldi Cache", path: "\(homeDirectory)/Library/Caches/com.vivaldi.Vivaldi", risk: .low, scanChildren: true),
        CleanupTarget(source: .browserCaches, category: .browserCaches, title: "Orion Cache", path: "\(homeDirectory)/Library/Caches/com.kagi.kagimacOS", risk: .low, scanChildren: true),
        CleanupTarget(source: .browserCaches, category: .browserCaches, title: "Zen Cache", path: "\(homeDirectory)/Library/Caches/zen", risk: .low, scanChildren: true),
        CleanupTarget(source: .userCaches, category: .safeSystem, title: "User App Caches", path: "\(homeDirectory)/Library/Caches", risk: .medium, scanChildren: true)
    ]
}

private func uniqueCandidatesByPath(_ candidates: [CleanupCandidate]) -> [CleanupCandidate] {
    var byPath: [String: CleanupCandidate] = [:]
    for candidate in candidates {
        let key = candidate.path ?? candidate.id
        if let existing = byPath[key] {
            if candidate.category != .safeSystem && existing.category == .safeSystem {
                byPath[key] = candidate
            }
            continue
        }
        byPath[key] = candidate
    }
    return Array(byPath.values)
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
