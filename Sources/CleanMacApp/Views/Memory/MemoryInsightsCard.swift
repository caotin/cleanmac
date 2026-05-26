import CleanMacCore
import SwiftUI

struct MemoryInsightsCard: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Memory Insights")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
            
            VStack(spacing: 12) {
                // Reclaimable Memory Row
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.3.trianglepath")
                                    .font(.system(size: 10))
                                    .foregroundStyle(AppTheme.green)
                                Text("Reclaimable Memory")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(AppTheme.secondaryText)
                            }
                            Text("2,14 GB")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.green)
                        }
                        Spacer()
                        
                        SparklineLineChart(data: [12, 14, 11, 15, 18, 16, 22, 20, 24], color: AppTheme.green)
                            .frame(width: 80, height: 24)
                            .padding(.top, 4)
                    }
                    Text("Memory used by apps that can be freed without closing them.")
                        .font(.system(size: 9))
                        .foregroundStyle(AppTheme.secondaryText)
                        .lineLimit(2)
                }
                
                Divider().overlay(Color.white.opacity(0.05))
                
                // Cached Files Row
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 4) {
                                Image(systemName: "folder.badge.gearshape")
                                    .font(.system(size: 10))
                                    .foregroundStyle(AppTheme.cyan)
                                Text("Cached Files")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(AppTheme.secondaryText)
                            }
                            Text("1,38 GB")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.cyan)
                        }
                        Spacer()
                        
                        SparklineLineChart(data: [18, 16, 17, 15, 19, 21, 18, 20, 22], color: AppTheme.cyan)
                            .frame(width: 80, height: 24)
                            .padding(.top, 4)
                    }
                    Text("Temporary cached files that can be safely cleared.")
                        .font(.system(size: 9))
                        .foregroundStyle(AppTheme.secondaryText)
                        .lineLimit(2)
                }
                
                Divider().overlay(Color.white.opacity(0.05))
                
                // Swap Used Row
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.left.and.right.righttriangle.left.righttriangle.right")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.purple)
                                Text("Swap Used")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(AppTheme.secondaryText)
                            }
                            Text("0 KB")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(.purple)
                        }
                        Spacer()
                        
                        SparklineLineChart(data: [5, 5, 5, 5, 5, 5, 5, 5, 5], color: .purple)
                            .frame(width: 80, height: 2)
                            .padding(.top, 14)
                    }
                    Text("Great! Your Mac isn't using swap right now.")
                        .font(.system(size: 9))
                        .foregroundStyle(AppTheme.secondaryText)
                        .lineLimit(2)
                }
            }
            
            Divider().overlay(Color.white.opacity(0.05))
            
            Button {
                // Learn more action
            } label: {
                HStack {
                    Image(systemName: "book")
                    Text("Learn More About Memory")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(AppTheme.cyan)
            }
            .buttonStyle(.plain)
        }
    }
}
