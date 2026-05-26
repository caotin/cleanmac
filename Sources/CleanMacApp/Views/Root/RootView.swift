import CleanMacCore
import SwiftUI

struct RootView: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        ZStack {
            AppShellBackground()
            HStack(spacing: 0) {
                Sidebar()
                    .fixedSize(horizontal: true, vertical: false)
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 1080, minHeight: 700)
        .confirmationDialog(
            "Confirm Cleanup",
            isPresented: $state.isShowingCleanupConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clean Selected", role: .destructive) {
                Task { await state.executePendingCleanup() }
            }
            Button("Cancel", role: .cancel) {
                state.dismissCleanupConfirmation()
            }
        } message: {
            Text(confirmationMessage)
        }
        .confirmationDialog(
            appKillTitle,
            isPresented: $state.isShowingAppKillConfirmation,
            titleVisibility: .visible
        ) {
            Button(state.isForceKillingApps ? "Force Kill Selected Apps" : "Quit Selected Apps", role: .destructive) {
                Task { await state.executePendingAppTermination() }
            }
            Button("Cancel", role: .cancel) {
                state.dismissAppKillConfirmation()
            }
        } message: {
            Text(appKillMessage)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch state.section {
        case .dashboard:
            DashboardView()
        case .smartScan:
            SmartScanView()
        case .cleanup:
            CleanupOverviewView()
        case .memory:
            MemoryCleanupView()
        case .nodeModules:
            NodeModulesView()
        case .docker:
            DockerCleanupView()
        case .logs:
            LogsView()
        case .settings:
            SettingsView()
        }
    }


    private var confirmationMessage: String {
        let selected = state.pendingConfirmation
        let summary = CleanupConfirmationSummary(candidates: selected)
        var message = "\(summary.itemCount) item(s), \(CleanMacFormatting.bytes(summary.totalBytes)). Risk: \(summary.lowRiskCount) low, \(summary.mediumRiskCount) medium, \(summary.highRiskCount) high."
        if !summary.highRiskNames.isEmpty {
            message += " High-risk: \(summary.highRiskNames.joined(separator: ", "))."
        }
        return "\(message) This cannot be undone."
    }

    private var appKillTitle: String {
        state.isForceKillingApps ? "Force Kill Apps" : "Quit Apps"
    }

    private var appKillMessage: String {
        let apps = state.pendingRunningAppTermination
        let names = apps.map { "\($0.name) (pid \($0.processIdentifier))" }.joined(separator: ", ")
        let action = state.isForceKillingApps ? "force kill" : "ask macOS to quit"
        return "This will \(action) \(apps.count) selected app(s): \(names). Unsaved changes in those apps may be lost."
    }
}

struct Sidebar: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Spacer()
                HStack(spacing: 6) {
                    Text("CleanMac")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white.opacity(0.9))
                    Image(systemName: "sparkles")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(AppTheme.cyan)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .frame(height: 28)

            VStack(spacing: 6) {
                ForEach(AppSection.allCases) { section in
                    SidebarRow(
                        section: section,
                        isSelected: state.section == section
                    ) {
                        withAnimation(.snappy(duration: 0.2)) {
                            state.section = section
                        }
                    }
                }
            }
            .padding(.horizontal, 12)

            Spacer()

            SidebarMachineOverviewCard()
        }
        .frame(width: 270)
        .background(.ultraThinMaterial.opacity(0.45))
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(.white.opacity(0.06))
                .frame(width: 1)
        }
    }
}

struct SidebarRow: View {
    var section: AppSection
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: section.systemImage)
                    .font(.system(size: 15, weight: isSelected ? .semibold : .medium))
                    .frame(width: 22)
                Text(section.rawValue)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                Spacer()
            }
            .foregroundStyle(isSelected ? AppTheme.cyan : AppTheme.secondaryText)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isSelected ? AppTheme.cyan.opacity(0.08) : Color.clear, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isSelected ? AppTheme.cyan.opacity(0.18) : .clear, lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct AppMark: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(LinearGradient(colors: [AppTheme.cyan, AppTheme.teal], startPoint: .topLeading, endPoint: .bottomTrailing))
            Image(systemName: "sparkles")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
        }
        .shadow(color: AppTheme.cyan.opacity(0.3), radius: 16, y: 6)
    }
}

