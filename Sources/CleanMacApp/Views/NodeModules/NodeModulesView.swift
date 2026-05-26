import CleanMacCore
import SwiftUI

struct NodeModulesView: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header section
                HStack {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(LinearGradient(colors: [Color(red: 0.65, green: 0.45, blue: 0.95), Color(red: 0.45, green: 0.25, blue: 0.85)], startPoint: .top, endPoint: .bottom))
                                .frame(width: 32, height: 32)
                            Image(systemName: "shippingbox.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(.white)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Node Modules")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.white)
                            Text("Scan configured roots, group by project/path/size/last modified, then select folders to delete.")
                                .font(.system(size: 11))
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                    }
                    Spacer()
                    HStack(spacing: 8) {
                        Button {
                            Task {
                                await state.scanNodeModules()
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 11))
                                Text("Start Over")
                            }
                            .font(.system(size: 12, weight: .medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(14)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.1), lineWidth: 1))
                        }
                        .buttonStyle(.plain)

                        Button {
                            // Option Menu
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 12, weight: .bold))
                                .frame(width: 28, height: 28)
                                .background(Color.white.opacity(0.06))
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.bottom, 8)

                // Two-Column Layout
                HStack(alignment: .top, spacing: 20) {
                    // Left Column (~65%)
                    VStack(alignment: .leading, spacing: 20) {
                        // Node Modules Telemetry Overview
                        NodeModulesTelemetryCard()

                        // Active Search Paths Card
                        GlassPanel(padding: 16) {
                            NodeModulesActiveSearchPathsCard()
                        }

                        // Project Node Modules Review Table Card
                        GlassPanel(padding: 16) {
                            VStack(alignment: .leading, spacing: 14) {
                                CandidateReviewTable(candidates: state.nodeCandidates, title: "Project Dependencies Review")
                                    .frame(minHeight: 280)
                                
                                // Batch Action Bar
                                HStack(spacing: 12) {
                                    Button {
                                        Task {
                                            await state.scanNodeModules()
                                        }
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: "sparkles")
                                                .font(.system(size: 10))
                                            Text("Scan Now")
                                                .font(.system(size: 11, weight: .bold))
                                        }
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 7)
                                        .background(Color(red: 0.65, green: 0.45, blue: 0.95))
                                        .cornerRadius(14)
                                        .shadow(color: Color(red: 0.65, green: 0.45, blue: 0.95).opacity(0.3), radius: 4)
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(state.isScanningNodeModules)

                                    Button {
                                        state.cleanSelectedPreview()
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: "trash")
                                                .font(.system(size: 10))
                                            Text("Delete Selected")
                                                .font(.system(size: 11, weight: .bold))
                                        }
                                        .foregroundStyle(selectedNodeModuleCount > 0 ? Color(red: 1.0, green: 0.28, blue: 0.36) : AppTheme.secondaryText)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 7)
                                        .background(selectedNodeModuleCount > 0 ? Color(red: 1.0, green: 0.28, blue: 0.36).opacity(0.12) : Color.white.opacity(0.04))
                                        .cornerRadius(14)
                                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(selectedNodeModuleCount > 0 ? Color(red: 1.0, green: 0.28, blue: 0.36).opacity(0.24) : Color.white.opacity(0.06), lineWidth: 1))
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(selectedNodeModuleCount == 0)
                                }
                                .padding(.top, 4)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)

                    // Right Column (~35%)
                    VStack(alignment: .leading, spacing: 20) {
                        // Node Modules Insights
                        GlassPanel(padding: 16) {
                            NodeModulesInsightsCard()
                        }

                        // Recommendations
                        GlassPanel(padding: 16) {
                            NodeModulesRecommendationsCard()
                        }

                        // Ignore Rules
                        GlassPanel(padding: 16) {
                            NodeModulesIgnoreRulesCard()
                        }

                        // Quick Actions
                        GlassPanel(padding: 16) {
                            NodeModulesQuickActionsCard()
                        }
                    }
                    .frame(width: 280)
                }
            }
            .padding(24)
        }
    }

    private var selectedNodeModuleCount: Int {
        state.nodeCandidates.filter { state.selectedCandidateIDs.contains($0.id) }.count
    }
}
