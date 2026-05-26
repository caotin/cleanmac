import CleanMacCore
import SwiftUI

struct CleanupOverviewView: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header row
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 14) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Cleanup Center")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(.white)
                            Text("Review and safely remove unnecessary files to free up space and keep your Mac running smoothly.")
                                .font(.system(size: 12))
                                .foregroundStyle(AppTheme.secondaryText)
                                .lineLimit(2)
                        }
                        
                        HStack(spacing: 12) {
                            Button {
                                Task {
                                    await state.quickClean()
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    if state.isRunningQuickClean {
                                        ProgressView()
                                            .controlSize(.small)
                                            .scaleEffect(0.7)
                                    } else {
                                        Image(systemName: "sparkles")
                                    }
                                    Text(state.isRunningQuickClean ? "Cleaning..." : "Smart Cleanup")
                                }
                                .font(.system(size: 12, weight: .bold))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Color(red: 0.1, green: 0.5, blue: 1.0))
                            .disabled(state.isBusyWithCleanupScan)
                            
                            Button {
                                state.cleanSelectedPreview()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.circle")
                                    Text("Clean Selected")
                                }
                                .font(.system(size: 12))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.bordered)
                            .tint(.white)
                            .disabled(selectedCount == 0)
                        }
                    }
                    
                    Spacer(minLength: 40)
                    
                    CleanupInsightsCard()
                        .frame(width: 320)
                }
                .padding(.bottom, 4)

                // 4 Category Cards
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                    CleanupMetricCard(
                        title: "Practical",
                        value: cardBytes(for: [.largeFiles, .loginItems], defaultVal: "8,2 GB"),
                        count: cardCountText(for: [.largeFiles, .loginItems], defaultCountVal: "24 items"),
                        description: "Large files, downloads, and other clutter",
                        icon: "folder.fill",
                        iconBackground: LinearGradient(colors: [AppTheme.cyan, AppTheme.cyan.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing),
                        tintColor: AppTheme.cyan
                    ) {
                        // review action if any
                    }
                    
                    CleanupMetricCard(
                        title: "Safe System",
                        value: cardBytes(for: [.safeSystem, .devCaches], defaultVal: "2.1 GB"),
                        count: cardCountText(for: [.safeSystem, .devCaches], defaultCountVal: "11 items"),
                        description: "System cache, logs, and temporary files",
                        icon: "sparkles",
                        iconBackground: LinearGradient(colors: [AppTheme.green, AppTheme.green.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing),
                        tintColor: AppTheme.green
                    ) {
                        // review action
                    }
                    
                    CleanupMetricCard(
                        title: "Trash",
                        value: cardBytes(for: [.trashBins], defaultVal: "1.6 GB"),
                        count: cardCountText(for: [.trashBins], defaultCountVal: "7 items"),
                        description: "Trash bin and related files",
                        icon: "trash.fill",
                        iconBackground: LinearGradient(colors: [AppTheme.amber, AppTheme.amber.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing),
                        tintColor: AppTheme.amber
                    ) {
                        // review action
                    }
                    
                    CleanupMetricCard(
                        title: "Apps",
                        value: cardBytes(for: [.applications], defaultVal: "512 MB"),
                        count: cardCountText(for: [.applications], defaultCountVal: "8 items"),
                        description: "Unused app caches and residual files",
                        icon: "square.grid.2x2.fill",
                        iconBackground: LinearGradient(colors: [Color(red: 0.65, green: 0.45, blue: 0.95), Color(red: 0.65, green: 0.45, blue: 0.95).opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing),
                        tintColor: Color(red: 0.68, green: 0.44, blue: 0.98)
                    ) {
                        // review action
                    }
                }

                // Two columns layout below
                HStack(alignment: .top, spacing: 18) {
                    // Left: Cleanup Review Table
                    VStack {
                        CandidateReviewTable(candidates: state.allCandidates, title: "Cleanup Review")
                    }
                    .padding(14)
                    .background(.ultraThinMaterial)
                    .background(AppTheme.panel)
                    .cornerRadius(12)
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.white.opacity(0.08), lineWidth: 1)
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Right: Side widgets
                    VStack(spacing: 16) {
                        RecommendationsCard()
                        PotentialSavingsCard()
                        CleanupTipsCard()
                    }
                    .frame(width: 250)
                }
            }
            .padding(20)
        }
    }

    private var selectedCount: Int {
        state.allCandidates.filter { state.selectedCandidateIDs.contains($0.id) }.count
    }

    private func cardBytes(for categories: Set<CleanupCategory>, defaultVal: String) -> String {
        let bytes = state.allCandidates.filter { categories.contains($0.category) }.reduce(UInt64(0)) { $0 + ($1.sizeBytes ?? 0) }
        if state.isScanned {
            return CleanMacFormatting.bytes(bytes)
        }
        return defaultVal
    }

    private func cardCountText(for categories: Set<CleanupCategory>, defaultCountVal: String) -> String {
        let count = state.allCandidates.filter { categories.contains($0.category) }.count
        if state.isScanned {
            return "\(count) items"
        }
        return defaultCountVal
    }
}
