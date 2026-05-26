import CleanMacCore
import SwiftUI

struct MemoryCleanupView: View {
    @EnvironmentObject private var state: AppState
    @State private var searchText = ""
    @State private var selectedRisk = "All Risks"
    @State private var selectedCategory = "All Categories"
    @State private var isSafeOptimizeSelected = true
    @State private var isShowingAllRunningApps = false

    private let memoryCandidate = MemoryOptimizer(machineInfo: MachineInfoService()).preview()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header section
                HStack {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(LinearGradient(colors: [Color(red: 0.1, green: 0.5, blue: 1.0), Color(red: 0.1, green: 0.3, blue: 0.8)], startPoint: .top, endPoint: .bottom))
                                .frame(width: 32, height: 32)
                            Image(systemName: "memorychip")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Memory")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.white)
                            Text("Optimize memory and review running apps before quitting or force killing them.")
                                .font(.system(size: 11))
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                    }
                    Spacer()
                    HStack(spacing: 8) {
                        Button {
                            Task {
                                await state.refreshMachine()
                                state.refreshRunningApps()
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
                            // Options placeholder
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
                        GlassPanel(padding: 16) {
                            MemoryUsageCard(
                                usedPercent: usedPercent,
                                usedGBString: usedGBString,
                                totalGBString: totalGBString,
                                freeGBString: freeGBString,
                                pressureString: pressureString
                            )
                        }

                        GlassPanel(padding: 16) {
                            MemoryOptimizeReviewCard(
                                searchText: $searchText,
                                selectedRisk: $selectedRisk,
                                selectedCategory: $selectedCategory,
                                isSafeOptimizeSelected: $isSafeOptimizeSelected
                            )
                        }

                        GlassPanel(padding: 16) {
                            RunningAppsCard(
                                isShowingAllRunningApps: $isShowingAllRunningApps,
                                totalRunningAppMemory: totalRunningAppMemory,
                                selectedAppsCount: selectedAppsCount,
                                filteredApps: filteredApps
                            )
                        }
                    }
                    .frame(maxWidth: .infinity)

                    // Right Column (~35%)
                    VStack(alignment: .leading, spacing: 20) {
                        GlassPanel(padding: 16) {
                            MemoryInsightsCard()
                        }

                        GlassPanel(padding: 16) {
                            MemoryRecommendationsCard()
                        }

                        GlassPanel(padding: 16) {
                            PotentialMemoryReclaimCard()
                        }

                        GlassPanel(padding: 16) {
                            MemoryMonitorCard()
                        }
                    }
                    .frame(width: 320)
                }
            }
            .padding(24)
        }
    }

    // Calculations
    private var totalBytes: UInt64 {
        state.machine?.memoryBytes ?? UInt64(16 * 1024 * 1024 * 1024)
    }

    private var usedPercent: Double {
        state.machine?.memoryUsedPercent ?? 0.78
    }

    private var usedBytes: UInt64 {
        UInt64(Double(totalBytes) * usedPercent)
    }

    private var freeBytes: UInt64 {
        totalBytes > usedBytes ? totalBytes - usedBytes : 0
    }

    private var totalGBString: String {
        String(format: "%.0f GB", Double(totalBytes) / (1024 * 1024 * 1024))
    }

    private var usedGBString: String {
        String(format: "%.2f", Double(usedBytes) / (1024 * 1024 * 1024)).replacingOccurrences(of: ".", with: ",")
    }

    private var freeGBString: String {
        String(format: "%.2f", Double(freeBytes) / (1024 * 1024 * 1024)).replacingOccurrences(of: ".", with: ",")
    }

    private var pressureString: String {
        state.machine?.memoryPressure ?? "Normal"
    }

    private var totalRunningAppMemory: UInt64 {
        state.runningApps.reduce(UInt64(0)) { $0 + ($1.memoryBytes ?? 0) }
    }

    private var selectedAppsCount: Int {
        state.runningApps.filter { state.selectedRunningAppIDs.contains($0.id) }.count
    }

    private var filteredApps: [RunningAppInfo] {
        var apps = state.runningApps
        if !searchText.isEmpty {
            apps = apps.filter { app in
                app.name.localizedCaseInsensitiveContains(searchText) ||
                app.bundleIdentifier.localizedCaseInsensitiveContains(searchText)
            }
        }
        return apps
    }
}
