import AppKit
import CleanMacCore
import SwiftUI

struct AppIconView: View {
    var bundleID: String
    
    var body: some View {
        if let icon = getAppIcon(bundleID: bundleID) {
            Image(nsImage: icon)
                .resizable()
                .scaledToFit()
        } else {
            Image(systemName: "app.dashed")
                .resizable()
                .scaledToFit()
                .foregroundStyle(AppTheme.secondaryText.opacity(0.5))
        }
    }

    private func getAppIcon(bundleID: String) -> NSImage? {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            return nil
        }
        return NSWorkspace.shared.icon(forFile: url.path)
    }
}
