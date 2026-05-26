import CleanMacCore
import SwiftUI

struct DockerTelemetryCard: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        GlassPanel(padding: 16) {
            VStack(alignment: .leading, spacing: 14) {
                Text("Docker Resources Overview")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                
                let imagesCount = state.dockerCandidates.filter { $0.id.hasPrefix("docker.image.") }.count
                let containersCount = state.dockerCandidates.filter { $0.id.hasPrefix("docker.container.") }.count
                let volumesCount = state.dockerCandidates.filter { $0.id.hasPrefix("docker.volume.") }.count
                
                let imagesSize = state.dockerCandidates.filter { $0.id.hasPrefix("docker.image.") }.reduce(UInt64(0)) { $0 + ($1.sizeBytes ?? 0) }
                let containersSize = state.dockerCandidates.filter { $0.id.hasPrefix("docker.container.") }.reduce(UInt64(0)) { $0 + ($1.sizeBytes ?? 0) }
                
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Images (\(imagesCount))")
                            .font(.system(size: 10))
                            .foregroundStyle(AppTheme.secondaryText)
                        Text(CleanMacFormatting.bytes(imagesSize))
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Containers (\(containersCount))")
                            .font(.system(size: 10))
                            .foregroundStyle(AppTheme.secondaryText)
                        Text(CleanMacFormatting.bytes(containersSize))
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Volumes (\(volumesCount))")
                            .font(.system(size: 10))
                            .foregroundStyle(AppTheme.secondaryText)
                        Text("\(volumesCount) dangling")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}
