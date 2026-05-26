import SwiftUI

struct GlowingRunScanButton: View {
    var isScanning: Bool
    var action: () -> Void
    @State private var pulse = false
    @State private var rotationAngle: Double = 0

    var body: some View {
        Button(action: action) {
            ZStack {
                // Outer soft glowing ring pulsing
                Circle()
                    .stroke(AppTheme.cyan.opacity(isScanning ? 0.35 : 0.2), lineWidth: isScanning ? 1.5 : 1)
                    .frame(width: 144, height: 144)
                    .scaleEffect(pulse ? 1.08 : 0.95)
                    .opacity(pulse ? (isScanning ? 0.25 : 0.15) : 0.6)
                
                // Main neon border ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [AppTheme.cyan, AppTheme.cyan.opacity(0.6), AppTheme.cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 124, height: 124)
                    .shadow(color: AppTheme.cyan.opacity(0.5), radius: 14)
                    .opacity(isScanning ? 0.2 : 1.0)
                
                // Sparkle (star) highlight at the 11 o'clock position on the neon border
                if !isScanning {
                    Image(systemName: "sparkle")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                        .shadow(color: AppTheme.cyan, radius: 4)
                        .offset(y: -62) // Radius of 124 ring is 62
                        .rotationEffect(.degrees(-35))
                        .opacity(pulse ? 1.0 : 0.7)
                }
                
                // Custom rotating gradient loading ring
                if isScanning {
                    Circle()
                        .trim(from: 0.0, to: 0.65)
                        .stroke(
                            AngularGradient(
                                colors: [AppTheme.cyan, AppTheme.teal, AppTheme.cyan.opacity(0.15)],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: 124, height: 124)
                        .shadow(color: AppTheme.cyan.opacity(0.8), radius: 8)
                        .rotationEffect(.degrees(rotationAngle))
                        .onAppear {
                            rotationAngle = 0
                            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                                rotationAngle = 360
                            }
                        }
                }
                
                // Semi-translucent dark center fill
                Circle()
                    .fill(Color.black.opacity(0.4))
                    .frame(width: 116, height: 116)
                
                if isScanning {
                    Text("Scanning...")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(AppTheme.cyan)
                } else {
                    Text("Run Scan")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .frame(width: 150, height: 150)
        }
        .buttonStyle(.plain)
        .frame(width: 150, height: 150)
        .disabled(isScanning)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}
