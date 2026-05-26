import CleanMacCore
import SwiftUI

struct CleanupInsightsCard: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppTheme.cyan)
                Text("Cleanup Insights")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppTheme.text)
            }
            
            HStack(spacing: 0) {
                // Total Removable
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total Removable")
                        .font(.system(size: 10))
                        .foregroundStyle(AppTheme.secondaryText)
                    
                    HStack(alignment: .bottom, spacing: 3) {
                        Text(totalRemovableValue)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.cyan)
                        Text(totalRemovableUnit)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(AppTheme.cyan)
                            .padding(.bottom, 2)
                    }
                    
                    Text("Safe to remove")
                        .font(.system(size: 9))
                        .foregroundStyle(AppTheme.secondaryText)
                }
                
                Spacer()
                
                Divider()
                    .frame(height: 38)
                    .overlay(Color.white.opacity(0.08))
                    .padding(.horizontal, 12)
                
                Spacer()
                
                // Items Found
                VStack(alignment: .leading, spacing: 2) {
                    Text("Items Found")
                        .font(.system(size: 10))
                        .foregroundStyle(AppTheme.secondaryText)
                    
                    Text(itemsFoundText)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 0.68, green: 0.44, blue: 0.98))
                    
                    Text("Across all categories")
                        .font(.system(size: 9))
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
            .padding(.vertical, 4)
            
            Divider()
                .overlay(Color.white.opacity(0.08))
            
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 9))
                    Text(lastScanText)
                        .font(.system(size: 9))
                }
                .foregroundStyle(AppTheme.secondaryText)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text("Scan Type")
                        .font(.system(size: 9))
                    Text("Deep Scan")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(AppTheme.cyan)
                }
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .background(AppTheme.panel)
        .cornerRadius(12)
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        }
    }

    private var totalRemovableValue: String {
        if state.isScanned {
            let bytes = state.allCandidates.reduce(UInt64(0)) { $0 + ($1.sizeBytes ?? 0) }
            let formatted = CleanMacFormatting.bytes(bytes)
            return String(formatted.split(separator: " ").first ?? "0")
        }
        return "12,4"
    }

    private var totalRemovableUnit: String {
        if state.isScanned {
            let bytes = state.allCandidates.reduce(UInt64(0)) { $0 + ($1.sizeBytes ?? 0) }
            let formatted = CleanMacFormatting.bytes(bytes)
            return String(formatted.split(separator: " ").last ?? "GB")
        }
        return "GB"
    }

    private var itemsFoundText: String {
        if state.isScanned {
            return "\(state.allCandidates.count)"
        }
        return "42"
    }

    private var lastScanText: String {
        state.isScanned ? "Last Scan: Just now" : "Last Scan: 2 mins ago"
    }
}

struct CleanupMetricCard: View {
    var title: String
    var value: String
    var count: String
    var description: String
    var icon: String
    var iconBackground: LinearGradient
    var tintColor: Color
    var action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 10) {
                    // Circle background with icon
                    ZStack {
                        Circle()
                            .fill(iconBackground)
                            .frame(width: 32, height: 32)
                        Image(systemName: icon)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(AppTheme.text)
                        
                        Text(value)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(tintColor)
                        
                        Text(count)
                            .font(.system(size: 10))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }
                
                Text(description)
                    .font(.system(size: 10))
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineLimit(2)
                    .frame(height: 28, alignment: .topLeading)
                
                HStack {
                    Text("Review")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(tintColor)
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(tintColor)
                }
                .padding(.top, 2)
            }
            .padding(12)
            .background(.ultraThinMaterial)
            .background(AppTheme.panel)
            .cornerRadius(12)
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isHovered ? tintColor.opacity(0.4) : .white.opacity(0.08), lineWidth: 1)
            }
            .scaleEffect(isHovered ? 1.015 : 1)
            .shadow(color: isHovered ? tintColor.opacity(0.1) : .clear, radius: 10, y: 4)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.snappy(duration: 0.18)) {
                isHovered = hovering
            }
        }
    }
}
