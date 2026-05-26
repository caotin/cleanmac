import SwiftUI

enum AppTheme {
    static let cyan = Color(red: 0.25, green: 0.82, blue: 1.0)
    static let teal = Color(red: 0.13, green: 0.95, blue: 0.72)
    static let green = Color(red: 0.55, green: 0.92, blue: 0.38)
    static let amber = Color(red: 1.0, green: 0.66, blue: 0.25)
    static let red = Color(red: 1.0, green: 0.28, blue: 0.36)
    static let text = Color.white.opacity(0.92)
    static let secondaryText = Color.white.opacity(0.58)
    static let panel = Color.white.opacity(0.095)
    static let panelStrong = Color.white.opacity(0.15)
}

struct AppShellBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.10, blue: 0.15),
                    Color(red: 0.10, green: 0.17, blue: 0.22),
                    Color(red: 0.04, green: 0.08, blue: 0.13)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [AppTheme.cyan.opacity(0.24), .clear],
                center: .topTrailing,
                startRadius: 40,
                endRadius: 520
            )

            RadialGradient(
                colors: [AppTheme.teal.opacity(0.18), .clear],
                center: .bottom,
                startRadius: 20,
                endRadius: 480
            )

            ParticleField()
                .opacity(0.28)
        }
        .ignoresSafeArea()
    }
}

struct ParticleField: View {
    private let points: [CGPoint] = [
        CGPoint(x: 0.18, y: 0.16), CGPoint(x: 0.28, y: 0.34), CGPoint(x: 0.39, y: 0.20),
        CGPoint(x: 0.55, y: 0.12), CGPoint(x: 0.64, y: 0.31), CGPoint(x: 0.76, y: 0.18),
        CGPoint(x: 0.86, y: 0.44), CGPoint(x: 0.47, y: 0.52), CGPoint(x: 0.31, y: 0.68),
        CGPoint(x: 0.59, y: 0.74), CGPoint(x: 0.72, y: 0.62), CGPoint(x: 0.88, y: 0.79)
    ]

    var body: some View {
        GeometryReader { proxy in
            ForEach(points.indices, id: \.self) { index in
                Circle()
                    .fill(.white.opacity(index.isMultiple(of: 3) ? 0.55 : 0.32))
                    .frame(width: index.isMultiple(of: 4) ? 3 : 2, height: index.isMultiple(of: 4) ? 3 : 2)
                    .position(x: proxy.size.width * points[index].x, y: proxy.size.height * points[index].y)
            }
        }
    }
}

struct GlassPanel<Content: View>: View {
    var padding: CGFloat = 18
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .background(AppTheme.panel, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(.white.opacity(0.13), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.18), radius: 24, y: 12)
    }
}

struct StatusBar: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        HStack {
            if state.isRefreshingMachine || state.isRefreshingRunningApps || state.isScanningSources || state.isScanningNodeModules || state.isScanningDocker {
                ProgressView()
                    .controlSize(.small)
            }
            Text(state.statusMessage)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            if let refreshedAt = state.machine?.refreshedAt {
                Text("Updated \(refreshedAt.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .foregroundStyle(AppTheme.secondaryText)
        .background(.ultraThinMaterial)
    }
}

struct Header: View {
    var title: String
    var subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.largeTitle.bold())
                .foregroundStyle(AppTheme.text)
            Text(subtitle)
                .font(.body)
                .foregroundStyle(AppTheme.secondaryText)
        }
    }
}

struct SectionHeader: View {
    var title: String
    var subtitle: String
    var icon: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AppTheme.cyan.opacity(0.16))
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AppTheme.cyan)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title2.bold())
                    .foregroundStyle(AppTheme.text)
                Text(subtitle)
                    .foregroundStyle(AppTheme.secondaryText)
            }
            Spacer()
        }
    }
}

struct MetricCard: View {
    var title: String
    var value: String
    var detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(AppTheme.secondaryText)
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(AppTheme.text)
                .lineLimit(2)
            Text(detail)
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryText)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AppTheme.panel, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        }
    }
}

struct HeroMetricCard: View {
    var title: String
    var value: String
    var detail: String
    var icon: String
    var tint: Color = AppTheme.cyan

    var body: some View {
        GlassPanel(padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(tint)
                    Spacer()
                }
                Text(title)
                    .font(.headline)
                    .foregroundStyle(AppTheme.text)
                Text(value)
                    .font(.system(size: 30, weight: .light, design: .rounded))
                    .foregroundStyle(tint)
                    .contentTransition(.numericText())
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct PrimaryOrbButton: View {
    var title: String
    var systemImage: String
    var isBusy: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [AppTheme.cyan.opacity(0.32), Color.white.opacity(0.06), Color.black.opacity(0.18)],
                            center: .top,
                            startRadius: 12,
                            endRadius: 76
                        )
                    )
                Circle()
                    .stroke(AppTheme.cyan.opacity(0.75), lineWidth: 3)
                    .padding(6)
                VStack(spacing: 7) {
                    if isBusy {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: systemImage)
                            .font(.system(size: 21, weight: .bold))
                    }
                    Text(title)
                        .font(.headline)
                }
                .foregroundStyle(.white)
            }
            .frame(width: 116, height: 116)
            .shadow(color: AppTheme.cyan.opacity(0.42), radius: 30, y: 14)
        }
        .buttonStyle(.plain)
        .disabled(isBusy)
    }
}
