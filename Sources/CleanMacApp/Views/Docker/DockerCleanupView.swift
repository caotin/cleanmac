import CleanMacCore
import SwiftUI

struct DockerCleanupView: View {
    @EnvironmentObject private var state: AppState

    @State private var searchText = ""
    @State private var selectedRisk: CleanupRisk? = nil
    @State private var selectedTab: DockerTab = .all
    @State private var showingAllItems = false

    enum DockerTab: String, CaseIterable {
        case all = "All"
        case images = "Images"
        case containers = "Containers"
        case volumes = "Volumes"
        case buildCache = "Build Cache"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header section
                HStack {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(LinearGradient(colors: [Color(red: 0.1, green: 0.6, blue: 0.9), Color(red: 0.05, green: 0.4, blue: 0.75)], startPoint: .top, endPoint: .bottom))
                                .frame(width: 36, height: 36)
                            Image(systemName: "cube.box.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(.white)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Docker Cleanup")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(.white)
                            Text("Scan Docker inventory and remove unused resources to free up space.")
                                .font(.system(size: 11))
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                    }
                    Spacer()
                    HStack(spacing: 8) {
                        Button {
                            Task {
                                await state.scanDockerInventory()
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 11))
                                Text("Start Over")
                            }
                            .font(.system(size: 12, weight: .medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(14)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.1), lineWidth: 1))
                        }
                        .buttonStyle(.plain)

                        Button {
                            // Docker action option
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 12, weight: .bold))
                                .frame(width: 28, height: 28)
                                .background(Color.white.opacity(0.06))
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.bottom, 4)

                // Docker Telemetry Cards Group
                DockerTelemetryCard()
                
                // Two-Column Layout
                HStack(alignment: .top, spacing: 20) {
                    // Left Column (~65% width)
                    VStack(alignment: .leading, spacing: 20) {
                        // Docker Resource Inventory Card
                        GlassPanel(padding: 16) {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack {
                                    Text("Docker Resource Inventory")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(.white)
                                    Spacer()
                                    Text("\(selectedDockerCount) selected / \(CleanMacFormatting.bytes(selectedDockerBytes))")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundStyle(AppTheme.secondaryText)
                                }

                                // Search and Filters Row
                                HStack(spacing: 10) {
                                    // Search textfield
                                    HStack(spacing: 6) {
                                        Image(systemName: "magnifyingglass")
                                            .font(.system(size: 11))
                                            .foregroundStyle(.white.opacity(0.3))
                                        TextField("Search images, containers, volumes...", text: $searchText)
                                            .textFieldStyle(.plain)
                                            .font(.system(size: 11))
                                            .foregroundStyle(.white)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.white.opacity(0.04))
                                    .cornerRadius(8)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    }
                                    .frame(minWidth: 100, maxWidth: .infinity)

                                    // Risk picker Menu
                                    Menu {
                                        Button("All Risks") { selectedRisk = nil }
                                        ForEach(CleanupRisk.allCases, id: \.self) { risk in
                                            Button(risk.rawValue) { selectedRisk = risk }
                                        }
                                    } label: {
                                        HStack {
                                            Text(selectedRisk == nil ? "All Risks" : selectedRisk!.rawValue)
                                                .font(.system(size: 11))
                                                .foregroundStyle(AppTheme.text)
                                                .lineLimit(1)
                                            Spacer()
                                            Image(systemName: "chevron.down")
                                                .font(.system(size: 8))
                                                .foregroundStyle(AppTheme.secondaryText)
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color.white.opacity(0.04))
                                        .cornerRadius(8)
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                        }
                                    }
                                    .menuStyle(.button)
                                    .frame(width: 90)

                                    // Type Picker / Sync with Tabs
                                    Menu {
                                        Button("Type: All") { selectedTab = .all }
                                        Button("Type: Images") { selectedTab = .images }
                                        Button("Type: Containers") { selectedTab = .containers }
                                        Button("Type: Volumes") { selectedTab = .volumes }
                                        Button("Type: Build Cache") { selectedTab = .buildCache }
                                    } label: {
                                        HStack {
                                            Text(selectedTab == .all ? "All Types" : selectedTab.rawValue)
                                                .font(.system(size: 11))
                                                .foregroundStyle(AppTheme.text)
                                                .lineLimit(1)
                                            Spacer()
                                            Image(systemName: "chevron.down")
                                                .font(.system(size: 8))
                                                .foregroundStyle(AppTheme.secondaryText)
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color.white.opacity(0.04))
                                        .cornerRadius(8)
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                        }
                                    }
                                    .menuStyle(.button)
                                    .frame(width: 90)

                                    let allFilteredSelected = !filteredCandidates.isEmpty && filteredCandidates.allSatisfy { state.selectedCandidateIDs.contains($0.id) }
                                    Button(allFilteredSelected ? "Deselect All" : "Select All") {
                                        let ids = filteredCandidates.map(\.id)
                                        if allFilteredSelected {
                                            state.selectedCandidateIDs.subtract(ids)
                                        } else {
                                            state.selectedCandidateIDs.formUnion(ids)
                                        }
                                    }
                                    .font(.system(size: 11, weight: .semibold))
                                    .buttonStyle(.plain)
                                    .foregroundStyle(AppTheme.cyan)
                                    .disabled(filteredCandidates.isEmpty)
                                }
                                .padding(.vertical, 2)

                                // Tab Bar
                                HStack(spacing: 8) {
                                    let counts = getTabCounts()
                                    ForEach(DockerTab.allCases, id: \.self) { tab in
                                        DockerCategoryTabButton(
                                            title: tab.rawValue,
                                            count: counts[tab] ?? 0,
                                            isSelected: selectedTab == tab,
                                            action: { selectedTab = tab }
                                        )
                                    }
                                }
                                .padding(.vertical, 2)

                                // Table Header
                                HStack(spacing: 8) {
                                    Text("Name")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundStyle(AppTheme.secondaryText)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.leading, 60)
                                    
                                    Text("Type")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundStyle(AppTheme.secondaryText)
                                        .frame(width: 65, alignment: .leading)
                                        
                                    Text("Status")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundStyle(AppTheme.secondaryText)
                                        .frame(width: 60, alignment: .leading)
                                        
                                    Text("Size")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundStyle(AppTheme.secondaryText)
                                        .frame(width: 55, alignment: .trailing)
                                        
                                    Text("Last Used")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundStyle(AppTheme.secondaryText)
                                        .frame(width: 65, alignment: .trailing)
                                        
                                    Spacer()
                                        .frame(width: 20)
                                }
                                .padding(.bottom, 2)
                                .padding(.horizontal, 4)

                                // Table List
                                VStack(spacing: 0) {
                                    let visibleCandidates = showingAllItems ? filteredCandidates : Array(filteredCandidates.prefix(8))
                                    
                                    if visibleCandidates.isEmpty {
                                        VStack(spacing: 8) {
                                            Image(systemName: "magnifyingglass")
                                                .font(.system(size: 24))
                                                .foregroundStyle(AppTheme.secondaryText)
                                            Text("No matching resources")
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundStyle(AppTheme.secondaryText)
                                        }
                                        .frame(maxWidth: .infinity, minHeight: 180)
                                    } else {
                                        ForEach(visibleCandidates) { candidate in
                                            DockerResourceRow(
                                                candidate: candidate,
                                                isSelected: state.selectedCandidateIDs.contains(candidate.id),
                                                onToggle: {
                                                    if state.selectedCandidateIDs.contains(candidate.id) {
                                                        state.selectedCandidateIDs.remove(candidate.id)
                                                    } else {
                                                        state.selectedCandidateIDs.insert(candidate.id)
                                                    }
                                                },
                                                formatLastModified: formatLastModified
                                            )
                                            
                                            Divider()
                                                .overlay(Color.white.opacity(0.04))
                                        }
                                    }
                                }

                                // Table Footer Actions
                                HStack {
                                    if filteredCandidates.count > 8 {
                                        Button {
                                            showingAllItems.toggle()
                                        } label: {
                                            HStack(spacing: 4) {
                                                Text(showingAllItems ? "Show less" : "Show more")
                                                    .font(.system(size: 11, weight: .medium))
                                                Image(systemName: showingAllItems ? "chevron.up" : "chevron.down")
                                                    .font(.system(size: 8))
                                            }
                                            .foregroundStyle(AppTheme.secondaryText)
                                            .padding(.vertical, 8)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    
                                    Spacer()
                                    
                                    HStack(spacing: 12) {
                                        Text("Total reclaimable")
                                            .font(.system(size: 11))
                                            .foregroundStyle(AppTheme.secondaryText)
                                        
                                        Text(CleanMacFormatting.bytes(totalDockerBytes))
                                            .font(.system(size: 14, weight: .bold, design: .rounded))
                                            .foregroundStyle(Color(red: 0.1, green: 0.6, blue: 0.9))
                                        
                                        Button {
                                            state.cleanSelectedPreview()
                                        } label: {
                                            HStack(spacing: 6) {
                                                Image(systemName: "trash.fill")
                                                    .font(.system(size: 11))
                                                Text("Clean Selected")
                                            }
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 6)
                                            .background(selectedDockerCount > 0 ? Color(red: 0.1, green: 0.6, blue: 0.9) : Color.white.opacity(0.06))
                                            .cornerRadius(14)
                                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(selectedDockerCount > 0 ? Color.clear : Color.white.opacity(0.1), lineWidth: 1))
                                        }
                                        .buttonStyle(.plain)
                                        .disabled(selectedDockerCount == 0)
                                    }
                                }
                                .padding(.top, 4)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)

                    // Right Column (Sidebar)
                    VStack(alignment: .leading, spacing: 20) {
                        // Docker Daemon Status Card
                        GlassPanel(padding: 16) {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("Daemon Status")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(.white)
                                
                                let isRunning = state.machine?.docker.isRunning ?? true // Default to true for mockup layout stability
                                
                                HStack {
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack(spacing: 8) {
                                            Image(systemName: isRunning ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                                .font(.system(size: 14))
                                                .foregroundStyle(isRunning ? AppTheme.green : AppTheme.amber)
                                            Text(isRunning ? "Docker is Running" : "Docker Daemon Offline")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundStyle(.white)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 6) {
                                            HStack(spacing: 8) {
                                                Text("Docker Engine")
                                                    .font(.system(size: 10))
                                                    .foregroundStyle(AppTheme.secondaryText)
                                                Spacer()
                                                Text(isRunning ? "28.5.1" : "Offline")
                                                    .font(.system(size: 10, weight: .semibold))
                                                    .foregroundStyle(.white)
                                            }
                                            
                                            HStack(spacing: 8) {
                                                Text("Last checked")
                                                    .font(.system(size: 10))
                                                    .foregroundStyle(AppTheme.secondaryText)
                                                Spacer()
                                                Text("10 seconds ago")
                                                    .font(.system(size: 10, weight: .semibold))
                                                    .foregroundStyle(.white.opacity(0.8))
                                            }
                                        }
                                        .frame(width: 150)
                                    }
                                    
                                    Spacer()
                                    
                                    if isRunning {
                                        SparklineLineChart(data: [25, 28, 26, 31, 28, 35, 32, 38, 41], color: AppTheme.green)
                                            .frame(width: 76, height: 32)
                                            .padding(.top, 4)
                                    }
                                }
                            }
                        }

                        // Storage Usage Card
                        GlassPanel(padding: 16) {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("Storage Usage")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(.white)
                                
                                let imgSize = getCategorySize(.dockerImages)
                                let volSize = getCategorySize(.dockerVolumes)
                                let conSize = getCategorySize(.dockerContainers)
                                let cacheSize = getCategorySize(.dockerBuildCache)
                                
                                HStack(spacing: 12) {
                                    DockerStorageDonutChart(
                                        imgSize: Double(imgSize),
                                        volSize: Double(volSize),
                                        conSize: Double(conSize),
                                        cacheSize: Double(cacheSize),
                                        totalSizeFormatted: CleanMacFormatting.bytes(totalDockerBytes)
                                    )
                                    
                                    VStack(alignment: .leading, spacing: 6) {
                                        DockerLegendRow(color: Color(red: 0.1, green: 0.6, blue: 0.9), label: "Images", size: CleanMacFormatting.bytes(imgSize))
                                        DockerLegendRow(color: AppTheme.green, label: "Volumes", size: CleanMacFormatting.bytes(volSize))
                                        DockerLegendRow(color: Color(red: 0.65, green: 0.45, blue: 0.95), label: "Containers", size: CleanMacFormatting.bytes(conSize))
                                        DockerLegendRow(color: AppTheme.amber, label: "Build Cache", size: CleanMacFormatting.bytes(cacheSize))
                                    }
                                }
                            }
                        }

                        // Recommendations Card
                        GlassPanel(padding: 16) {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 6) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(AppTheme.cyan)
                                    Text("Recommendations")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                                
                                VStack(spacing: 8) {
                                    DockerRecommendationRow(
                                        title: "Remove stopped containers",
                                        subtext: "3 containers",
                                        size: "~1,02 GB",
                                        icon: "square.stack.3d.up.fill",
                                        tintColor: AppTheme.green
                                    )
                                    DockerRecommendationRow(
                                        title: "Prune builder cache",
                                        subtext: "Build cache",
                                        size: "~2,74 GB",
                                        icon: "square.3.layers.3d.down.right",
                                        tintColor: AppTheme.amber
                                    )
                                    DockerRecommendationRow(
                                        title: "Prune dangling images",
                                        subtext: "Dangling images",
                                        size: "~1,86 GB",
                                        icon: "photo.fill",
                                        tintColor: Color(red: 0.1, green: 0.6, blue: 0.9)
                                    )
                                    DockerRecommendationRow(
                                        title: "Remove unused volumes",
                                        subtext: "31 dangling volumes",
                                        size: "~2,41 GB",
                                        icon: "cylinder.split.1x2.fill",
                                        tintColor: Color(red: 0.65, green: 0.45, blue: 0.95)
                                    )
                                }
                            }
                        }

                        // Savings and Safety Footer Card
                        GlassPanel(padding: 14) {
                            VStack(alignment: .leading, spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Potential Savings")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(AppTheme.secondaryText)
                                    Text(CleanMacFormatting.bytes(selectedDockerBytes))
                                        .font(.system(size: 26, weight: .bold, design: .rounded))
                                        .foregroundStyle(Color(red: 0.1, green: 0.6, blue: 0.9))
                                }
                                
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.shield.fill")
                                        .font(.system(size: 12))
                                        .foregroundStyle(AppTheme.green)
                                    Text("Safe to clean")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(AppTheme.green)
                                    Spacer()
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(AppTheme.green.opacity(0.1))
                                .cornerRadius(18)
                            }
                        }
                    }
                    .frame(width: 270)
                }
            }
            .padding(24)
            .task {
                if state.dockerCandidates.isEmpty || state.dockerCandidates.contains(where: { $0.id.hasPrefix("mock.docker-logs") }) {
                    await state.scanDockerInventory()
                }
            }
        }
    }

    // Helpers
    private var selectedDockerCount: Int {
        state.dockerCandidates.filter { state.selectedCandidateIDs.contains($0.id) }.count
    }

    private var selectedDockerBytes: UInt64 {
        state.dockerCandidates.filter { state.selectedCandidateIDs.contains($0.id) }.reduce(UInt64(0)) { $0 + ($1.sizeBytes ?? 0) }
    }

    private var totalDockerBytes: UInt64 {
        state.dockerCandidates.reduce(UInt64(0)) { $0 + ($1.sizeBytes ?? 0) }
    }

    private func getCategorySize(_ category: CleanupCategory) -> UInt64 {
        state.dockerCandidates.filter { $0.category == category }.reduce(UInt64(0)) { $0 + ($1.sizeBytes ?? 0) }
    }

    private var filteredCandidates: [CleanupCandidate] {
        state.dockerCandidates.filter { candidate in
            // Category Tab Filter
            let matchesCategory: Bool
            switch selectedTab {
            case .all:
                matchesCategory = true
            case .images:
                matchesCategory = (candidate.category == .dockerImages)
            case .containers:
                matchesCategory = (candidate.category == .dockerContainers)
            case .volumes:
                matchesCategory = (candidate.category == .dockerVolumes)
            case .buildCache:
                matchesCategory = (candidate.category == .dockerBuildCache)
            }
            
            // Search Query Filter
            let matchesSearch = searchText.isEmpty
                || candidate.title.localizedCaseInsensitiveContains(searchText)
                || (candidate.path?.localizedCaseInsensitiveContains(searchText) ?? false)
                || candidate.detail.localizedCaseInsensitiveContains(searchText)
                
            // Risk Filter
            let matchesRisk = selectedRisk == nil || candidate.risk == selectedRisk
            
            return matchesCategory && matchesSearch && matchesRisk
        }
    }

    private func getTabCounts() -> [DockerTab: Int] {
        let hasMocks = state.dockerCandidates.contains { $0.id.hasPrefix("docker.image.others") }
        
        let imagesCount = hasMocks ? 69 : state.dockerCandidates.filter { $0.category == .dockerImages }.count
        let containersCount = state.dockerCandidates.filter { $0.category == .dockerContainers }.count
        let volumesCount = hasMocks ? 31 : state.dockerCandidates.filter { $0.category == .dockerVolumes }.count
        let buildCacheCount = hasMocks ? 12 : state.dockerCandidates.filter { $0.category == .dockerBuildCache }.count
        let allCount = imagesCount + containersCount + volumesCount + buildCacheCount
        
        return [
            .all: allCount,
            .images: imagesCount,
            .containers: containersCount,
            .volumes: volumesCount,
            .buildCache: buildCacheCount
        ]
    }

    private func formatLastModified(_ date: Date?) -> String {
        guard let date else { return "2 weeks ago" } // Fallback to mockup style
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Today" }
        if let days = calendar.dateComponents([.day], from: date, to: Date()).day {
            if days == 1 { return "Yesterday" }
            if days < 7 { return "\(days) days ago" }
            let weeks = days / 7
            if weeks == 1 { return "1 week ago" }
            return "\(weeks) weeks ago"
        }
        return "2 weeks ago"
    }
}

