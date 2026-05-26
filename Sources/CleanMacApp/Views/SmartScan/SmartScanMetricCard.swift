import CleanMacCore
import SwiftUI

struct SmartScanMetricCard<Icon: View>: View {
    var icon: Icon
    var iconColor: Color
    var title: String
    var value: String
    var subtext: String
    var actionText: String? = nil
    var badgeText: String? = nil
    var action: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Circle Icon Badge on the left (solid gradient background with white symbol)
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [iconColor, iconColor.opacity(0.78)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .shadow(color: iconColor.opacity(0.35), radius: 6, y: 3)
                
                icon
                    .foregroundStyle(.white)
            }
            
            // Text and action link on the right
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.secondaryText)
                
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(iconColor)
                
                Text(subtext)
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.secondaryText)
                    .padding(.bottom, 6)
                
                if let actionText = actionText {
                    Button(action: action) {
                        Text(actionText)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(AppTheme.cyan)
                    }
                    .buttonStyle(.plain)
                } else if let badgeText = badgeText {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                        Text(badgeText.replacingOccurrences(of: "✓ ", with: ""))
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundStyle(iconColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(iconColor.opacity(0.12))
                    .cornerRadius(10)
                }
            }
            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 144)
        .background(Color.white.opacity(0.035))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isHovered ? AppTheme.cyan.opacity(0.2) : Color.white.opacity(0.06), lineWidth: 1)
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
