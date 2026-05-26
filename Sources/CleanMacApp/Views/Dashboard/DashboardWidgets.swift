import CleanMacCore
import SwiftUI

struct DashboardRecommendationsCard: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        GlassPanel(padding: 16) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Recommendations")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                    Spacer()
                    Button {
                        state.section = .cleanup
                    } label: {
                        Text("View All")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(AppTheme.cyan)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 4)

                RecommendationRow(title: "Remove 3 old Docker images", size: "2,1 GB")
                RecommendationRow(title: "Clean system cache", size: "5,2 GB")
                RecommendationRow(title: "Delete old log files", size: "1,3 GB")

                Divider()
                    .background(Color.white.opacity(0.08))
                    .padding(.vertical, 2)

                HStack {
                    Text("Potential Savings")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(AppTheme.secondaryText)
                    Spacer()
                    Text("7,3 GB")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color(red: 0.1, green: 0.5, blue: 1.0))
                }
            }
        }
    }
}

struct DashboardQuickActionsCard: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        GlassPanel(padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Quick Actions")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.bottom, 4)

                QuickActionButton(icon: "bolt.fill", iconColor: Color(red: 0.1, green: 0.5, blue: 1.0), title: "Smart Cleanup", desc: "Remove junk files") {
                    state.section = .smartScan
                }

                QuickActionButton(icon: "waveform.path.ecg", iconColor: AppTheme.green, title: "Free Memory", desc: "Optimize RAM usage") {
                    state.section = .memory
                }

                QuickActionButton(icon: "cube.box.fill", iconColor: AppTheme.teal, title: "Docker Cleanup", desc: "Remove unused data") {
                    state.section = .docker
                }

                QuickActionButton(icon: "shippingbox.fill", iconColor: .purple, title: "Remove Node Modules", desc: "Clean unused packages") {
                    state.section = .nodeModules
                }

                QuickActionButton(icon: "doc.text.fill", iconColor: AppTheme.amber, title: "Clear Logs", desc: "Remove old log files") {
                    state.section = .logs
                }

                QuickActionButton(icon: "trash.fill", iconColor: .orange, title: "Trash Cleanup", desc: "Empty system trash") {
                    state.section = .cleanup
                }
            }
        }
    }
}

struct DashboardTopResourceUsageCard: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        GlassPanel(padding: 16) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Top Resource Usage")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                    Spacer()
                    Button {
                        state.section = .memory
                    } label: {
                        Text("View All")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(AppTheme.cyan)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 4)

                ForEach(state.runningApps.prefix(5)) { app in
                    HStack {
                        AppIconView(bundleID: app.bundleIdentifier)
                            .frame(width: 14, height: 14)
                        Text(app.name)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(AppTheme.text)
                        Spacer()
                        Text(CleanMacFormatting.bytes(app.memoryBytes))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }
            }
        }
    }
}

struct QuickActionButton: View {
    var icon: String
    var iconColor: Color
    var title: String
    var desc: String
    var action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 28, height: 28)
                    Image(systemName: icon)
                        .font(.system(size: 13))
                        .foregroundStyle(iconColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white)
                    Text(desc)
                        .font(.system(size: 9))
                        .foregroundStyle(AppTheme.secondaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(AppTheme.secondaryText.opacity(0.5))
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(isHovered ? Color.white.opacity(0.04) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct RecommendationRow: View {
    var title: String
    var size: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.green)
            
            Text(title)
                .font(.system(size: 11))
                .foregroundStyle(AppTheme.text)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
            
            Text(size)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(AppTheme.secondaryText)
        }
    }
}
