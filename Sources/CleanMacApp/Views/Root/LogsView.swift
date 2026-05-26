import CleanMacCore
import SwiftUI

struct LogsView: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            SectionHeader(title: "Cleanup Logs", subtitle: "Every cleanup action is recorded locally.", icon: "list.bullet.rectangle")
            GlassPanel(padding: 8) {
                List(state.logs) { entry in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(entry.action)
                                .font(.headline)
                                .foregroundStyle(AppTheme.text)
                            Spacer()
                            Text(entry.succeeded ? "Succeeded" : "Failed")
                                .foregroundStyle(entry.succeeded ? AppTheme.green : AppTheme.red)
                        }
                        Text(entry.detail)
                            .foregroundStyle(AppTheme.secondaryText)
                        Text(entry.timestamp.formatted(date: .abbreviated, time: .standard))
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.inset)
                .scrollContentBackground(.hidden)
            }
        }
        .padding(24)
    }
}
