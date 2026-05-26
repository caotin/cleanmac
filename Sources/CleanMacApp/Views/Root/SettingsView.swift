import AppKit
import CleanMacCore
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var state: AppState
    @State private var newRoot = ""
    @State private var newLargeRoot = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Row
                HStack(alignment: .center) {
                    SectionHeader(
                        title: "Settings",
                        subtitle: "Tune scan roots, safety defaults, and cleanup sources.",
                        icon: "gearshape"
                    )
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Button(action: {
                            state.settings = CleanupSettings()
                            Task { await state.saveSettings() }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 11))
                                Text("Reset to Defaults")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundStyle(AppTheme.text)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(8)
                            .overlay {
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                            }
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: {}) {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 14))
                                .foregroundStyle(AppTheme.text)
                                .padding(8)
                                .background(Color.white.opacity(0.06))
                                .cornerRadius(8)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.bottom, 10)
                
                // First Row: Preset (Left) & Settings Overview (Right)
                HStack(alignment: .top, spacing: 20) {
                    // Preset Panel
                    GlassPanel(padding: 16) {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 10) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(AppTheme.cyan.opacity(0.12))
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(AppTheme.cyan)
                                }
                                .frame(width: 32, height: 32)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Preset")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(AppTheme.text)
                                    Text("Choose a preset configuration for scans and cleanup.")
                                        .font(.system(size: 11))
                                        .foregroundStyle(AppTheme.secondaryText)
                                }
                            }
                            
                            Divider()
                                .background(Color.white.opacity(0.08))
                            
                            HStack {
                                Text("Cleanup preset")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(AppTheme.secondaryText)
                                Spacer()
                                Menu {
                                    Button("Safe Daily") {
                                        state.settings.selectedPreset = "Safe Daily"
                                        Task { await state.saveSettings() }
                                    }
                                    Button("Manual Deep Clean") {
                                        state.settings.selectedPreset = "Manual Deep Clean"
                                        Task { await state.saveSettings() }
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Text(state.settings.selectedPreset)
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundStyle(AppTheme.text)
                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 8, weight: .bold))
                                            .foregroundStyle(AppTheme.secondaryText)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.white.opacity(0.06))
                                    .cornerRadius(6)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    }
                                }
                                .menuStyle(.button)
                                .buttonStyle(.plain)
                            }
                            
                            Button(action: {
                                state.settings.requireConfirmation.toggle()
                                Task { await state.saveSettings() }
                            }) {
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: state.settings.requireConfirmation ? "checkmark.square.fill" : "square")
                                        .font(.system(size: 15))
                                        .foregroundStyle(state.settings.requireConfirmation ? AppTheme.cyan : AppTheme.secondaryText)
                                        .padding(.top, 1)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Require confirmation before cleanup")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundStyle(AppTheme.text)
                                        Text("Ask for confirmation before deleting files or folders.")
                                            .font(.system(size: 10))
                                            .foregroundStyle(AppTheme.secondaryText)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Settings Overview Panel
                    GlassPanel(padding: 16) {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 10) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(Color(red: 0.5, green: 0.3, blue: 0.9).opacity(0.12))
                                    Image(systemName: "timer")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(Color(red: 0.6, green: 0.4, blue: 1.0))
                                }
                                .frame(width: 32, height: 32)
                                
                                Text("Settings Overview")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(AppTheme.text)
                            }
                            
                            Divider()
                                .background(Color.white.opacity(0.08))
                            
                            HStack(spacing: 0) {
                                // Scan Roots Overview
                                OverviewMetric(
                                    icon: "folder.fill",
                                    iconColor: AppTheme.cyan,
                                    bgColor: AppTheme.cyan.opacity(0.1),
                                    title: "Scan Roots",
                                    value: "\(state.settings.nodeSearchRoots.count)",
                                    subtitle: "Configured"
                                )
                                
                                Spacer()
                                
                                // Large File Rules
                                OverviewMetric(
                                    icon: "doc.text.fill",
                                    iconColor: Color(red: 0.55, green: 0.45, blue: 1.0),
                                    bgColor: Color(red: 0.55, green: 0.45, blue: 1.0).opacity(0.1),
                                    title: "Large File Rules",
                                    value: formatBytesCompact(state.settings.largeFileMinimumBytes),
                                    subtitle: "Minimum size"
                                )
                                
                                Spacer()
                                
                                // Safety
                                OverviewMetric(
                                    icon: "shield.fill",
                                    iconColor: AppTheme.teal,
                                    bgColor: AppTheme.teal.opacity(0.1),
                                    title: "Safety",
                                    value: state.settings.requireConfirmation ? "High" : "Medium",
                                    subtitle: "Protection level"
                                )
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                
                // Second Row: Left column (Node Roots, Large Files) & Right column (About, Tips)
                HStack(alignment: .top, spacing: 20) {
                    // Left Column (flexible width)
                    VStack(spacing: 20) {
                        // Node Search Roots Panel
                        GlassPanel(padding: 16) {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Node Search Roots")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(AppTheme.text)
                                        Text("Define folders to scan for node_modules and related dependencies.")
                                            .font(.system(size: 11))
                                            .foregroundStyle(AppTheme.secondaryText)
                                    }
                                    Spacer()
                                    Button(action: {
                                        selectFolder { path in
                                            if !state.settings.nodeSearchRoots.contains(path) {
                                                state.settings.nodeSearchRoots.append(path)
                                                Task { await state.saveSettings() }
                                            }
                                        }
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "plus")
                                                .font(.system(size: 10, weight: .bold))
                                            Text("Add Path")
                                                .font(.system(size: 11, weight: .semibold))
                                        }
                                        .foregroundStyle(AppTheme.cyan)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(AppTheme.cyan.opacity(0.1))
                                        .cornerRadius(6)
                                    }
                                    .buttonStyle(.plain)
                                }
                                
                                PathListEditor(
                                    paths: $state.settings.nodeSearchRoots,
                                    newPath: $newRoot,
                                    showBadge: true,
                                    onSave: {
                                        Task { await state.saveSettings() }
                                    },
                                    selectFolderAction: {
                                        selectFolder { path in
                                            if !state.settings.nodeSearchRoots.contains(path) {
                                                state.settings.nodeSearchRoots.append(path)
                                                Task { await state.saveSettings() }
                                            }
                                        }
                                    }
                                )
                            }
                        }
                        
                        // Large & Old Files Panel
                        GlassPanel(padding: 16) {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Large & Old Files")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(AppTheme.text)
                                        Text("Define minimum size and age for files to be considered for cleanup.")
                                            .font(.system(size: 11))
                                            .foregroundStyle(AppTheme.secondaryText)
                                    }
                                    Spacer()
                                    
                                    HStack(spacing: 12) {
                                        // Size picker
                                        HStack(spacing: 6) {
                                            Text("Minimum size")
                                                .font(.system(size: 11))
                                                .foregroundStyle(AppTheme.secondaryText)
                                            
                                            Menu {
                                                Button("50 MB") { state.settings.largeFileMinimumBytes = 50 * 1024 * 1024; Task { await state.saveSettings() } }
                                                Button("100 MB") { state.settings.largeFileMinimumBytes = 100 * 1024 * 1024; Task { await state.saveSettings() } }
                                                Button("250 MB") { state.settings.largeFileMinimumBytes = 250 * 1024 * 1024; Task { await state.saveSettings() } }
                                                Button("500 MB") { state.settings.largeFileMinimumBytes = 500 * 1024 * 1024; Task { await state.saveSettings() } }
                                                Button("1 GB") { state.settings.largeFileMinimumBytes = 1024 * 1024 * 1024; Task { await state.saveSettings() } }
                                                Button("2 GB") { state.settings.largeFileMinimumBytes = 2 * 1024 * 1024 * 1024; Task { await state.saveSettings() } }
                                                Button("5 GB") { state.settings.largeFileMinimumBytes = 5 * 1024 * 1024 * 1024; Task { await state.saveSettings() } }
                                            } label: {
                                                HStack(spacing: 4) {
                                                    Text(formatBytesLabel(state.settings.largeFileMinimumBytes))
                                                        .font(.system(size: 11, weight: .semibold))
                                                        .foregroundStyle(AppTheme.text)
                                                    Image(systemName: "chevron.up.chevron.down")
                                                        .font(.system(size: 8))
                                                        .foregroundStyle(AppTheme.secondaryText)
                                                }
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 5)
                                                .background(Color.white.opacity(0.06))
                                                .cornerRadius(5)
                                            }
                                            .menuStyle(.button)
                                            .buttonStyle(.plain)
                                        }
                                        
                                        // Age picker
                                        HStack(spacing: 6) {
                                            Text("Older than")
                                                .font(.system(size: 11))
                                                .foregroundStyle(AppTheme.secondaryText)
                                            
                                            Menu {
                                                Button("7 days") { state.settings.largeFileMinimumAgeDays = 7; Task { await state.saveSettings() } }
                                                Button("14 days") { state.settings.largeFileMinimumAgeDays = 14; Task { await state.saveSettings() } }
                                                Button("30 days") { state.settings.largeFileMinimumAgeDays = 30; Task { await state.saveSettings() } }
                                                Button("60 days") { state.settings.largeFileMinimumAgeDays = 60; Task { await state.saveSettings() } }
                                                Button("90 days") { state.settings.largeFileMinimumAgeDays = 90; Task { await state.saveSettings() } }
                                                Button("180 days") { state.settings.largeFileMinimumAgeDays = 180; Task { await state.saveSettings() } }
                                                Button("365 days") { state.settings.largeFileMinimumAgeDays = 365; Task { await state.saveSettings() } }
                                            } label: {
                                                HStack(spacing: 4) {
                                                    Text("\(state.settings.largeFileMinimumAgeDays) days")
                                                        .font(.system(size: 11, weight: .semibold))
                                                        .foregroundStyle(AppTheme.text)
                                                    Image(systemName: "chevron.up.chevron.down")
                                                        .font(.system(size: 8))
                                                        .foregroundStyle(AppTheme.secondaryText)
                                                }
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 5)
                                                .background(Color.white.opacity(0.06))
                                                .cornerRadius(5)
                                            }
                                            .menuStyle(.button)
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                                
                                PathListEditor(
                                    paths: $state.settings.largeFileSearchRoots,
                                    newPath: $newLargeRoot,
                                    showBadge: false,
                                    onSave: {
                                        Task { await state.saveSettings() }
                                    },
                                    selectFolderAction: {
                                        selectFolder { path in
                                            if !state.settings.largeFileSearchRoots.contains(path) {
                                                state.settings.largeFileSearchRoots.append(path)
                                                Task { await state.saveSettings() }
                                            }
                                        }
                                    }
                                )
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .top)
                    
                    // Right Column (fixed 280px width)
                    VStack(spacing: 20) {
                        // About Settings Panel
                        GlassPanel(padding: 16) {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("About Settings")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(AppTheme.text)
                                
                                Text("Customize how CleanMac scans and cleans your system.")
                                    .font(.system(size: 11))
                                    .foregroundStyle(AppTheme.secondaryText)
                                    .padding(.bottom, 4)
                                
                                InfoRow(
                                    icon: "folder.fill",
                                    iconColor: Color(red: 0.55, green: 0.45, blue: 1.0),
                                    title: "Scan Roots",
                                    desc: "Add or remove folders to include in scans."
                                )
                                
                                InfoRow(
                                    icon: "shield.fill",
                                    iconColor: AppTheme.teal,
                                    title: "Safety First",
                                    desc: "Smart protection to keep important files safe."
                                )
                                
                                InfoRow(
                                    icon: "sparkles",
                                    iconColor: AppTheme.cyan,
                                    title: "Custom Rules",
                                    desc: "Set your own rules for large and old files."
                                )
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        // Tips Panel
                        GlassPanel(padding: 16) {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack(spacing: 8) {
                                    Image(systemName: "lightbulb.fill")
                                        .font(.system(size: 14))
                                        .foregroundStyle(.yellow)
                                    Text("Tips")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(AppTheme.text)
                                }
                                
                                TipRow(
                                    icon: "checkmark.circle.fill",
                                    iconColor: AppTheme.cyan,
                                    title: "Be Specific",
                                    desc: "Add only the folders you want CleanMac to scan."
                                )
                                
                                TipRow(
                                    icon: "shield.checkmark.fill",
                                    iconColor: AppTheme.secondaryText,
                                    title: "Stay Safe",
                                    desc: "CleanMac will never remove system critical files."
                                )
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .frame(width: 280)
                }
            }
            .padding(24)
        }
    }

    // Helper functions
    private func selectFolder(completion: @escaping (String) -> Void) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.begin { response in
            if response == .OK, let url = panel.url {
                completion(url.path)
            }
        }
    }

    private func formatBytesCompact(_ value: UInt64) -> String {
        let mb = Double(value) / (1000.0 * 1000.0)
        if mb >= 1000.0 {
            let gb = mb / 1000.0
            return String(format: "%.1f GB", gb).replacingOccurrences(of: ".", with: ",")
        }
        return String(format: "%.1f MB", mb).replacingOccurrences(of: ".", with: ",")
    }

    private func formatBytesLabel(_ value: UInt64) -> String {
        let mb = Double(value) / (1024.0 * 1024.0)
        if mb >= 1024.0 {
            let gb = mb / 1024.0
            return String(format: "%.0f GB", gb)
        }
        return String(format: "%.0f MB", mb)
    }
}

