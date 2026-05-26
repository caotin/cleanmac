import AppKit
import CleanMacCore
import SwiftUI

struct SmartScanHeroVisual: View {
    @State private var isAnimating = false
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            // Radial background glow behind the drive
            Circle()
                .fill(AppTheme.cyan.opacity(0.18))
                .frame(width: 320, height: 320)
                .blur(radius: 50)
            
            // Glowing outer dashed ring (rotating slowly)
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [AppTheme.cyan.opacity(0.4), .clear, AppTheme.teal.opacity(0.3), .clear, AppTheme.cyan.opacity(0.4)],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 1.5, dash: [4, 8])
                )
                .frame(width: 300, height: 300)
                .rotationEffect(.degrees(rotation))
            
            // Glowing inner ring (rotating counter-clockwise)
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [.clear, AppTheme.cyan.opacity(0.5), .clear, AppTheme.teal.opacity(0.4)],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 1)
                )
                .frame(width: 240, height: 240)
                .rotationEffect(.degrees(-rotation * 1.5))
            
            // Hard Drive speed dial meter graphic (loaded safely as loose resource from Bundle)
            if let nsImage = heroImage {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 190)
                    .shadow(color: AppTheme.cyan.opacity(0.4), radius: 28)
                    .offset(y: isAnimating ? 4 : -4)
            } else {
                Image(systemName: "internaldrive.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.white.opacity(0.15))
                    .offset(y: isAnimating ? 4 : -4)
            }
            
            // Floating 3D-like folder icon on the left
            Image(systemName: "folder.fill")
                .font(.system(size: 24))
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppTheme.cyan, Color(red: 0.1, green: 0.5, blue: 0.9)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(8)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.white.opacity(0.15), lineWidth: 1)
                )
                .shadow(color: AppTheme.cyan.opacity(0.3), radius: 8)
                .rotationEffect(.degrees(-15))
                .offset(x: -125, y: isAnimating ? -25 : -35)
            
            // Floating Code Bracket badge on the right
            HStack(spacing: 0) {
                Text("</>")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.1, green: 0.4, blue: 0.8).opacity(0.85), Color(red: 0.05, green: 0.2, blue: 0.5).opacity(0.85)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(AppTheme.cyan.opacity(0.4), lineWidth: 1)
            )
            .shadow(color: AppTheme.cyan.opacity(0.4), radius: 10)
            .rotationEffect(.degrees(12))
            .offset(x: 135, y: isAnimating ? 15 : 5)
            
            // Floating Doc icon (top-left)
            Image(systemName: "doc.text.fill")
                .font(.system(size: 16))
                .foregroundStyle(.white.opacity(0.6))
                .padding(6)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 6))
                .rotationEffect(.degrees(-8))
                .offset(x: -80, y: isAnimating ? -90 : -96)

            // Floating small Doc icon (bottom-left)
            Image(systemName: "doc.fill")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.4))
                .padding(4)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 4))
                .rotationEffect(.degrees(20))
                .offset(x: -95, y: isAnimating ? 65 : 58)

            // Floating drive icon (top-right)
            Image(systemName: "internaldrive.fill")
                .font(.system(size: 15))
                .foregroundStyle(.white.opacity(0.55))
                .padding(6)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 6))
                .rotationEffect(.degrees(10))
                .offset(x: 85, y: isAnimating ? -75 : -81)
            
            // Floating small code brackets (bottom-right)
            Image(systemName: "chevron.left.forwardslash.chevron.right")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white.opacity(0.5))
                .padding(5)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 5))
                .rotationEffect(.degrees(-12))
                .offset(x: 90, y: isAnimating ? 70 : 76)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
            withAnimation(.linear(duration: 25).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }

    private var heroImage: NSImage? {
        guard let url = Bundle.module.url(forResource: "SmartScanHero", withExtension: "png") else {
            return nil
        }
        return NSImage(contentsOf: url)
    }
}
