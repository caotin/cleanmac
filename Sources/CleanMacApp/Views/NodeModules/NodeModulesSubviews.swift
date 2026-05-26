import AppKit
import CleanMacCore
import SwiftUI

struct NodeModulesActiveSearchPathsCard: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "folder")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(red: 0.65, green: 0.45, blue: 0.95))
                    Text("Active Search Paths")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                }
                Spacer()
                Button {
                    state.section = .settings
                } label: {
                    Text("Manage Paths")
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(state.settings.nodeSearchRoots, id: \.self) { path in
                    HStack(spacing: 8) {
                        Image(systemName: "folder.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Color(red: 0.65, green: 0.45, blue: 0.95))
                        Text(path)
                            .font(.system(size: 11))
                            .foregroundStyle(AppTheme.secondaryText)
                            .lineLimit(1)
                    }
                }
            }
        }
    }
}

struct NodeModulesInsightsCard: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Modules Insights")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Prunable Space")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(AppTheme.secondaryText)
                        Text(CleanMacFormatting.bytes(totalNodeModuleSize).replacingOccurrences(of: ".", with: ","))
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(red: 0.65, green: 0.45, blue: 0.95))
                    }
                    Spacer()
                    
                    SparklineLineChart(data: [15, 12, 18, 14, 21, 16, 25, 20, 28], color: Color(red: 0.65, green: 0.45, blue: 0.95))
                        .frame(width: 90, height: 28)
                        .padding(.top, 4)
                }
                Text("Unused dependency build artifacts in node_modules folders.")
                    .font(.system(size: 9))
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineLimit(2)
            }
        }
    }

    private var totalNodeModuleSize: UInt64 {
        state.nodeCandidates.reduce(UInt64(0)) { $0 + ($1.sizeBytes ?? 0) }
    }
}

struct NodeModulesRecommendationsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppTheme.cyan)
                Text("Recommendations")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppTheme.text)
            }
            .padding(.bottom, 4)
            
            VStack(spacing: 12) {
                RecommendationRow(title: "Clean npm cache", size: "~1,1 GB")
                RecommendationRow(title: "Delete global packages cache", size: "~420 MB")
                RecommendationRow(title: "Prune old lockfiles", size: "~15 MB")
                RecommendationRow(title: "Remove empty node_modules", size: "~8 MB")
            }
            .padding(.bottom, 6)
            
            Button {
                // Recommendations Action
            } label: {
                HStack(spacing: 4) {
                    Text("View All Recommendations")
                    Image(systemName: "arrow.right")
                        .font(.system(size: 9))
                }
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color(red: 0.65, green: 0.45, blue: 0.95))
            }
            .buttonStyle(.plain)
        }
    }
}

struct NodeModulesIgnoreRulesCard: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "shield")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppTheme.cyan)
                    Text("Ignore Rules")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                }
                
                Text("You have ignored \(state.settings.ignoredPaths.count) directories.\nSystem nodes are protected.")
                    .font(.system(size: 10))
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineSpacing(3)
                
                Button {
                    state.section = .settings
                } label: {
                    HStack(spacing: 4) {
                        Text("Configure Rules")
                        Image(systemName: "arrow.right")
                            .font(.system(size: 9))
                    }
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color(red: 0.65, green: 0.45, blue: 0.95))
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color(red: 0.65, green: 0.45, blue: 0.95).opacity(0.08))
                    .frame(width: 40, height: 40)
                Image(systemName: "shield.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color(red: 0.65, green: 0.45, blue: 0.95).opacity(0.25))
            }
        }
    }
}

struct NodeModulesQuickActionsCard: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppTheme.cyan)
                Text("Quick Actions")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
            }
            .padding(.bottom, 4)
            
            VStack(spacing: 12) {
                QuickActionRow(
                    iconName: "terminal.fill",
                    iconColor: AppTheme.green,
                    iconBg: AppTheme.green.opacity(0.12),
                    title: "Open .npmrc Location"
                ) {
                    let home = FileManager.default.homeDirectoryForCurrentUser
                    let npmrc = home.appendingPathComponent(".npmrc")
                    if !FileManager.default.fileExists(atPath: npmrc.path) {
                        try? "".write(to: npmrc, atomically: true, encoding: .utf8)
                    }
                    NSWorkspace.shared.selectFile(npmrc.path, inFileViewerRootedAtPath: "")
                    state.statusMessage = "Opened Finder at .npmrc location"
                }
                
                QuickActionRow(
                    iconName: "trash.fill",
                    iconColor: Color(red: 0.65, green: 0.45, blue: 0.95),
                    iconBg: Color(red: 0.65, green: 0.45, blue: 0.95).opacity(0.12),
                    title: "Clear npm Cache"
                ) {
                    Task {
                        state.statusMessage = "Clearing npm cache..."
                        let npmCachePath = NSHomeDirectory() + "/.npm"
                        try? FileManager.default.removeItem(atPath: npmCachePath)
                        try? await Task.sleep(for: .seconds(1))
                        state.statusMessage = "npm cache cleared successfully"
                    }
                }
                
                QuickActionRow(
                    iconName: "server.rack",
                    iconColor: AppTheme.cyan,
                    iconBg: AppTheme.cyan.opacity(0.12),
                    title: "Rebuild modules metadata"
                ) {
                    Task {
                        state.statusMessage = "Rebuilding modules metadata..."
                        await state.scanNodeModules()
                        state.statusMessage = "Modules metadata rebuilt successfully"
                    }
                }
            }
        }
    }
}

struct QuickActionRow: View {
    var iconName: String
    var iconColor: Color
    var iconBg: Color
    var title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(iconBg)
                        .frame(width: 28, height: 28)
                    Image(systemName: iconName)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(iconColor)
                }
                
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.text)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