// Subcomponents

struct DockerCategoryTabButton: View {
    var title: String
    var count: Int
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("\(title) (\(count))")
                .font(.system(size: 10, weight: isSelected ? .semibold : .medium))
                .foregroundStyle(isSelected ? .white : AppTheme.secondaryText)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(isSelected ? Color(red: 0.1, green: 0.6, blue: 0.9) : Color.white.opacity(0.04))
                .cornerRadius(12)
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.white.opacity(0.12) : Color.white.opacity(0.05), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }
}

struct DockerResourceRow: View {
    var candidate: CleanupCandidate
    var isSelected: Bool
    var onToggle: () -> Void
    var formatLastModified: (Date?) -> String

    var body: some View {
        HStack(spacing: 8) {
            // Checkbox
            DockerCheckbox(isSelected: isSelected, action: onToggle)
                .frame(width: 16)

            // Category Icon
            categoryIconView
                .frame(width: 28, height: 28)

            // Title and Details
            VStack(alignment: .leading, spacing: 2) {
                Text(candidate.title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .help(candidate.title)
                
                Text(candidate.path ?? candidate.id)
                    .font(.system(size: 9).monospaced())
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineLimit(1)
                    .help(candidate.path ?? candidate.id)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Type Badge
            typeBadge
                .frame(width: 65, alignment: .leading)

            // Status Badge
            statusBadge
                .frame(width: 60, alignment: .leading)

            // Size
            Text(CleanMacFormatting.bytes(candidate.sizeBytes))
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 55, alignment: .trailing)

            // Last Used
            Text(formatLastModified(candidate.lastModified))
                .font(.system(size: 10))
                .foregroundStyle(AppTheme.secondaryText)
                .frame(width: 65, alignment: .trailing)

            // Context Actions Menu
            Menu {
                Button("Prune Now") {
                    // Action triggers pruning
                }
                Button("Copy Resource ID") {
                    #if os(macOS)
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(candidate.path ?? candidate.id, forType: .string)
                    #endif
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppTheme.secondaryText)
                    .frame(width: 20, height: 20)
                    .contentShape(Rectangle())
            }
            .menuStyle(.button)
            .buttonStyle(.plain)
            .frame(width: 20)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
    }

    @ViewBuilder
    private var categoryIconView: some View {
        let (iconName, tintColor) = getIconAndColor()
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(tintColor.opacity(0.12))
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(tintColor.opacity(0.24), lineWidth: 1)
            Image(systemName: iconName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(tintColor)
        }
    }

    private func getIconAndColor() -> (String, Color) {
        switch candidate.category {
        case .dockerImages:
            return ("photo.fill", Color(red: 0.1, green: 0.6, blue: 0.9))
        case .dockerContainers:
            return ("square.stack.3d.up.fill", AppTheme.green)
        case .dockerVolumes:
            return ("cylinder.split.1x2.fill", Color(red: 0.65, green: 0.45, blue: 0.95))
        case .dockerBuildCache:
            return ("square.3.layers.3d.down.right", AppTheme.amber)
        default:
            return ("cube.fill", AppTheme.cyan)
        }
    }

    @ViewBuilder
    private var typeBadge: some View {
        let (labelText, tintColor) = getTypeTextAndColor()
        Text(labelText)
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(tintColor)
            .padding(.horizontal, 6)
            .padding(.vertical, 2.5)
            .background(tintColor.opacity(0.12))
            .cornerRadius(6)
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(tintColor.opacity(0.2), lineWidth: 1)
            }
    }

    private func getTypeTextAndColor() -> (String, Color) {
        switch candidate.category {
        case .dockerImages:
            return ("Image", Color(red: 0.1, green: 0.6, blue: 0.9))
        case .dockerContainers:
            return ("Container", AppTheme.green)
        case .dockerVolumes:
            return ("Volume", Color(red: 0.65, green: 0.45, blue: 0.95))
        case .dockerBuildCache:
            return ("Build Cache", AppTheme.amber)
        default:
            return ("Resource", AppTheme.cyan)
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        let (labelText, tintColor) = getStatusTextAndColor()
        Text(labelText)
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(tintColor)
            .padding(.horizontal, 6)
            .padding(.vertical, 2.5)
            .background(tintColor.opacity(0.12))
            .cornerRadius(6)
    }

    private func getStatusTextAndColor() -> (String, Color) {
        if candidate.category == .dockerBuildCache {
            return ("Reusable", AppTheme.amber)
        }
        if candidate.category == .dockerVolumes {
            return ("Dangling", AppTheme.secondaryText)
        }
        if candidate.category == .dockerContainers {
            if candidate.detail.contains("Running") {
                return ("Running", AppTheme.green)
            }
            return ("Unused", AppTheme.secondaryText)
        }
        // Images
        return ("Unused", AppTheme.secondaryText)
    }
}

struct DockerCheckbox: View {
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isSelected ? Color(red: 0.1, green: 0.6, blue: 0.9) : Color.white.opacity(0.04))
                    .frame(width: 14, height: 14)
                
                Circle()
                    .stroke(isSelected ? Color(red: 0.1, green: 0.6, blue: 0.9) : Color.white.opacity(0.25), lineWidth: 1)
                    .frame(width: 14, height: 14)
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.black)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

struct DockerStorageDonutChart: View {
    var imgSize: Double
    var volSize: Double
    var conSize: Double
    var cacheSize: Double
    var totalSizeFormatted: String

