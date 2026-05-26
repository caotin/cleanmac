import CleanMacCore
import SwiftUI

struct DockerCleanupView: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header section
                HStack {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(LinearGradient(colors: [Color(red: 0.1, green: 0.6, blue: 0.9), Color(red: 0.05, green: 0.4, blue: 0.75)], startPoint: .top, endPoint: .bottom))
                                .frame(width: 32, height: 32)
                            Image(systemName: "cube.box.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(.white)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Docker Cleanup")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.white)
                            Text("Scan Docker inventory, then select images, stopped containers, unused volumes, or build cache to clean.")
                                .font(.system(size: 11))
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                    }
                    Spacer()
                    HStack(spacing: 8) {
                        Button {
                            Task {
                                await state.scanDockerInventory()
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
                            // Docker action option
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
                        // Docker Telemetry Cards Group
                        DockerTelemetryCard()
                        
                        // Docker Review Table Card
                        GlassPanel(padding: 16) {
                            VStack(alignment: .leading, spacing: 14) {
                                CandidateReviewTable(candidates: state.dockerCandidates, title: "Docker Resource Inventory")
                                    .frame(minHeight: 280)
                                
                                // Action buttons
                                HStack(spacing: 12) {
                                    Button {
                                        Task {
                                            await state.scanDockerInventory()
                                        }
                                    } label: {
                                        Text("Scan Docker")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 6)
                                            .background(Color(red: 0.1, green: 0.6, blue: 0.9))
                                            .cornerRadius(14)
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(state.isScanningDocker)

                                    Button {
                                        state.cleanSelectedPreview()
                                    } label: {
                                        Text("Run Clean")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundStyle(selectedDockerCount > 0 ? Color(red: 1.0, green: 0.28, blue: 0.36) : AppTheme.secondaryText)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 6)
                                            .background(selectedDockerCount > 0 ? Color(red: 1.0, green: 0.28, blue: 0.36).opacity(0.12) : Color.white.opacity(0.04))
                                            .cornerRadius(14)
                                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(selectedDockerCount > 0 ? Color(red: 1.0, green: 0.28, blue: 0.36).opacity(0.24) : Color.clear, lineWidth: 1))
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(selectedDockerCount == 0)

                                    if selectedDockerCount > 0 {
                                        Text("\(selectedDockerCount) item(s) selected")
                                            .font(.system(size: 11))
                                            .foregroundStyle(AppTheme.secondaryText)
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.top, 4)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)

                    // Right Column (~35%)
                    VStack(alignment: .leading, spacing: 20) {
                        // Docker Daemon Status
                        GlassPanel(padding: 16) {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("Daemon Status")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(.white)
                                
                                let isRunning = state.machine?.docker.isRunning ?? false
                                
                                HStack(spacing: 8) {
                                    Image(systemName: isRunning ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                                        .font(.system(size: 14))
                                        .foregroundStyle(isRunning ? AppTheme.green : AppTheme.amber)
                                    Text(isRunning ? "Docker is Running" : "Docker Daemon Offline")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                                
                                Text(state.machine?.docker.summary ?? "Docker CLI interface cannot connect to dockerd daemon.")
                                    .font(.system(size: 9.5))
                                    .foregroundStyle(AppTheme.secondaryText)
                                    .lineSpacing(3)
                            }
                        }

                        // Docker Storage Trend / Insights
                        GlassPanel(padding: 16) {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("Storage Insights")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(.white)
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(alignment: .top) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Docker Disk Usage")
                                                .font(.system(size: 10, weight: .semibold))
                                                .foregroundStyle(AppTheme.secondaryText)
                                            Text(CleanMacFormatting.bytes(totalDockerBytes))
                                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                                .foregroundStyle(Color(red: 0.1, green: 0.6, blue: 0.9))
                                        }
                                        Spacer()
                                        
                                        SparklineLineChart(data: [25, 28, 26, 31, 28, 35, 32, 38, 41], color: Color(red: 0.1, green: 0.6, blue: 0.9))
                                            .frame(width: 80, height: 24)
                                            .padding(.top, 4)
                                    }
                                    Text("Docker images, stopped containers, build caches, and volumes footprint.")
                                        .font(.system(size: 9))
                                        .foregroundStyle(AppTheme.secondaryText)
                                        .lineLimit(2)
                                }
                            }
                        }

                        // Recommendations
                        GlassPanel(padding: 16) {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 6) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(AppTheme.cyan)
                                    Text("Recommendations")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(AppTheme.text)
                                }
                                
                                VStack(spacing: 8) {
                                    RecommendationRow(title: "Remove stopped containers", size: "Safe")
                                    RecommendationRow(title: "Prune builder cache", size: "~2,4 GB")
                                    RecommendationRow(title: "Prune dangling images", size: "~1,8 GB")
                                }
                            }
                        }
                    }
                    .frame(width: 320)
                }
            }
            .padding(24)
            .task {
                if state.dockerCandidates.contains(where: { $0.id == "docker.images" }) {
                    await state.scanDockerInventory()
                }
            }
        }
    }

    private var selectedDockerCount: Int {
        state.dockerCandidates.filter { state.selectedCandidateIDs.contains($0.id) }.count
    }

    private var totalDockerBytes: UInt64 {
        state.dockerCandidates.reduce(UInt64(0)) { $0 + ($1.sizeBytes ?? 0) }
    }
}