struct SidebarMachineOverviewCard: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        Group {
            if let machine = state.machine {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "laptopcomputer")
                            .font(.system(size: 24))
                            .foregroundStyle(.white)
                            .padding(.top, 2)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(cleanModelName(machine.model))
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                            Text(machine.chip)
                                .font(.system(size: 11))
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                        Spacer()
                    }
                    .padding(.bottom, 6)

                    // Memory progress
                    HStack(spacing: 8) {
                        Text("Memory")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(AppTheme.secondaryText)
                            .frame(width: 52, alignment: .leading)
                        
                        ProgressView(value: machine.memoryUsedPercent)
                            .progressViewStyle(SleekProgressViewStyle(color: Color(red: 0.1, green: 0.5, blue: 1.0)))
                        
                        Text("\(Int(machine.memoryUsedPercent * 100))%")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(AppTheme.text)
                            .frame(width: 32, alignment: .trailing)
                    }

                    // Storage progress
                    HStack(spacing: 8) {
                        Text("Storage")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(AppTheme.secondaryText)
                            .frame(width: 52, alignment: .leading)
                        
                        ProgressView(value: diskRatio(machine.disk))
                            .progressViewStyle(SleekProgressViewStyle(color: AppTheme.teal))
                        
                        Text("\(Int(diskRatio(machine.disk) * 100))%")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(AppTheme.text)
                            .frame(width: 32, alignment: .trailing)
                    }

                    // macOS info
                    HStack {
                        Text("macOS")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(AppTheme.secondaryText)
                        Spacer()
                        Text(formattedOSVersion(machine.macOSVersion))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    .padding(.top, 4)
                }
                .padding(14)
                .background(Color.white.opacity(0.04))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
            } else {
                VStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Loading system status...")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(14)
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 18)
    }

    private func diskRatio(_ disk: DiskOverview) -> Double {
        guard disk.totalBytes > 0 else { return 0 }
        return Double(disk.usedBytes) / Double(disk.totalBytes)
    }

    private func formattedOSVersion(_ version: String) -> String {
        version
            .replacingOccurrences(of: "Version ", with: "")
            .replacingOccurrences(of: "Build ", with: "")
    }

    private func cleanModelName(_ model: String) -> String {
        let lower = model.lowercased()
        if lower.contains("macbookpro") || lower.contains("mac14,9") || lower.contains("mac14,5") || lower.contains("mac14,6") || lower.contains("mac15,") || lower.contains("mac16,") {
            return "MacBook Pro"
        }
        if lower.contains("macbookair") || lower.contains("mac13,") || lower.contains("mac14,2") || lower.contains("mac14,15") {
            return "MacBook Air"
        }
        if lower.contains("macmini") || lower.contains("mac14,3") || lower.contains("mac14,12") {
            return "Mac mini"
        }
        if lower.contains("macstudio") || lower.contains("mac14,13") || lower.contains("mac14,14") {
            return "Mac Studio"
        }
        if lower.contains("macpro") {
            return "Mac Pro"
        }
        if lower.contains("imac") {
            return "iMac"
        }
        if model.range(of: "^Mac[0-9]+,[0-9]+$", options: .regularExpression) != nil {
            return "MacBook Pro"
        }
        return model
    }
}

struct SleekProgressViewStyle: ProgressViewStyle {
    var color: Color

    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(0.12))
                    .frame(height: 5)
                
                if let fraction = configuration.fractionCompleted {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(fraction), height: 5)
                }
            }
        }
        .frame(height: 5)
    }
}
