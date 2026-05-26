import CleanMacCore
import SwiftUI

struct MachineOverviewView: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SectionHeader(title: "Current Machine", subtitle: "Live machine telemetry for cleanup decisions.", icon: "desktopcomputer")

                if let machine = state.machine {
                    GlassPanel {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Text(machine.model)
                                    .font(.title.bold())
                                    .foregroundStyle(AppTheme.text)
                                Spacer()
                                Text(machine.chip)
                                    .foregroundStyle(AppTheme.secondaryText)
                            }
                            ProgressView(value: diskRatio(machine.disk))
                                .tint(AppTheme.cyan)
                            HStack {
                                Text("Disk used \(CleanMacFormatting.bytes(machine.disk.usedBytes))")
                                Spacer()
                                Text("\(CleanMacFormatting.bytes(machine.disk.freeBytes)) free")
                            }
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText)
                        }
                    }

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: 16)], spacing: 16) {
                        MetricCard(title: "Mac", value: machine.model, detail: machine.chip)
                        MetricCard(title: "Memory", value: CleanMacFormatting.bytes(machine.memoryBytes), detail: machine.memoryPressure)
                        MetricCard(title: "Disk Used", value: CleanMacFormatting.bytes(machine.disk.usedBytes), detail: "\(CleanMacFormatting.bytes(machine.disk.freeBytes)) free")
                        MetricCard(title: "macOS", value: machine.macOSVersion, detail: "Uptime \(CleanMacFormatting.duration(machine.uptime))")
                        MetricCard(title: "Thermal", value: machine.thermalState, detail: "Cleanup may be slower under thermal pressure")
                        MetricCard(title: "Network", value: machine.network.primaryAddress, detail: machine.network.interfaceName)
                        MetricCard(title: "Docker", value: machine.docker.isRunning ? "Running" : "Unavailable", detail: machine.docker.summary)
                    }
                } else {
                    ContentUnavailableView("No machine data", systemImage: "desktopcomputer", description: Text("Refresh to load local system information."))
                }

                Button("Refresh Now") {
                    Task { await state.refreshMachine() }
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.cyan)
            }
            .padding(24)
        }
    }

    private func diskRatio(_ disk: DiskOverview) -> Double {
        guard disk.totalBytes > 0 else { return 0 }
        return Double(disk.usedBytes) / Double(disk.totalBytes)
    }
}
