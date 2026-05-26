import CleanMacCore
import SwiftUI

struct DashboardTelemetryRow: View {
    var machine: MachineOverview
    var cpuHistory: [Double]
    var tempHistory: [Double]

    var body: some View {
        HStack(spacing: 16) {
            // CPU Card
            TelemetryCard(
                icon: "cpu",
                iconColor: .purple,
                title: "CPU",
                value: "\(Int(machine.cpuUsedPercent))%"
            ) {
                ZStack(alignment: .bottomLeading) {
                    TelemetryLineChart(data: cpuHistory, color: .purple)
                        .frame(height: 26)
                    Text("System Load")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(AppTheme.secondaryText.opacity(0.8))
                        .padding(.leading, 2)
                }
            }

            // Memory Card
            TelemetryCard(
                icon: "memorychip",
                iconColor: AppTheme.green,
                title: "Memory",
                value: "\(Int(machine.memoryUsedPercent * 100))%"
            ) {
                VStack(alignment: .leading, spacing: 6) {
                    ProgressView(value: machine.memoryUsedPercent)
                        .progressViewStyle(SleekProgressViewStyle(color: AppTheme.green))
                    Text("\(CleanMacFormatting.bytes(UInt64(Double(machine.memoryBytes) * machine.memoryUsedPercent))) / \(CleanMacFormatting.bytes(machine.memoryBytes))")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }

            // Storage SSD Card
            TelemetryCard(
                icon: "internaldrive.fill",
                iconColor: AppTheme.teal,
                title: "Storage (SSD)",
                value: "\(Int(diskRatio(machine.disk) * 100))%"
            ) {
                VStack(alignment: .leading, spacing: 6) {
                    ProgressView(value: diskRatio(machine.disk))
                        .progressViewStyle(SleekProgressViewStyle(color: AppTheme.teal))
                    Text("\(CleanMacFormatting.bytes(machine.disk.usedBytes)) / \(CleanMacFormatting.bytes(machine.disk.totalBytes))")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }

            // Temperature Card
            TelemetryCard(
                icon: "thermometer.medium",
                iconColor: .orange,
                title: "Temperature",
                value: "\(Int(machine.temperature))°C"
            ) {
                HStack(spacing: 8) {
                    Text("Normal")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(AppTheme.green)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppTheme.green.opacity(0.12))
                        .cornerRadius(4)
                    
                    TelemetryLineChart(data: tempHistory, color: .orange)
                        .frame(maxWidth: .infinity, maxHeight: 26)
                }
            }
        }
        .padding(.horizontal, 24)
    }

    private func diskRatio(_ disk: DiskOverview) -> Double {
        guard disk.totalBytes > 0 else { return 0 }
        return Double(disk.usedBytes) / Double(disk.totalBytes)
    }
}

struct TelemetryCard<Content: View>: View {
    var icon: String
    var iconColor: Color
    var title: String
    var value: String
    @ViewBuilder var content: Content

    var body: some View {
        GlassPanel(padding: 12) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(iconColor.opacity(0.12))
                            .frame(width: 24, height: 24)
                        Image(systemName: icon)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(iconColor)
                    }
                    
                    Text(title)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(AppTheme.secondaryText)
                    
                    Spacer()
                }

                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.bottom, 2)

                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct TelemetryLineChart: View {
    var data: [Double]
    var color: Color

    var body: some View {
        GeometryReader { geometry in
            Path { path in
                guard data.count > 1 else { return }
                let width = geometry.size.width
                let height = geometry.size.height
                let maxVal = data.max() ?? 100.0
                let minVal = data.min() ?? 0.0
                let diff = max(1.0, maxVal - minVal)

                for (index, val) in data.enumerated() {
                    let x = CGFloat(index) * (width / CGFloat(data.count - 1))
                    let normalizedY = CGFloat((val - minVal) / diff)
                    let y = height - (normalizedY * (height - 4)) - 2

                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(
                LinearGradient(
                    colors: [color, color.opacity(0.4)],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)
            )
            .shadow(color: color.opacity(0.35), radius: 4, y: 2)
        }
    }
}
