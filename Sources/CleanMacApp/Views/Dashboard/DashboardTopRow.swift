import CleanMacCore
import SwiftUI

struct DashboardTopRow: View {
    @EnvironmentObject private var state: AppState
    var machine: MachineOverview
    var pulseHeart: Bool

    var body: some View {
        HStack(spacing: 16) {
            DashboardSystemHealthCard(pulseHeart: pulseHeart)
            DashboardAtAGlanceCard(machine: machine)
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, 24)
    }
}

struct DashboardSystemHealthCard: View {
    @EnvironmentObject private var state: AppState
    var pulseHeart: Bool

    var body: some View {
        GlassPanel(padding: 20) {
            HStack(alignment: .top, spacing: 24) {
                // Pulsing Heart animation
                ZStack {
                    Circle()
                        .stroke(AppTheme.green.opacity(0.15), lineWidth: 6)
                        .frame(width: 110, height: 110)
                    
                    Circle()
                        .trim(from: 0.0, to: 0.92)
                        .stroke(
                            LinearGradient(colors: [AppTheme.green, AppTheme.teal], startPoint: .topLeading, endPoint: .bottomTrailing),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: 110, height: 110)
                        .rotationEffect(.degrees(-90))
                        .shadow(color: AppTheme.green.opacity(0.5), radius: 6)

                    VStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(AppTheme.green)
                            .shadow(color: AppTheme.green.opacity(0.6), radius: 8)
                            .scaleEffect(pulseHeart ? 1.08 : 0.95)
                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulseHeart)
                    }
                }
                .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 6) {
                    Text("SYSTEM HEALTH")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(AppTheme.secondaryText)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("Excellent")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(AppTheme.green)
                        Text("92")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(.white)
                        Text("/100")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AppTheme.secondaryText)
                    }

                    Text("Everything is running smoothly.")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.secondaryText)
                        .padding(.bottom, 12)

                    HStack(spacing: 12) {
                        Button {
                            state.section = .smartScan
                            Task { await state.scanAll() }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 12, weight: .bold))
                                Text("Smart Scan")
                            }
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color(red: 0.1, green: 0.5, blue: 1.0))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)

                        Button {
                            Task { await state.runMemoryOptimize(confirmed: true) }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 11))
                                Text("Optimize Now")
                            }
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.12), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
                Spacer()
            }
            .frame(maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity)
    }
}

struct DashboardAtAGlanceCard: View {
    @EnvironmentObject private var state: AppState
    var machine: MachineOverview

    var body: some View {
        GlassPanel(padding: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Text("At a Glance")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.bottom, 4)

                // Row 1: Junk Files
                AtAGlanceRow(
                    icon: "trash.fill",
                    iconColor: Color(red: 0.1, green: 0.5, blue: 1.0),
                    title: "Junk Files",
                    value: totalJunkBytes == 0 ? "25,26 GB" : CleanMacFormatting.bytes(totalJunkBytes)
                )

                // Row 2: Memory Used
                AtAGlanceProgressRow(
                    icon: "memorychip",
                    iconColor: AppTheme.green,
                    title: "Memory Used",
                    value: "\(Int(machine.memoryUsedPercent * 100))%",
                    progress: machine.memoryUsedPercent
                )

                // Row 3: Storage Used
                AtAGlanceProgressRow(
                    icon: "internaldrive.fill",
                    iconColor: AppTheme.teal,
                    title: "Storage Used",
                    value: "\(Int(diskRatio(machine.disk) * 100))%",
                    progress: diskRatio(machine.disk)
                )

                // Row 4: CPU Usage
                AtAGlanceProgressRow(
                    icon: "cpu",
                    iconColor: .purple,
                    title: "CPU Usage",
                    value: "\(Int(machine.cpuUsedPercent))%",
                    progress: machine.cpuUsedPercent / 100.0
                )
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .frame(width: 320)
    }

    private var totalJunkBytes: UInt64 {
        state.allCandidates.reduce(0) { $0 + ($1.sizeBytes ?? 0) }
    }

    private func diskRatio(_ disk: DiskOverview) -> Double {
        guard disk.totalBytes > 0 else { return 0 }
        return Double(disk.usedBytes) / Double(disk.totalBytes)
    }
}
