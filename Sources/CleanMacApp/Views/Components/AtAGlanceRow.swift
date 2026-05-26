import CleanMacCore
import SwiftUI

struct AtAGlanceRow: View {
    var icon: String
    var iconColor: Color
    var title: String
    var value: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 26, height: 26)
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(iconColor)
            }

            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.secondaryText)

            Spacer()

            Text(value)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
        }
    }
}

struct AtAGlanceProgressRow: View {
    var icon: String
    var iconColor: Color
    var title: String
    var value: String
    var progress: Double

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 26, height: 26)
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(iconColor)
            }

            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.secondaryText)
                .frame(width: 90, alignment: .leading)

            ProgressView(value: max(0.0, min(1.0, progress)))
                .progressViewStyle(SleekProgressViewStyle(color: iconColor))
                .frame(maxWidth: .infinity)

            Text(value)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 44, alignment: .trailing)
        }
    }
}
