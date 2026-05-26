import CleanMacCore
import SwiftUI

struct CandidateReviewTable: View {
    @EnvironmentObject private var state: AppState
    var candidates: [CleanupCandidate]
    var title: String = "Review Items"

    @State private var searchText = ""
    @State private var selectedRisk: CleanupRisk?
    @State private var selectedCategory: CleanupCategory?
    @State private var expandedIDs: Set<String> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppTheme.text)
                Spacer()
                Text("\(selectedCount) selected / \(CleanMacFormatting.bytes(totalBytes))")
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .padding(.horizontal, 4)

            reviewControls

            if filteredCandidates.isEmpty {
                ContentUnavailableView("Nothing to show", systemImage: "magnifyingglass", description: Text("Run a scan or adjust the filters."))
            } else {
                VStack(spacing: 0) {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(filteredCandidates) { candidate in
                                CandidateReviewRow(
                                    candidate: candidate,
                                    isSelected: Binding(
                                        get: { state.selectedCandidateIDs.contains(candidate.id) },
                                        set: { isSelected in
                                            if isSelected {
                                                state.selectedCandidateIDs.insert(candidate.id)
                                            } else {
                                                state.selectedCandidateIDs.remove(candidate.id)
                                            }
                                        }
                                    ),
                                    isExpanded: expandedIDs.contains(candidate.id)
                                ) {
                                    if expandedIDs.contains(candidate.id) {
                                        expandedIDs.remove(candidate.id)
                                    } else {
                                        expandedIDs.insert(candidate.id)
                                    }
                                }
                                
                                Divider()
                                    .overlay(Color.white.opacity(0.06))
                            }
                        }
                    }
                    .frame(maxHeight: .infinity)
                    
                    HStack {
                        Spacer()
                        Button {
                            // Action to show more
                        } label: {
                            HStack(spacing: 4) {
                                Text("Show more")
                                    .font(.system(size: 11))
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 9))
                            }
                            .foregroundStyle(AppTheme.secondaryText)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }
                    .padding(.top, 4)
                }
            }
        }
    }

    private var reviewControls: some View {
        HStack(spacing: 10) {
            // Search textfield
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.3))
                TextField("Search files, paths, or details", text: $searchText)
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
            .frame(minWidth: 200, maxWidth: .infinity)

            // Risk picker Menu
            Menu {
                Button("All Risks") { selectedRisk = nil }
                ForEach(CleanupRisk.allCases, id: \.self) { risk in
                    Button(risk.rawValue) { selectedRisk = risk }
                }
            } label: {
                HStack {
                    Text(selectedRisk == nil ? "Risk: All Risks" : "Risk: \(selectedRisk!.rawValue)")
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.text)
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
            .frame(width: 130)

            // Category picker Menu
            Menu {
                Button("All Categories") { selectedCategory = nil }
                ForEach(availableCategories, id: \.self) { category in
                    Button(category.rawValue) { selectedCategory = category }
                }
            } label: {
                HStack {
                    Text(selectedCategory == nil ? "Category: All Categories" : "Category: \(selectedCategory!.rawValue)")
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.text)
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
            .frame(width: 170)

            Button("Select All") {
                state.selectedCandidateIDs.formUnion(CandidateReviewPlanner.selectAllIDs(from: candidates))
            }
            .font(.system(size: 11, weight: .semibold))
            .buttonStyle(.plain)
            .foregroundStyle(AppTheme.cyan)
            .disabled(candidates.isEmpty)
        }
        .padding(.vertical, 4)
    }

    private var filter: CandidateReviewFilter {
        CandidateReviewFilter(
            searchText: searchText,
            risks: selectedRisk.map { [$0] } ?? [],
            categories: selectedCategory.map { [$0] } ?? []
        )
    }

    private var filteredCandidates: [CleanupCandidate] {
        CandidateReviewPlanner.filteredCandidates(candidates, filter: filter)
    }

    private var availableCategories: [CleanupCategory] {
        Array(Set(candidates.map(\.category))).sorted { $0.rawValue < $1.rawValue }
    }

    private var selectedCount: Int {
        candidates.filter { state.selectedCandidateIDs.contains($0.id) }.count
    }

    private var totalBytes: UInt64 {
        candidates.reduce(UInt64(0)) { $0 + ($1.sizeBytes ?? 0) }
    }
}