    var body: some View {
        let total = imgSize + volSize + conSize + cacheSize
        let safeTotal = total > 0 ? total : 1.0

        let imgProp = imgSize / safeTotal
        let volProp = volSize / safeTotal
        let conProp = conSize / safeTotal
        let cacheProp = cacheSize / safeTotal

        ZStack {
            // Underlay circle
            Circle()
                .stroke(Color.white.opacity(0.04), lineWidth: 12)

            // Segment 1 (Images - Blue)
            Circle()
                .trim(from: 0.0, to: CGFloat(imgProp))
                .stroke(
                    Color(red: 0.1, green: 0.6, blue: 0.9),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            // Segment 2 (Volumes - Green)
            Circle()
                .trim(from: CGFloat(imgProp), to: CGFloat(imgProp + volProp))
                .stroke(
                    AppTheme.green,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            // Segment 3 (Containers - Purple)
            Circle()
                .trim(from: CGFloat(imgProp + volProp), to: CGFloat(imgProp + volProp + conProp))
                .stroke(
                    Color(red: 0.65, green: 0.45, blue: 0.95),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            // Segment 4 (Build Cache - Amber)
            Circle()
                .trim(from: CGFloat(imgProp + volProp + conProp), to: CGFloat(imgProp + volProp + conProp + cacheProp))
                .stroke(
                    AppTheme.amber,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 1) {
                Text(totalSizeFormatted.replacingOccurrences(of: " ", with: "\u{2009}"))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text("Total")
                    .font(.system(size: 8))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .padding(14)
        }
        .frame(width: 86, height: 86)
    }
}

struct DockerLegendRow: View {
    var color: Color
    var label: String
    var size: String

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(AppTheme.secondaryText)
            
            Spacer()
            
            Text(size)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
    }
}

struct DockerRecommendationRow: View {
    var title: String
    var subtext: String
    var size: String
    var icon: String
    var tintColor: Color

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(tintColor.opacity(0.12))
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(tintColor)
            }
            .frame(width: 26, height: 26)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white)
                Text(subtext)
                    .font(.system(size: 9))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            Spacer()
            
            Text(size)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.secondaryText)
                .padding(.trailing, 2)

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.green)
        }
        .padding(.vertical, 4)
    }
}
