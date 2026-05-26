import CleanMacCore
import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var state: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var pulseHeart = false
    @State private var cpuHistory: [Double] = (0..<25).map { _ in Double.random(in: 12.0...16.0) }
    @State private var tempHistory: [Double] = (0..<25).map { _ in Double.random(in: 41.0...43.0) }

    let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Bar
                HStack {
                    Spacer()
                    Text("Dashboard")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                    Spacer()
                    HStack(spacing: 12) {
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
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(14)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.1), lineWidth: 1))
                        }
                        .buttonStyle(.plain)

                        Button {
                            // menu placeholder
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 13, weight: .bold))
                                .frame(width: 28, height: 28)
                                .background(Color.white.opacity(0.06))
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                if let machine = state.machine {
                    // Top Row: System Health + At a Glance
                    DashboardTopRow(machine: machine, pulseHeart: pulseHeart)

                    // Middle Row: 4 Telemetry Cards (CPU, Memory, Storage, Temp)
                    DashboardTelemetryRow(
                        machine: machine,
                        cpuHistory: cpuHistory,
                        tempHistory: tempHistory
                    )

                    // Bottom Row: Balanced Column Layout
                    HStack(alignment: .top, spacing: 16) {
                        // Left Column: Running Applications Table + Recommendations
                        VStack(spacing: 16) {
                            DashboardRunningAppsTable()
                            DashboardRecommendationsCard()
                        }
                        .frame(maxWidth: .infinity)

                        // Right Column: Quick Actions + Top Resource Usage
                        VStack(spacing: 16) {
                            DashboardQuickActionsCard()
                            DashboardTopResourceUsageCard()
                        }
                        .frame(width: 320)
                    }
                    .padding(.horizontal, 24)
                } else {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            ProgressView()
                                .controlSize(.small)
                            Text("Loading dashboard telemetry...")
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 64)
                }
            }
            .padding(.bottom, 24)
        }
        .onAppear {
            pulseHeart = true
        }
        .onReceive(timer) { _ in
            guard let machine = state.machine else { return }
            let baseCPU = machine.cpuUsedPercent
            let fluctuatedCPU = max(1.0, min(100.0, baseCPU + Double.random(in: -2.0...2.0)))
            cpuHistory.append(fluctuatedCPU)
            if cpuHistory.count > 25 {
                cpuHistory.removeFirst()
            }
            
            let baseTemp = machine.temperature
            let fluctuatedTemp = max(35.0, min(100.0, baseTemp + Double.random(in: -0.4...0.4)))
            tempHistory.append(fluctuatedTemp)
            if tempHistory.count > 25 {
                tempHistory.removeFirst()
            }
        }
    }
}
