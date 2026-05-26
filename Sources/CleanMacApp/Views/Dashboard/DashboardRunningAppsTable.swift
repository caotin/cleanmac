import CleanMacCore
import SwiftUI

enum RunningAppTab: String, CaseIterable {
    case all = "All"
    case memory = "Memory"
    case cpu = "CPU"
    case energy = "Energy"
}

struct DashboardRunningAppsTable: View {
    @EnvironmentObject private var state: AppState
    @State private var activeTab: RunningAppTab = .all

    var body: some View {
        GlassPanel(padding: 0) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Running Applications")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    // Custom Tab bar
                    HStack(spacing: 4) {
                        ForEach(RunningAppTab.allCases, id: \.self) { tab in
                            Button {
                                withAnimation(.snappy(duration: 0.15)) {
                                    activeTab = tab
                                }
                            } label: {
                                Text(tab.rawValue)
                                    .font(.system(size: 11, weight: .bold))
                                    .lineLimit(1)
                                    .fixedSize(horizontal: true, vertical: false)
                                    .foregroundStyle(activeTab == tab ? .white : AppTheme.secondaryText)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(activeTab == tab ? Color.white.opacity(0.1) : Color.clear)
                                    .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(3)
                    .background(Color.white.opacity(0.04))
                    .cornerRadius(8)
                    
                    Spacer().frame(width: 16)
                    
                    Text("\(state.runningApps.count) active")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(AppTheme.secondaryText)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                // Table Header
                HStack(spacing: 0) {
                    Text("Application")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(AppTheme.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("Memory")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(AppTheme.secondaryText)
                        .frame(width: 80, alignment: .trailing)
                    
                    Spacer().frame(width: 24)

                    Text("CPU")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(AppTheme.secondaryText)
                        .frame(width: 60, alignment: .trailing)

                    Spacer().frame(width: 44) // matches Spacer (24) + Button (20)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.02))

                // Table list of top 5 apps sorted by active tab
                let sortedApps = sortApps(state.runningApps, by: activeTab).prefix(5)
                VStack(spacing: 0) {
                    ForEach(sortedApps) { app in
                        HStack(spacing: 0) {
                            HStack(spacing: 12) {
                                // Dynamic app icon lookup
                                AppIconView(bundleID: app.bundleIdentifier)
                                    .frame(width: 18, height: 18)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(app.name)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(.white)
                                    Text("PID \(app.processIdentifier)")
                                        .font(.system(size: 9))
                                        .foregroundStyle(AppTheme.secondaryText)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Text(CleanMacFormatting.bytes(app.memoryBytes))
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(AppTheme.secondaryText)
                                .frame(width: 80, alignment: .trailing)
                            
                            Spacer().frame(width: 24)
                            
                            Text(String(format: "%.1f%%", app.cpuPercent ?? 0.0))
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(AppTheme.secondaryText)
                                .frame(width: 60, alignment: .trailing)

                            Spacer().frame(width: 24)

                            Button {
                                state.pendingRunningAppTermination = [app]
                                state.isForceKillingApps = true
                                state.isShowingAppKillConfirmation = true
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 13))
                                    .foregroundStyle(AppTheme.red.opacity(0.8))
                            }
                            .buttonStyle(.plain)
                            .frame(width: 20, alignment: .trailing)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)

                        if app.id != sortedApps.last?.id {
                            Divider()
                                .background(Color.white.opacity(0.05))
                        }
                    }
                }

                Spacer().frame(height: 16)

                Button {
                    state.section = .memory
                } label: {
                    HStack {
                        Text("Show All Applications")
                        Image(systemName: "arrow.right")
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.cyan)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
    }

    private func sortApps(_ apps: [RunningAppInfo], by tab: RunningAppTab) -> [RunningAppInfo] {
        switch tab {
        case .all:
            return apps.sorted { ($0.memoryBytes ?? 0) > ($1.memoryBytes ?? 0) }
        case .memory:
            return apps.sorted { ($0.memoryBytes ?? 0) > ($1.memoryBytes ?? 0) }
        case .cpu:
            return apps.sorted { ($0.cpuPercent ?? 0.0) > ($1.cpuPercent ?? 0.0) }
        case .energy:
            return apps.sorted { ($0.cpuPercent ?? 0.0) > ($1.cpuPercent ?? 0.0) }
        }
    }
}
