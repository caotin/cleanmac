import CleanMacCore
import SwiftUI

struct RecommendationsCard: View {
    @EnvironmentObject private var state: AppState
    
    var body: some View {
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
                RecommendationRow(title: "Remove old Docker images", size: "3,2 GB")
                RecommendationRow(title: "Clean npm cache", size: "1,1 GB")
                RecommendationRow(title: "Delete Telegram cache", size: "698 MB")
                RecommendationRow(title: "Empty Trash", size: "1,6 GB")
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
}

struct PotentialSavingsCard: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Potential Savings")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(AppTheme.secondaryText)
            
            HStack(alignment: .bottom) {
                HStack(alignment: .bottom, spacing: 2) {
                    Text(savingsValue)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.cyan)
                    Text(savingsUnit)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AppTheme.cyan)
                        .padding(.bottom, 2)
                }
                
                Spacer()
                
                // Line chart sparkline
                TelemetryLineChart(data: [10.0, 15.0, 12.0, 18.0, 22.0, 20.0, 28.0, 32.0], color: AppTheme.cyan)
                    .frame(width: 100, height: 26)
                    .padding(.bottom, 2)
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

    private var savingsValue: String {
        if state.isScanned {
            let bytes = state.allCandidates.reduce(UInt64(0)) { $0 + ($1.sizeBytes ?? 0) }
            let formatted = CleanMacFormatting.bytes(bytes)
            return String(formatted.split(separator: " ").first ?? "0")
        }
        return "12,4"
    }

    private var savingsUnit: String {
        if state.isScanned {
            let bytes = state.allCandidates.reduce(UInt64(0)) { $0 + ($1.sizeBytes ?? 0) }
            let formatted = CleanMacFormatting.bytes(bytes)
            return String(formatted.split(separator: " ").last ?? "GB")
        }
        return "GB"
    }
}

struct CleanupTipsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.amber)
                Text("Cleanup Tips")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppTheme.text)
            }
            
            Text("Review items marked as \"Review\" to make sure nothing important gets removed.")
                .font(.system(size: 10))
                .foregroundStyle(AppTheme.secondaryText)
                .lineSpacing(2)
            
            Button {
                // Action
            } label: {
                HStack(spacing: 3) {
                    Text("Learn more")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(AppTheme.cyan)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(AppTheme.cyan)
                }
            }
            .buttonStyle(.plain)
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
}
