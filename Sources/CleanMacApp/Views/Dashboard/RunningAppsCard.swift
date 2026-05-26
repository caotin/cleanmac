import CleanMacCore
import SwiftUI

struct RunningAppsCard: View {
    @EnvironmentObject private var state: AppState
    @Binding var isShowingAllRunningApps: Bool
    var totalRunningAppMemory: UInt64
    var selectedAppsCount: Int
    var filteredApps: [RunningAppInfo]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Running Apps")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                Text("\(state.runningApps.count) app(s), \(CleanMacFormatting.bytes(totalRunningAppMemory))")
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            
            // Action bar buttons
            HStack(spacing: 12) {
                Button {
                    state.refreshRunningApps()
                } label: {
                    Text("Refresh Apps")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AppTheme.cyan)
                        .cornerRadius(14)
                }
                .buttonStyle(.plain)
                
                Button {
                    state.selectedRunningAppIDs.formUnion(state.runningApps.map(\.id))
                } label: {
                    Text("Select All")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(AppTheme.secondaryText)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(14)
                }
                .buttonStyle(.plain)
                .disabled(state.runningApps.isEmpty)
                
                Button {
                    state.selectedRunningAppIDs.subtract(state.runningApps.map(\.id))
                } label: {
                    Text("Clear Selection")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(AppTheme.secondaryText)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(14)
                }
                .buttonStyle(.plain)
                .disabled(selectedAppsCount == 0)
                
                Button {
                    state.confirmTerminateSelectedApps(force: false)
                } label: {
                    Text("Quit Selected")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(AppTheme.secondaryText)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(14)
                }
                .buttonStyle(.plain)
                .disabled(selectedAppsCount == 0)
                
                Button {
                    state.confirmTerminateSelectedApps(force: true)
                } label: {
                    Text("Force Kill Selected")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(AppTheme.secondaryText)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(14)
                }
                .buttonStyle(.plain)
                .disabled(selectedAppsCount == 0)
                
                Spacer()
            }
            
            // Running Apps List
            if filteredApps.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "app.dashed")
                        .font(.system(size: 24))
                        .foregroundStyle(AppTheme.secondaryText)
                    Text(state.runningApps.isEmpty ? "No running apps" : "No apps match search")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(Color.white.opacity(0.02))
                .cornerRadius(8)
            } else {
                VStack(spacing: 8) {
                    let appsToDisplay = isShowingAllRunningApps ? filteredApps : Array(filteredApps.prefix(5))
                    
                    ForEach(appsToDisplay) { app in
                        HStack(spacing: 12) {
                            Button {
                                if state.selectedRunningAppIDs.contains(app.id) {
                                    state.selectedRunningAppIDs.remove(app.id)
                                } else {
                                    state.selectedRunningAppIDs.insert(app.id)
                                }
                            } label: {
                                Image(systemName: state.selectedRunningAppIDs.contains(app.id) ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 14))
                                    .foregroundStyle(state.selectedRunningAppIDs.contains(app.id) ? AppTheme.cyan : AppTheme.secondaryText)
                            }
                            .buttonStyle(.plain)
                            
                            AppIconView(bundleID: app.bundleIdentifier)
                                .frame(width: 24, height: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(app.name)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.white)
                                Text(app.bundleIdentifier)
                                    .font(.system(size: 9))
                                    .foregroundStyle(AppTheme.secondaryText)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(CleanMacFormatting.bytes(app.memoryBytes ?? 0))
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(AppTheme.cyan)
                                Text("PID \(app.processIdentifier)")
                                    .font(.system(size: 9))
                                    .foregroundStyle(AppTheme.secondaryText)
                            }
                            
                            Button {
                                // context menu or single option action
                            } label: {
                                Image(systemName: "ellipsis")
                                    .font(.system(size: 10))
                                    .foregroundStyle(AppTheme.secondaryText)
                                    .padding(.horizontal, 4)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.02))
                        .cornerRadius(8)
                    }
                    
                    if filteredApps.count > 5 {
                        HStack {
                            Spacer()
                            Button {
                                withAnimation {
                                    isShowingAllRunningApps.toggle()
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Text(isShowingAllRunningApps ? "Show less" : "Show more")
                                    Image(systemName: isShowingAllRunningApps ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 8))
                                }
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(AppTheme.secondaryText)
                            }
                            .buttonStyle(.plain)
                            Spacer()
                        }
                        .padding(.top, 4)
                    }
                }
            }
        }
    }
}
