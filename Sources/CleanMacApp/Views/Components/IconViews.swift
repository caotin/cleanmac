import AppKit
import SwiftUI

enum AppIconInstaller {
    @MainActor
    static func install() {
        guard let url = Bundle.module.url(forResource: "CleanMacAppIcon", withExtension: "png"),
              let image = NSImage(contentsOf: url) else {
            return
        }
        NSApplication.shared.applicationIconImage = image
    }
}

struct ToolbarAssetIcon: View {
    var name: String

    var body: some View {
        Group {
            if let image = toolbarImage {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                RoundedRectangle(cornerRadius: 5)
                    .fill(.secondary.opacity(0.25))
            }
        }
        .frame(width: 18, height: 18)
        .accessibilityHidden(true)
    }

    private var toolbarImage: NSImage? {
        guard let url = Bundle.module.url(forResource: name, withExtension: "png", subdirectory: "ToolbarIcons") else {
            return nil
        }
        return NSImage(contentsOf: url)
    }
}

struct ToolbarMenuLabel: View {
    var title: String
    var iconName: String

    var body: some View {
        HStack(spacing: 6) {
            ToolbarAssetIcon(name: iconName)
            Text(title)
        }
        .accessibilityLabel(title)
    }
}

struct CleanupIconView: View {
    var size: CGFloat = 20

    var body: some View {
        ZStack {
            // Sweeping effect lines / dust particles
            Circle()
                .trim(from: 0.15, to: 0.6)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.8), .white.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [2, 3])
                )
                .frame(width: size * 1.3, height: size * 1.3)
                .rotationEffect(.degrees(-30))
                .offset(x: -size * 0.1, y: size * 0.1)

            // Sparkles to indicate clean/shiny
            Image(systemName: "sparkles")
                .font(.system(size: size * 0.55, weight: .bold))
                .foregroundStyle(.white)
                .offset(x: size * 0.45, y: -size * 0.45)
                .shadow(color: .white.opacity(0.6), radius: 1.5)

            Image(systemName: "sparkle")
                .font(.system(size: size * 0.35, weight: .semibold))
                .foregroundStyle(.white.opacity(0.8))
                .offset(x: -size * 0.4, y: size * 0.35)

            // Stylized broom
            ZStack {
                // Broom Handle
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.8)],
                            startPoint: .topTrailing,
                            endPoint: .bottomLeading
                        )
                    )
                    .frame(width: size * 0.16, height: size * 0.75)
                    .rotationEffect(.degrees(45))
                    .offset(x: size * 0.18, y: -size * 0.18)

                // Bristle Connector / Band (Orange/Amber colored to give contrast)
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color(red: 1.0, green: 0.66, blue: 0.25))
                    .frame(width: size * 0.42, height: size * 0.15)
                    .rotationEffect(.degrees(45))
                    .offset(x: -size * 0.12, y: size * 0.12)

                // Bristles (Triangular/Trapezoidal shape sweeping)
                Path { path in
                    path.move(to: CGPoint(x: size * 0.3, y: size * 0.6))
                    path.addLine(to: CGPoint(x: size * 0.1, y: size * 0.8))
                    path.addLine(to: CGPoint(x: size * 0.35, y: size * 0.95))
                    path.addLine(to: CGPoint(x: size * 0.5, y: size * 0.72))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.95), .white.opacity(0.6)],
                        startPoint: .topTrailing,
                        endPoint: .bottomLeading
                    )
                )
                .offset(x: -size * 0.35, y: -size * 0.35)
            }
            .offset(x: -size * 0.05, y: -size * 0.05)
        }
        .frame(width: size, height: size)
    }
}

