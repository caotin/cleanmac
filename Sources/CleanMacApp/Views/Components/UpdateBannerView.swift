import AppKit
import SwiftUI

struct UpdateBannerView: View {
    let info: UpdateInfo
    let onUpdate: () -> Void
    let onDismiss: () -> Void

    @State private var isHovered = false
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main row
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.1, green: 0.55, blue: 1.0).opacity(0.35),
                                    Color(red: 0.05, green: 0.38, blue: 0.9).opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                    Circle()
                        .stroke(Color(red: 0.25, green: 0.65, blue: 1.0).opacity(0.5), lineWidth: 1)
                        .frame(width: 36, height: 36)
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color(red: 0.4, green: 0.78, blue: 1.0))
                }

                // Text content
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("Update Available")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                        Text("v\(info.latestVersion)")
                            .font(.system(size: 11, weight: .bold))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(Color(red: 0.1, green: 0.5, blue: 1.0).opacity(0.3))
                            .foregroundStyle(Color(red: 0.4, green: 0.78, blue: 1.0))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color(red: 0.25, green: 0.65, blue: 1.0).opacity(0.4), lineWidth: 1))
                    }
                    Text("A new version of CleanMac is ready to download.")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.white.opacity(0.55))
                }

                Spacer()

                // Expand release notes toggle (only if notes exist)
                if !info.releaseNotes.isEmpty {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isExpanded.toggle()
                        }
                    } label: {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.white.opacity(0.45))
                            .frame(width: 22, height: 22)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }

                // Action Buttons
                Button {
                    onDismiss()
                } label: {
                    Text("Later")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.5))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.1), lineWidth: 1))
                }
                .buttonStyle(.plain)

                Button {
                    onUpdate()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "arrow.down.circle")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Update Now")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 0.15, green: 0.5, blue: 1.0),
                                Color(red: 0.05, green: 0.35, blue: 0.85)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(8)
                    .shadow(color: Color(red: 0.1, green: 0.45, blue: 1.0).opacity(0.4), radius: 8, y: 3)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            // Expandable release notes
            if isExpanded && !info.releaseNotes.isEmpty {
                Divider()
                    .background(Color.white.opacity(0.08))
                    .padding(.horizontal, 16)

                ScrollView {
                    Text(info.releaseNotes)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.65))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                }
                .frame(maxHeight: 120)
            }
        }
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.06, green: 0.14, blue: 0.28).opacity(0.95),
                                Color(red: 0.04, green: 0.10, blue: 0.22).opacity(0.95)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(red: 0.25, green: 0.65, blue: 1.0).opacity(0.5),
                                Color(red: 0.1, green: 0.4, blue: 0.9).opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .shadow(color: Color(red: 0.1, green: 0.4, blue: 1.0).opacity(isHovered ? 0.25 : 0.12), radius: 16, y: 6)
        .scaleEffect(isHovered ? 1.002 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
