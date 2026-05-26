import CleanMacCore
import SwiftUI

struct NodeModulesTelemetryCard: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        GlassPanel(padding: 16) {
            HStack(spacing: 24) {
                // Radial progress ring
                ZStack {
                    Circle()
                        .trim(from: 0.0, to: 0.75)
                        .stroke(Color.white.opacity(0.04), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .frame(width: 110, height: 110)
                        .rotationEffect(.degrees(135))
                    
                    Circle()
                        .trim(from: 0.0, to: 0.75)
                        .stroke(
                            LinearGradient(
                                colors: [Color(red: 0.65, green: 0.45, blue: 0.95), Color(red: 0.25, green: 0.82, blue: 1.0)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .frame(width: 110, height: 110)
                        .rotationEffect(.degrees(135))
                        .shadow(color: Color(red: 0.65, green: 0.45, blue: 0.95).opacity(0.4), radius: 8)
                    
                    VStack(spacing: 1) {
                        Text(formattedSizeValue)
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text(formattedSizeUnit)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.top, -2)
                        Text("Total Size")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(AppTheme.secondaryText)
                            .padding(.top, 2)
                    }
                }
                .frame(width: 120, height: 120)
                
                Spacer()
                
                // 3 Columns of stats
                HStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Projects Scanned")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(AppTheme.secondaryText)
                        Text("\(state.nodeCandidates.count)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text(state.nodeCandidates.count == 1 ? "Project" : "Projects")
                            .font(.system(size: 10))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    .frame(width: 90, alignment: .leading)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Search Roots")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(AppTheme.secondaryText)
                        Text("\(state.settings.nodeSearchRoots.count)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text(state.settings.nodeSearchRoots.count == 1 ? "Root" : "Roots")
                            .font(.system(size: 10))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    .frame(width: 75, alignment: .leading)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Last Scan")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(AppTheme.secondaryText)
                        Text(state.isScanned ? "Just now" : "2 min ago")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(height: 29)
                        Text(state.isScanned ? "Today, \(currentTimeString)" : "Today, 20:45")
                            .font(.system(size: 10))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    .frame(width: 90, alignment: .leading)
                }
            }
        }
    }

    private var totalNodeModuleSize: UInt64 {
        state.nodeCandidates.reduce(UInt64(0)) { $0 + ($1.sizeBytes ?? 0) }
    }

    private var formattedSizeValue: String {
        let formatted = CleanMacFormatting.bytes(totalNodeModuleSize)
            .replacingOccurrences(of: "\u{00A0}", with: " ")
        let parts = formatted.components(separatedBy: " ")
        let sizeValue = parts.first ?? "0"
        return sizeValue.replacingOccurrences(of: ".", with: ",")
    }

    private var formattedSizeUnit: String {
        let formatted = CleanMacFormatting.bytes(totalNodeModuleSize)
            .replacingOccurrences(of: "\u{00A0}", with: " ")
        let parts = formatted.components(separatedBy: " ")
        return parts.count > 1 ? parts[1] : "MB"
    }

    private var currentTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: Date())
    }
}