// Helper views
struct OverviewMetric: View {
    var icon: String
    var iconColor: Color
    var bgColor: Color
    var title: String
    var value: String
    var subtitle: String
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(bgColor)
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(iconColor)
            }
            .frame(width: 36, height: 36)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
                Text(value)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(AppTheme.text)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
    }
}

struct PathListEditor: View {
    @Binding var paths: [String]
    @Binding var newPath: String
    var showBadge: Bool
    var onSave: () -> Void
    var selectFolderAction: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(paths, id: \.self) { path in
                HStack(spacing: 12) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.cyan)
                    
                    Text(path)
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.text)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    
                    Spacer()
                    
                    if showBadge {
                        Text("Active")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(AppTheme.green)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppTheme.green.opacity(0.12))
                            .cornerRadius(4)
                    }
                    
                    Button(action: {
                        paths.removeAll { $0 == path }
                        onSave()
                    }) {
                        Text("Remove")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(AppTheme.secondaryText)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                    
                    Menu {
                        Button("Open in Finder") {
                            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: path)
                        }
                        Button("Copy Path") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(path, forType: .string)
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.secondaryText)
                            .padding(4)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(4)
                    }
                    .menuStyle(.button)
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.03))
                .cornerRadius(6)
            }
            
            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    TextField("Enter folder path to add...", text: $newPath)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                    
                    Button(action: selectFolderAction) {
                        Image(systemName: "folder")
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.04))
                .cornerRadius(6)
                .overlay {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                }
                
                Button("Add") {
                    let trimmed = newPath.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    if !paths.contains(trimmed) {
                        paths.append(trimmed)
                        onSave()
                    }
                    newPath = ""
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.cyan)
                .controlSize(.small)
            }
            .padding(.top, 4)
        }
    }
}

struct InfoRow: View {
    var icon: String
    var iconColor: Color
    var title: String
    var desc: String
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.12))
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(iconColor)
            }
            .frame(width: 28, height: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppTheme.text)
                Text(desc)
                    .font(.system(size: 10))
                    .foregroundStyle(AppTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct TipRow: View {
    var icon: String
    var iconColor: Color
    var title: String
    var desc: String
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppTheme.cyan.opacity(0.1))
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(iconColor)
            }
            .frame(width: 28, height: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppTheme.text)
                Text(desc)
                    .font(.system(size: 10))
                    .foregroundStyle(AppTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
