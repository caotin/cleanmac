import CleanMacCore
import SwiftUI

struct MemoryOptimizeReviewCard: View {
    @EnvironmentObject private var state: AppState
    @Binding var searchText: String
    @Binding var selectedRisk: String
    @Binding var selectedCategory: String
    @Binding var isSafeOptimizeSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Memory Optimize Review")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                Text("\(isSafeOptimizeSelected ? 1 : 0) selected / Zero KB")
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            
            // Search & Filter controls
            HStack(spacing: 8) {
                // Search textfield
                HStack {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.secondaryText)
                    TextField("Search files, paths, or details", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.05))
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.08), lineWidth: 1))
                .frame(minWidth: 100, maxWidth: 240)
                
                Spacer()
                
                // Filter dropdowns
                Menu {
                    Button("All Risks") { selectedRisk = "All Risks" }
                    Button("Medium Risks") { selectedRisk = "Medium" }
                    Button("High Risks") { selectedRisk = "High" }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedRisk)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 8))
                    }
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(6)
                }
                .menuStyle(.borderlessButton)
                
                Menu {
                    Button("All Categories") { selectedCategory = "All Categories" }
                    Button("System") { selectedCategory = "System" }
                    Button("Applications") { selectedCategory = "Applications" }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedCategory)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 8))
                    }
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(6)
                }
                .menuStyle(.borderlessButton)
                
                Button {
                    isSafeOptimizeSelected = true
                } label: {
                    Text("Select All")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(AppTheme.cyan)
                }
                .buttonStyle(.plain)
            }
            
            // Row Safe Memory Optimize
            HStack(spacing: 12) {
                Button {
                    isSafeOptimizeSelected.toggle()
                } label: {
                    Image(systemName: isSafeOptimizeSelected ? "checkmark.square.fill" : "square")
                        .font(.system(size: 14))
                        .foregroundStyle(isSafeOptimizeSelected ? AppTheme.cyan : AppTheme.secondaryText)
                }
                .buttonStyle(.plain)
                
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(red: 0.2, green: 0.6, blue: 0.2).opacity(0.15))
                        .frame(width: 28, height: 28)
                    Image(systemName: "folder.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(Color(red: 0.3, green: 0.8, blue: 0.3))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Safe memory optimize")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                    Text("Captures before/after machine state and clears reusable caches.")
                        .font(.system(size: 10))
                        .foregroundStyle(AppTheme.secondaryText)
                }
                
                Spacer()
                
                Text("Safe")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(AppTheme.green)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(AppTheme.green.opacity(0.12))
                    .cornerRadius(4)
                
                Text("Zero KB")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppTheme.secondaryText)
                
                Button {
                    state.optimizeMemoryPreview()
                } label: {
                    Text("Optimize")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppTheme.cyan)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
                
                Button {
                    // Show info details
                } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.secondaryText)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.02))
            .cornerRadius(8)
            
            // Show More expander
            HStack {
                Spacer()
                Button {
                    // Show more logic
                } label: {
                    HStack(spacing: 4) {
                        Text("Show more")
                        Image(systemName: "chevron.down")
                            .font(.system(size: 8))
                    }
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
                }
                .buttonStyle(.plain)
                Spacer()
            }
            .padding(.top, 4)
        }
    }
}
