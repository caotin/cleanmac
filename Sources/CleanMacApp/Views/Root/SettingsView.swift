import CleanMacCore
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var state: AppState
    @State private var newRoot = ""
    @State private var newIgnore = ""
    @State private var newLargeRoot = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SectionHeader(title: "Settings", subtitle: "Tune scan roots, safety defaults, and cleanup sources.", icon: "gearshape")

                GlassPanel {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Preset")
                            .font(.title3.bold())
                            .foregroundStyle(AppTheme.text)
                        Picker("Cleanup preset", selection: $state.settings.selectedPreset) {
                            Text("Safe Daily").tag("Safe Daily")
                            Text("Manual Deep Clean").tag("Manual Deep Clean")
                        }
                        Toggle("Require confirmation before cleanup", isOn: Binding(
                            get: { state.settings.requireConfirmation },
                            set: { state.settings.requireConfirmation = $0 }
                        ))
                    }
                }

                GlassPanel {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Node search roots")
                            .font(.title3.bold())
                            .foregroundStyle(AppTheme.text)
                        PathEditor(paths: $state.settings.nodeSearchRoots, newPath: $newRoot)
                    }
                }

                GlassPanel {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Large & old files")
                            .font(.title3.bold())
                            .foregroundStyle(AppTheme.text)
                        HStack {
                            Stepper("Minimum size: \(CleanMacFormatting.bytes(state.settings.largeFileMinimumBytes))", value: $state.settings.largeFileMinimumBytes, in: 50 * 1_024 * 1_024...5 * 1_024 * 1_024 * 1_024, step: 50 * 1_024 * 1_024)
                            Stepper("Older than: \(state.settings.largeFileMinimumAgeDays) days", value: $state.settings.largeFileMinimumAgeDays, in: 7...365, step: 7)
                        }
                        PathEditor(paths: $state.settings.largeFileSearchRoots, newPath: $newLargeRoot)
                    }
                }

                GlassPanel {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Cleanup sources")
                            .font(.title3.bold())
                            .foregroundStyle(AppTheme.text)
                        ForEach(CleanupSource.allCases, id: \.self) { source in
                            Toggle(source.title, isOn: Binding(
                                get: { state.settings.enabledSources.contains(source) },
                                set: { isEnabled in
                                    if isEnabled {
                                        if !state.settings.enabledSources.contains(source) {
                                            state.settings.enabledSources.append(source)
                                        }
                                    } else {
                                        state.settings.enabledSources.removeAll { $0 == source }
                                    }
                                }
                            ))
                        }
                    }
                }

                GlassPanel {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Ignore list")
                            .font(.title3.bold())
                            .foregroundStyle(AppTheme.text)
                        PathEditor(paths: $state.settings.ignoredPaths, newPath: $newIgnore)
                    }
                }

                Button("Save Settings") {
                    Task { await state.saveSettings() }
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.cyan)
            }
            .padding(24)
        }
        .foregroundStyle(AppTheme.text)
    }
}

struct PathEditor: View {
    @Binding var paths: [String]
    @Binding var newPath: String

    var body: some View {
        ForEach(paths, id: \.self) { path in
            HStack {
                Text(path)
                    .foregroundStyle(AppTheme.text)
                Spacer()
                Button("Remove") {
                    paths.removeAll { $0 == path }
                }
            }
        }
        HStack {
            TextField("Path", text: $newPath)
            Button("Add") {
                let trimmed = newPath.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                paths.append(trimmed)
                newPath = ""
            }
        }
        .tint(AppTheme.cyan)
    }
}
