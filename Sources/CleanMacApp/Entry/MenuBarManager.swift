import AppKit
import SwiftUI

@MainActor
final class MenuBarManager: NSObject, NSMenuDelegate {
    private let state: AppState
    private var statusItem: NSStatusItem?
    private var statusMenuItem: NSMenuItem?
    private var quickCleanMenuItem: NSMenuItem?
    private var updateMenuItem: NSMenuItem?

    init(state: AppState) {
        self.state = state
        super.init()
        setupMenuBar()
    }

    private func setupMenuBar() {
        // Create a status item with a variable length in the system menu bar
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.statusItem = statusItem

        if let button = statusItem.button {
            // Configure the menu bar button with a native template icon
            if let image = NSImage(systemSymbolName: "sparkles", accessibilityDescription: "CleanMac") {
                button.image = image
            }
        }

        // Create the dropdown menu
        let menu = NSMenu()
        menu.delegate = self

        // 1. Title Item (Header)
        let headerItem = NSMenuItem(title: "CleanMac", action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        menu.addItem(headerItem)

        // 2. Status message item
        let statusItemEntry = NSMenuItem(title: "Status: Ready", action: nil, keyEquivalent: "")
        statusItemEntry.isEnabled = false
        self.statusMenuItem = statusItemEntry
        menu.addItem(statusItemEntry)

        menu.addItem(NSMenuItem.separator())

        // 3. Quick Clean item
        let quickCleanItem = NSMenuItem(
            title: "Quick Clean",
            action: #selector(runQuickClean),
            keyEquivalent: ""
        )
        quickCleanItem.target = self
        self.quickCleanMenuItem = quickCleanItem
        menu.addItem(quickCleanItem)

        // 4. Update Available item (hidden by default)
        let updateItem = NSMenuItem(
            title: "Update Available",
            action: #selector(openUpdatePage),
            keyEquivalent: ""
        )
        updateItem.target = self
        updateItem.isHidden = true
        self.updateMenuItem = updateItem
        menu.addItem(updateItem)

        menu.addItem(NSMenuItem.separator())

        // 5. Open CleanMac item
        let openAppItem = NSMenuItem(
            title: "Open CleanMac",
            action: #selector(openMainApp),
            keyEquivalent: ""
        )
        openAppItem.target = self
        menu.addItem(openAppItem)

        // 5. Open Settings item
        let openSettingsItem = NSMenuItem(
            title: "Settings...",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        openSettingsItem.target = self
        menu.addItem(openSettingsItem)

        menu.addItem(NSMenuItem.separator())

        // 6. Quit item
        let quitItem = NSMenuItem(
            title: "Quit CleanMac",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    // MARK: - NSMenuDelegate

    func menuNeedsUpdate(_ menu: NSMenu) {
        updateMenuState()
    }

    private func updateMenuState() {
        // Update the status description
        statusMenuItem?.title = "Status: \(state.statusMessage)"

        // Show/hide update available menu item
        if let info = state.updateInfo {
            updateMenuItem?.title = "⬆︎ Update Available (v\(info.latestVersion))"
            updateMenuItem?.isHidden = false
        } else {
            updateMenuItem?.isHidden = true
        }

        // Enable or disable Quick Clean based on the application state
        if state.isRunningQuickClean {
            quickCleanMenuItem?.title = "Quick Clean (Running...)"
            quickCleanMenuItem?.isEnabled = false
        } else if !state.canRunQuickClean {
            quickCleanMenuItem?.title = "Quick Clean (Busy)"
            quickCleanMenuItem?.isEnabled = false
        } else {
            quickCleanMenuItem?.title = "Quick Clean"
            quickCleanMenuItem?.isEnabled = true
        }
    }

    // MARK: - Actions

    @objc private func runQuickClean() {
        Task {
            await state.quickClean()
        }
    }

    @objc private func openUpdatePage() {
        if let url = state.updateInfo?.releasePageURL {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func openMainApp() {
        CleanMacApp.showWindow()
    }

    @objc private func openSettings() {
        state.section = .settings
        CleanMacApp.showWindow()
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
