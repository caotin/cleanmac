import CleanMacCore
import SwiftUI

struct MemoryUsageCard: View {
    var usedPercent: Double
    var usedGBString: String
    var totalGBString: String
    var freeGBString: String
    var pressureString: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 24) {
                // Radial progress ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.05), lineWidth: 8)
                        .frame(width: 110, height: 110)
                    
                    Circle()
                        .trim(from: 0.0, to: CGFloat(usedPercent))
                        .stroke(
                            LinearGradient(
                                colors: [Color(red: 0.25, green: 0.82, blue: 1.0), Color(red: 0.05, green: 0.5, blue: 0.95)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 110, height: 110)
                        .rotationEffect(.degrees(-90))
                        .shadow(color: Color(red: 0.25, green: 0.82, blue: 1.0).opacity(0.2), radius: 6)
                    
                    VStack(spacing: 2) {
                        Text("\(Int(usedPercent * 100))%")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Memory Used")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Memory Usage")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppTheme.secondaryText)
                    
                    HStack(alignment: .bottom, spacing: 4) {
                        Text(usedGBString)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("GB")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.bottom, 2)
                        Text("/ \(totalGBString)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(AppTheme.secondaryText)
                            .padding(.bottom, 2)
                    }
                    
                    // Horizontal progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.white.opacity(0.08))
                                .frame(height: 6)
                            
                            RoundedRectangle(cornerRadius: 3)
                                .fill(LinearGradient(colors: [Color(red: 0.25, green: 0.82, blue: 1.0), Color(red: 0.05, green: 0.5, blue: 0.95)], startPoint: .leading, endPoint: .trailing))
                                .frame(width: geo.size.width * CGFloat(usedPercent), height: 6)
                        }
                    }
                    .frame(height: 6)
                    
                    HStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Used")
                                .font(.system(size: 10))
                                .foregroundStyle(AppTheme.secondaryText)
                            Text(usedGBString + " GB")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Free")
                                .font(.system(size: 10))
                                .foregroundStyle(AppTheme.secondaryText)
                            Text(freeGBString + " GB")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Pressure")
                                .font(.system(size: 10))
                                .foregroundStyle(AppTheme.secondaryText)
                            Text(pressureString)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(pressureString.localizedCaseInsensitiveContains("normal") ? AppTheme.green : AppTheme.amber)
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.horizontal, 8)
            
            // Bottom green box
            HStack(spacing: 10) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.green)
                Text("Your memory pressure is normal.")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                Text("macOS is managing your memory efficiently.")
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(AppTheme.green.opacity(0.06))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(AppTheme.green.opacity(0.12), lineWidth: 1)
            )
        }
    }
}
