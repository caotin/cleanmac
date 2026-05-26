import AppKit
import CleanMacCore
import SwiftUI

struct SmartScanView: View {
    @EnvironmentObject private var state: AppState
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack {
                Text("Smart Scan")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)

                Spacer()

                HStack(spacing: 12) {
                    Button {
                        Task { await state.scanAll() }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 11))
                            Text("Start Over")
                        }
                        .font(.system(size: 12, weight: .medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(14)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.1), lineWidth: 1))
                    }
                    .buttonStyle(.plain)

                    Button {
                        // Action menu placeholder
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 13, weight: .bold))
                            .frame(width: 28, height: 28)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)

            // Update Banner
            if let updateInfo = state.updateInfo {
                UpdateBannerView(
                    info: updateInfo,
                    onUpdate: {
                        NSWorkspace.shared.open(updateInfo.releasePageURL)
                    },
                    onDismiss: {
                        state.dismissUpdate()
                    }
                )
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            VStack(spacing: 0) {
                Spacer(minLength: 16)
                
                // Main Title
                VStack(spacing: 6) {
                    Text(headerTitle)
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    
                    Text(headerSubtitle)
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .lineSpacing(4)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer(minLength: 16)

                // Run Scan button centered with Dot Matrix Background
                ZStack {
                    DotGridView()
                        .frame(width: 320, height: 180)
                    
                    GlowingRunScanButton(title: buttonTitle, isScanning: state.isBusyWithCleanupScan) {
                        Task {
                            if state.hasScanned && hasSafeItems {
                                await state.quickClean()
                            } else {
                                await state.scanAll()
                            }
                        }
                    }
                }
                .frame(height: 180)
                
                Spacer(minLength: 16)

                // 3 Metric Cards Row
                HStack(spacing: 16) {
                    // Card 1: Cleanup
                    SmartScanMetricCard(
                        icon: CleanupIconView(size: 20),
                        iconColor: Color(red: 0.1, green: 0.5, blue: 1.0),
                        title: "Cleanup",
                        value: CleanMacFormatting.bytes(totalJunkBytes),
                        subtext: "Junk files found",
                        actionText: "Review Details →",
                        action: { state.section = .cleanup }
                    )

                    // Card 2: Memory
                    SmartScanMetricCard(
                        icon: Image(systemName: "waveform.path.ecg")
                            .font(.system(size: 18, weight: .semibold)),
                        iconColor: Color(red: 0.2, green: 0.72, blue: 0.45),
                        title: "Memory",
                        value: memoryStatus,
                        subtext: memorySubtext,
                        badgeText: memoryBadgeText,
                        action: { state.section = .memory }
                    )

                    // Card 3: Developer Junk
                    SmartScanMetricCard(
                        icon: Image(systemName: "chevron.left.forwardslash.chevron.right")
                            .font(.system(size: 18, weight: .semibold)),
                        iconColor: Color(red: 0.05, green: 0.6, blue: 0.7),
                        title: "Developer Junk",
                        value: "\(developerJunkCount)",
                        subtext: "Tasks to review",
                        actionText: "Review Tasks →",
                        action: { state.section = .nodeModules }
                    )
                }
                .padding(.horizontal, 24)

                Spacer(minLength: 24)

                // What We Found Panel (Full-Width, aligned with cards)
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("What we found")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                        Spacer()
                        Button {
                            state.section = .cleanup
                        } label: {
                            Text("View All")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(AppTheme.cyan)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    HStack(spacing: 20) {
                        BreakdownRow(iconName: "folder.fill", iconColor: AppTheme.cyan, title: "Cache Files", size: cacheFilesSize)
                            .frame(maxWidth: .infinity)
                        BreakdownRow(iconName: "doc.text.fill", iconColor: AppTheme.teal, title: "Log Files", size: logFilesSize)
                            .frame(maxWidth: .infinity)
                        BreakdownRow(iconName: "doc.on.doc.fill", iconColor: .purple, title: "Temporary Files", size: tempFilesSize)
                            .frame(maxWidth: .infinity)
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.08))
                    
                    HStack {
                        Text("Total")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                        Spacer()
                        Text(CleanMacFormatting.bytes(totalJunkBytes))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color(red: 0.1, green: 0.5, blue: 1.0))
                    }
                }
                .padding(16)
                .background(Color.white.opacity(0.035))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
                .padding(.horizontal, 24)
                
                Spacer(minLength: 24)
            }
            .frame(maxHeight: .infinity)
        }
        .background(Color.clear)
    }

    // Dynamic calculations
    private var totalJunkBytes: UInt64 {
        state.allCandidates.reduce(0) { $0 + ($1.sizeBytes ?? 0) }
    }

    private var developerJunkCount: Int {
        state.nodeCandidates.count + state.dockerCandidates.count
    }

    private var memoryStatus: String {
        let pressure = state.machine?.memoryPressure.lowercased() ?? "normal"
        if pressure.contains("critical") || pressure.contains("serious") {
            return "Heavy"
        }
        return "Optimized"
    }

    private var memorySubtext: String {
        let pressure = state.machine?.memoryPressure.lowercased() ?? "normal"
        if pressure.contains("critical") || pressure.contains("serious") {
            return "Memory pressure is high"
        }
        return "Memory pressure is low"
    }

    private var memoryBadgeText: String? {
        let pressure = state.machine?.memoryPressure.lowercased() ?? "normal"
        if pressure.contains("critical") || pressure.contains("serious") {
            return nil
        }
        return "✓ Great"
    }

    private var cacheFilesSize: UInt64 {
        state.allCandidates
            .filter {
                $0.category == .devCaches ||
                $0.category == .browserCaches ||
                $0.category == .aiDevCaches ||
                $0.category == .virtualizationCaches ||
                $0.path?.localizedCaseInsensitiveContains("cache") == true
            }
            .reduce(0) { $0 + ($1.sizeBytes ?? 0) }
    }

    private var logFilesSize: UInt64 {
        state.allCandidates
            .filter { $0.path?.localizedCaseInsensitiveContains("log") == true }
            .reduce(0) { $0 + ($1.sizeBytes ?? 0) }
    }

    private var tempFilesSize: UInt64 {
        let cacheAndLogs = state.allCandidates.filter {
            $0.category == .devCaches ||
            $0.category == .browserCaches ||
            $0.category == .aiDevCaches ||
            $0.category == .virtualizationCaches ||
            $0.path?.localizedCaseInsensitiveContains("cache") == true ||
            $0.path?.localizedCaseInsensitiveContains("log") == true
        }
        let cacheAndLogsIDs = Set(cacheAndLogs.map(\.id))
        return state.allCandidates
            .filter { !cacheAndLogsIDs.contains($0.id) }
            .reduce(0) { $0 + ($1.sizeBytes ?? 0) }
    }

    private var headerTitle: String {
        if state.isRunningQuickClean {
            return "Cleaning Your Mac..."
        } else if state.isBusyWithCleanupScan {
            return "Scanning Your Mac..."
        } else if state.hasScanned {
            return totalJunkBytes > 0 ? "Your Mac is ready for cleanup" : "Your Mac is clean and optimized"
        } else {
            return "Start with a clean, safe scan"
        }
    }

    private var headerSubtitle: String {
        if state.isRunningQuickClean {
            return "Removing safe junk files and optimizing system resources."
        } else if state.isBusyWithCleanupScan {
            return "Analyzing system caches, log files, developer modules, and Docker containers."
        } else if state.hasScanned {
            return totalJunkBytes > 0
                ? "We've found junk files, optimized memory, and developer clutter\nthat you can safely remove."
                : "No unnecessary files or active optimizations are needed at this time."
        } else {
            return "Cleanup, developer junk, memory, and app review in one compact dashboard."
        }
    }

    private var buttonTitle: String {
        if state.isRunningQuickClean {
            return "Cleaning..."
        } else if state.isBusyWithCleanupScan {
            return "Scanning..."
        } else if state.hasScanned && hasSafeItems {
            return "Smart Cleanup"
        } else {
            return "Run Scan"
        }
    }

    private var hasSafeItems: Bool {
        let safe = CleanupSelectionPlanner.quickCleanCandidates(from: state.allCandidates)
        return !safe.isEmpty
    }
}

struct BreakdownRow: View {
    var iconName: String
    var iconColor: Color
    var title: String
    var size: UInt64
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 26, height: 26)
                
                Image(systemName: iconName)
                    .font(.system(size: 12))
                    .foregroundStyle(iconColor)
            }

            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.text)

            Spacer()

            Text(CleanMacFormatting.bytes(size))
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppTheme.secondaryText)

            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(AppTheme.secondaryText.opacity(0.5))
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background(isHovered ? Color.white.opacity(0.03) : Color.clear)
        .cornerRadius(8)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
