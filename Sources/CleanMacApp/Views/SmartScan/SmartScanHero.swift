import CleanMacCore
import SwiftUI

struct SmartScanHero: View {
    var totalBytes: UInt64
    var totalCount: Int
    var safeBytes: UInt64
    var safeCount: Int
    var developerCount: Int
    var memoryPressure: String
    var dockerSummary: String
    var isBusy: Bool
    var scanAll: () -> Void
    var quickClean: () -> Void
    var review: () -> Void

    var body: some View {
        GlassPanel(padding: 0) {
            VStack(spacing: 22) {
                VStack(spacing: 8) {
                    Text("Smart Scan")
                        .font(.headline)
                        .foregroundStyle(AppTheme.cyan)
                    Text(totalCount > 0 ? "Your Mac is ready for cleanup" : "Start with a clean, safe scan")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.text)
                    Text("Cleanup, developer junk, memory and app review in one compact dashboard.")
                        .foregroundStyle(AppTheme.secondaryText)
                }
                .multilineTextAlignment(.center)
                .padding(.top, 28)

                ZStack {
                    SmartScanVisual(isBusy: isBusy)
                        .frame(height: 230)
                    VStack {
                        Spacer()
                        PrimaryOrbButton(title: isBusy ? "Scanning" : "Run Scan", systemImage: "bolt.fill", isBusy: isBusy, action: scanAll)
                            .offset(y: 52)
                    }
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 190), spacing: 14)], spacing: 14) {
                    HeroMetricCard(title: "Cleanup", value: CleanMacFormatting.bytes(totalBytes), detail: "\(totalCount) items found", icon: "internaldrive", tint: AppTheme.cyan)
                    HeroMetricCard(title: "Safe", value: CleanMacFormatting.bytes(safeBytes), detail: "\(safeCount) low-risk items", icon: "checkmark.shield", tint: AppTheme.green)
                    HeroMetricCard(title: "Developer Junk", value: "\(developerCount)", detail: "Node, Docker, caches", icon: "curlybraces", tint: AppTheme.amber)
                    HeroMetricCard(title: "Memory", value: memoryValue, detail: dockerSummary, icon: "memorychip", tint: AppTheme.teal)
                }
                .padding(.top, 34)

                HStack(spacing: 12) {
                    Button("Quick Clean", action: quickClean)
                        .buttonStyle(.borderedProminent)
                        .tint(AppTheme.cyan)
                        .disabled(isBusy)
                    Button("Review Details", action: review)
                        .buttonStyle(.bordered)
                    Button("Scan All", action: scanAll)
                        .buttonStyle(.bordered)
                        .disabled(isBusy)
                }
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
        }
    }

    private var memoryValue: String {
        if memoryPressure.localizedCaseInsensitiveContains("normal") { return "OK" }
        if memoryPressure.localizedCaseInsensitiveContains("unavailable") { return "N/A" }
        return "Live"
    }
}

struct SmartScanVisual: View {
    var isBusy: Bool
    @State private var pulse = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(AppTheme.cyan.opacity(0.18), lineWidth: 18)
                .frame(width: 250, height: 250)
                .blur(radius: 3)

            Circle()
                .stroke(AngularGradient(colors: [AppTheme.cyan, AppTheme.teal, .white.opacity(0.2), AppTheme.cyan], center: .center), lineWidth: 4)
                .frame(width: 210, height: 210)
                .rotationEffect(.degrees(pulse ? 360 : 0))

            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(LinearGradient(colors: [Color.white.opacity(0.24), AppTheme.cyan.opacity(0.18), Color.black.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 138, height: 138)
                .rotationEffect(.degrees(12))
                .shadow(color: AppTheme.cyan.opacity(0.35), radius: 32)

            Image(systemName: "internaldrive.fill")
                .font(.system(size: 58, weight: .thin))
                .foregroundStyle(.white.opacity(0.9))

            ForEach(0..<8, id: \.self) { index in
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(index.isMultiple(of: 2) ? AppTheme.cyan.opacity(0.75) : AppTheme.green.opacity(0.7))
                    .frame(width: 18, height: 8)
                    .offset(x: CGFloat(index - 4) * 42, y: index.isMultiple(of: 2) ? -86 : 82)
                    .rotationEffect(.degrees(Double(index) * 18))
                    .opacity(0.72)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                pulse = true
            }
        }
    }
}

struct CompactReviewPanel: View {
    var candidates: [CleanupCandidate]
    var title: String
    var openReview: () -> Void

    var body: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text(title)
                        .font(.title3.bold())
                        .foregroundStyle(AppTheme.text)
                    Spacer()
                    Button("Review", action: openReview)
                        .buttonStyle(.bordered)
                        .tint(AppTheme.cyan)
                }

                if candidates.isEmpty {
                    Text("Run a scan to populate cleanup candidates.")
                        .foregroundStyle(AppTheme.secondaryText)
                        .frame(maxWidth: .infinity, minHeight: 94, alignment: .center)
                } else {
                    ForEach(candidates.prefix(5)) { candidate in
                        HStack(spacing: 12) {
                            Image(systemName: icon(for: candidate.category))
                                .foregroundStyle(color(for: candidate.risk))
                                .frame(width: 26)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(candidate.title)
                                    .font(.headline)
                                    .foregroundStyle(AppTheme.text)
                                    .lineLimit(1)
                                Text(candidate.category.rawValue)
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.secondaryText)
                            }
                            Spacer()
                            Text(CleanMacFormatting.bytes(candidate.sizeBytes))
                                .font(.headline)
                                .foregroundStyle(AppTheme.cyan)
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
        }
    }

    private func icon(for category: CleanupCategory) -> String {
        switch category {
        case .memory: "memorychip"
        case .devCaches: "curlybraces"
        case .browserCaches: "globe"
        case .aiDevCaches: "brain"
        case .virtualizationCaches: "rectangle.3.group"
        case .safeSystem: "sparkles"
        case .nodeModules: "shippingbox"
        case .dockerImages, .dockerContainers, .dockerVolumes, .dockerBuildCache: "cube.box"
        case .largeFiles: "doc.text.magnifyingglass"
        case .trashBins: "trash"
        case .applications: "app.dashed"
        case .loginItems: "switch.2"
        }
    }

    private func color(for risk: CleanupRisk) -> Color {
        switch risk {
        case .low: AppTheme.green
        case .medium: AppTheme.amber
        case .high: AppTheme.red
        }
    }
}
