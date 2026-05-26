import CleanMacCore
import SwiftUI

struct DashboardActionPanel: View {
    var totalBytes: UInt64
    var totalCount: Int
    var safeBytes: UInt64
    var safeCount: Int
    var isBusy: Bool
    var reduceMotion: Bool
    var quickClean: () -> Void
    var scanAll: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 18) {
            QuickCleanGlyph(isActive: isBusy, reduceMotion: reduceMotion)
                .frame(width: 112, height: 112)

            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Quick Clean")
                        .font(.title2.bold())
                    Text("One-click cleanup runs only low-risk items. Manual cleanup still requires confirmation.")
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 12) {
                    Button(isBusy ? "Working..." : "Quick Clean") {
                        quickClean()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isBusy)

                    Button("Scan All") {
                        scanAll()
                    }
                    .buttonStyle(.bordered)
                    .disabled(isBusy)

                    Text(isBusy ? "Scanning and cleaning safe items..." : "\(safeCount) safe item(s) ready")
                        .foregroundStyle(.secondary)
                        .contentTransition(.numericText())
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 170), spacing: 12)], spacing: 12) {
                    DashboardStatTile(title: "Safe to Clean", value: CleanMacFormatting.bytes(safeBytes), detail: "\(safeCount) low-risk item(s)")
                    DashboardStatTile(title: "Total Found", value: CleanMacFormatting.bytes(totalBytes), detail: "\(totalCount) scanned item(s)")
                }
            }
        }
        .padding(16)
        .background(Color.accentColor.opacity(0.09), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.accentColor.opacity(0.22), lineWidth: 1)
        }
        .animation(reduceMotion ? nil : .smooth(duration: 0.28), value: isBusy)
        .animation(reduceMotion ? nil : .snappy(duration: 0.22), value: safeCount)
    }
}

struct QuickCleanGlyph: View {
    var isActive: Bool
    var reduceMotion: Bool
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.accentColor.opacity(0.28), Color.green.opacity(0.18)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Circle()
                .stroke(Color.white.opacity(0.42), lineWidth: 1)
                .padding(1)

            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(Color.accentColor.opacity(isActive ? 0.28 : 0.12), lineWidth: 1)
                    .scaleEffect(isActive && !reduceMotion ? 0.72 + CGFloat(index) * 0.18 + (isAnimating ? 0.18 : 0) : 0.72 + CGFloat(index) * 0.18)
                    .opacity(isActive ? (isAnimating ? 0.22 : 0.65) : 0.28)
            }

            Image(systemName: isActive ? "sparkles" : "checkmark.seal.fill")
                .font(.system(size: 34, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.white)
                .rotationEffect(.degrees(isActive && !reduceMotion && isAnimating ? 10 : 0))
                .scaleEffect(isActive && !reduceMotion && isAnimating ? 1.08 : 1)
        }
        .shadow(color: Color.accentColor.opacity(0.18), radius: 18, y: 8)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

struct DashboardStatTile: View {
    var title: String
    var value: String
    var detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.bold())
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

enum DashboardCleanupGroup: String, CaseIterable, Identifiable {
    case devCaches
    case browserCaches
    case aiDevCaches
    case virtualizationCaches
    case safeSystem
    case nodeModules
    case docker

    var id: String { rawValue }

    var title: String {
        switch self {
        case .devCaches: "Dev Caches"
        case .browserCaches: "Browser Caches"
        case .aiDevCaches: "AI Dev Caches"
        case .virtualizationCaches: "Virtualization"
        case .safeSystem: "Safe System"
        case .nodeModules: "Node Modules"
        case .docker: "Docker"
        }
    }

    var categories: Set<CleanupCategory> {
        switch self {
        case .devCaches: [.devCaches]
        case .browserCaches: [.browserCaches]
        case .aiDevCaches: [.aiDevCaches]
        case .virtualizationCaches: [.virtualizationCaches]
        case .safeSystem: [.safeSystem]
        case .nodeModules: [.nodeModules]
        case .docker: [.dockerImages, .dockerContainers, .dockerVolumes, .dockerBuildCache]
        }
    }
}

struct DashboardGroupCard: View {
    var group: DashboardCleanupGroup
    var candidates: [CleanupCandidate]
    var isSelected: Bool
    var action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(group.title)
                        .font(.headline)
                    Spacer()
                    Text("\(candidates.count)")
                        .font(.caption.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.secondary.opacity(0.14), in: Capsule())
                }

                Text(CleanMacFormatting.bytes(totalBytes))
                    .font(.title2.bold())

                Text(riskSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                GeometryReader { proxy in
                    HStack(spacing: 3) {
                        riskBar(width: lowWidth(totalWidth: proxy.size.width), color: .green)
                        riskBar(width: reviewWidth(totalWidth: proxy.size.width), color: .orange)
                    }
                }
                .frame(height: 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(isSelected ? Color.accentColor.opacity(0.14) : Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isSelected ? Color.accentColor.opacity(0.55) : Color.clear, lineWidth: 1)
            }
            .scaleEffect(isHovering ? 1.015 : 1)
            .shadow(color: isSelected ? Color.accentColor.opacity(0.12) : .clear, radius: 10, y: 4)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.snappy(duration: 0.18)) {
                isHovering = hovering
            }
        }
    }

    private var totalBytes: UInt64 {
        candidates.reduce(UInt64(0)) { $0 + ($1.sizeBytes ?? 0) }
    }

    private var riskSummary: String {
        let lows = candidates.filter { $0.risk == .low }.count
        let mediumHigh = candidates.count - lows
        return "\(lows) low-risk, \(mediumHigh) review"
    }

    private var lowRiskCount: Int {
        candidates.filter { $0.risk == .low }.count
    }

    private var reviewCount: Int {
        candidates.count - lowRiskCount
    }

    private func riskBar(width: CGFloat, color: Color) -> some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(color.opacity(width > 0 ? 0.72 : 0))
            .frame(width: width)
    }

    private func lowWidth(totalWidth: CGFloat) -> CGFloat {
        guard !candidates.isEmpty else { return 0 }
        return max(0, totalWidth * CGFloat(lowRiskCount) / CGFloat(candidates.count))
    }

    private func reviewWidth(totalWidth: CGFloat) -> CGFloat {
        guard !candidates.isEmpty else { return 0 }
        return max(0, totalWidth * CGFloat(reviewCount) / CGFloat(candidates.count))
    }
}

struct CleanupSummaryCard: View {
    var summary: CleanupRunSummary
    var openLogs: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("Last cleanup")
                    .font(.headline)
                Text("\(summary.itemCount) item(s), \(CleanMacFormatting.bytes(summary.bytesRequested)) requested, \(summary.failedCount) failed")
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Open Logs", action: openLogs)
        }
        .padding()
        .background(Color.green.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
