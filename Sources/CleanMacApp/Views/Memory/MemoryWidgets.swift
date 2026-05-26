import CleanMacCore
import SwiftUI

struct MemoryRecommendationsCard: View {
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
                RecommendationRow(title: "Close unused browser tabs", size: "~320 MB")
                RecommendationRow(title: "Quit inactive apps", size: "~450 MB")
                RecommendationRow(title: "Clear app caches", size: "~680 MB")
                RecommendationRow(title: "Restart resource heavy apps", size: "~200 MB")
            }
        }
    }
}

struct PotentialMemoryReclaimCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Potential Memory Reclaim")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(AppTheme.secondaryText)
            
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("1,65 GB")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.cyan)
                    Text("Reclaimable without closing apps")
                        .font(.system(size: 9))
                        .foregroundStyle(AppTheme.secondaryText)
                }
                
                Spacer()
                
                ReclaimBarChart()
                    .padding(.bottom, 2)
            }
        }
    }
}

struct MemoryMonitorCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Memory Monitor")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(AppTheme.secondaryText)
                Spacer()
                Text("Last 60 seconds")
                    .font(.system(size: 9))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            
            HStack(spacing: 12) {
                VStack(alignment: .trailing, spacing: 14) {
                    Text("100%")
                    Text("50%")
                    Text("0%")
                }
                .font(.system(size: 9))
                .foregroundStyle(AppTheme.secondaryText)
                
                MemoryMonitorAreaChart()
                    .frame(height: 70)
            }
            .padding(.top, 4)
        }
    }
}
