import SwiftUI

struct DotGridView: View {
    var body: some View {
        VStack(spacing: 12) {
            ForEach(0..<11, id: \.self) { _ in
                HStack(spacing: 12) {
                    ForEach(0..<23, id: \.self) { _ in
                        Circle()
                            .fill(AppTheme.cyan.opacity(0.24))
                            .frame(width: 2, height: 2)
                    }
                }
            }
        }
        .mask(
            RadialGradient(
                gradient: Gradient(colors: [.black, .black.opacity(0.7), .clear]),
                center: .center,
                startRadius: 0,
                endRadius: 100
            )
        )
    }
}
