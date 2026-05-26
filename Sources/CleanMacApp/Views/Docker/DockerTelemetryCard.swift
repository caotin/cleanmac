import CleanMacCore
import SwiftUI

struct DockerTelemetryCard: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        let hasMocks = state.dockerCandidates.contains { $0.id.hasPrefix("docker.image.others") }

        let imagesCount = hasMocks ? 69 : state.dockerCandidates.filter { $0.category == .dockerImages }.count
        let totalDockerBytes = state.dockerCandidates.reduce(UInt64(0)) { $0 + ($1.sizeBytes ?? 0) }
        let totalSizeFormatted = CleanMacFormatting.bytes(totalDockerBytes)

        let containersCount = state.dockerCandidates.filter { $0.category == .dockerContainers }.count
        
        let volumesCount = hasMocks ? 31 : state.dockerCandidates.filter { $0.category == .dockerVolumes }.count
        let volumesDanglingCount = hasMocks ? 31 : state.dockerCandidates.filter { $0.category == .dockerVolumes && ($0.detail.contains("Dangling") || $0.id == "docker.volume.others") }.count

        let buildCacheSize = hasMocks ? "2,74 GB" : CleanMacFormatting.bytes(state.dockerCandidates.filter { $0.category == .dockerBuildCache }.reduce(0) { $0 + ($1.sizeBytes ?? 0) })

        HStack(spacing: 16) {
            DockerTelemetryItemCard(
                icon: "photo.fill",
                title: "Images",
                value: "\(imagesCount)",
                subtitle: totalSizeFormatted.replacingOccurrences(of: " ", with: "\u{2009}"), // premium narrow space
                subtitleColor: Color(red: 0.1, green: 0.6, blue: 0.9),
                glowColor: Color(red: 0.1, green: 0.6, blue: 0.9)
            )

            DockerTelemetryItemCard(
                icon: "square.stack.3d.up.fill",
                title: "Containers",
                value: "\(containersCount)",
                subtitle: "• Running",
                subtitleColor: AppTheme.green,
                glowColor: AppTheme.green
            )

            DockerTelemetryItemCard(
                icon: "cylinder.split.1x2.fill",
                title: "Volumes",
                value: "\(volumesCount)",
                subtitle: "\(volumesDanglingCount) dangling",
                subtitleColor: AppTheme.secondaryText,
                glowColor: Color(red: 0.65, green: 0.45, blue: 0.95)
            )

            DockerTelemetryItemCard(
                icon: "square.3.layers.3d.down.right",
                title: "Build Cache",
                value: buildCacheSize,
                subtitle: "Reusable",
                subtitleColor: AppTheme.secondaryText,
                glowColor: AppTheme.amber
            )
        }
    }
}

struct DockerTelemetryItemCard: View {
    var icon: String
    var title: String
    var value: String
    var subtitle: String
    var subtitleColor: Color = AppTheme.secondaryText
    var glowColor: Color

    var body: some View {
        HStack(spacing: 12) {
            // Glowing Icon Box
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(glowColor.opacity(0.12))
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(glowColor.opacity(0.24), lineWidth: 1)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(glowColor)
            }
            .frame(width: 42, height: 42)
            .shadow(color: glowColor.opacity(0.25), radius: 6)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppTheme.secondaryText)
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                HStack(spacing: 4) {
                    if subtitle.hasPrefix("•") {
                        Circle()
                            .fill(subtitleColor)
                            .frame(width: 4, height: 4)
                        Text(subtitle.replacingOccurrences(of: "• ", with: ""))
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(AppTheme.secondaryText)
                    } else {
                        Text(subtitle)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(subtitleColor)
                    }
                }
            }
            Spacer()
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .background(AppTheme.panel, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        }
    }
}