struct CandidateReviewRow: View {
    var candidate: CleanupCandidate
    @Binding var isSelected: Bool
    var isExpanded: Bool
    var toggleExpanded: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                // Checkbox
                Toggle("", isOn: $isSelected)
                    .labelsHidden()
                    .toggleStyle(CheckboxToggleStyle())
                    .frame(width: 16)

                // Category Icon
                categoryIconView
                    .frame(width: 28, height: 28)

                // Title and path
                Button(action: toggleExpanded) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(candidate.title)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(AppTheme.text)
                            .lineLimit(1)
                        
                        Text(candidate.path ?? candidate.detail)
                            .font(.system(size: 10))
                            .foregroundStyle(AppTheme.secondaryText)
                            .lineLimit(1)
                    }
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .leading)

                // Status Badge
                RiskBadge(risk: candidate.risk)
                    .frame(width: 64, alignment: .leading)

                // Size
                Text(CleanMacFormatting.bytes(candidate.sizeBytes))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.text)
                    .frame(width: 80, alignment: .trailing)

                // Info Action
                if candidate.category != .nodeModules {
                    Button {
                        // Show info popover/alert
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    .buttonStyle(.plain)
                    .frame(width: 20)
                }

                // Chevron for expansion
                Button(action: toggleExpanded) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(AppTheme.secondaryText)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .buttonStyle(.plain)
                .frame(width: 20)
            }

            if isExpanded {
                VStack(alignment: .leading, spacing: 6) {
                    if candidate.risk == .high {
                        Text("High risk: review this item carefully before cleanup.")
                            .font(.caption.bold())
                            .foregroundStyle(.red)
                    }
                    Text(candidate.detail)
                        .font(.system(size: 11))
                    if let path = candidate.path {
                        Text("Path: \(path)")
                            .font(.system(size: 10).monospaced())
                    }
                    if let command = candidate.commandPreview {
                        Text("Command: \(command)")
                            .font(.system(size: 10).monospaced())
                    }
                }
                .foregroundStyle(AppTheme.secondaryText)
                .padding(.leading, 56)
                .padding(.vertical, 4)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
    }

    @ViewBuilder
    private var categoryIconView: some View {
        let categoryColor: Color = {
            switch candidate.category {
            case .dockerImages, .dockerContainers, .dockerVolumes, .dockerBuildCache:
                return Color(red: 0.1, green: 0.5, blue: 1.0)
            case .nodeModules:
                return Color(red: 0.65, green: 0.45, blue: 0.95)
            case .largeFiles:
                return AppTheme.teal
            case .trashBins:
                return AppTheme.amber
            case .applications:
                return AppTheme.red
            default:
                return AppTheme.green
            }
        }()
        
        let iconName: String = {
            switch candidate.category {
            case .dockerImages, .dockerContainers, .dockerVolumes, .dockerBuildCache:
                return "cube.fill"
            case .nodeModules:
                return "shippingbox.fill"
            case .largeFiles:
                return "folder.fill"
            case .trashBins:
                return "trash.fill"
            case .applications:
                return "app.dashed"
            default:
                return "doc.text.fill"
            }
        }()

        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(categoryColor.opacity(0.15))
            Image(systemName: iconName)
                .font(.system(size: 13))
                .foregroundStyle(categoryColor)
        }
    }
}

struct RiskBadge: View {
    var risk: CleanupRisk

    var body: some View {
        Text(displayText)
            .font(.system(size: 10, weight: .semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.12))
            .cornerRadius(6)
            .foregroundStyle(color)
    }

    private var displayText: String {
        switch risk {
        case .low, .medium: return "Safe"
        case .high: return "Review"
        }
    }

    private var color: Color {
        switch risk {
        case .low, .medium: return AppTheme.green
        case .high: return AppTheme.amber
        }
    }
}

struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(configuration.isOn ? AppTheme.cyan : Color.white.opacity(0.04))
                    .frame(width: 14, height: 14)
                
                RoundedRectangle(cornerRadius: 4)
                    .stroke(configuration.isOn ? AppTheme.cyan : Color.white.opacity(0.25), lineWidth: 1)
                    .frame(width: 14, height: 14)
                
                if configuration.isOn {
                    Image(systemName: "checkmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.black)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
