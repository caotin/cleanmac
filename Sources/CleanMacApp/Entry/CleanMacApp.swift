import AppKit
import SwiftUI

@main
enum CleanMacApp {
    @MainActor private static var state: AppState?
    @MainActor private static var window: NSWindow?

    @MainActor
    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.regular)
        app.finishLaunching()
        AppIconInstaller.install()

        let state = AppState()
        self.state = state

        installMenu(state: state)

        let rootView = RootView()
            .environmentObject(state)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1180, height: 760),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "CleanMac"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 1180, height: 760)
        window.center()
        window.contentView = NSHostingView(rootView: rootView)
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        self.window = window

        app.activate(ignoringOtherApps: true)

        Task {
            await state.bootstrap()
        }

        app.run()
    }

    @MainActor
    private static func installMenu(state: AppState) {
        let handler = MenuHandler(state: state)
        MenuHandler.shared = handler

        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)

        let appMenu = NSMenu()
        appMenu.addItem(NSMenuItem(title: "Settings...", action: #selector(MenuHandler.openSettings), keyEquivalent: ","))
        appMenu.items.first?.target = handler
        appMenu.addItem(.separator())
        appMenu.addItem(NSMenuItem(title: "Quit CleanMac", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        appMenuItem.submenu = appMenu

        NSApplication.shared.mainMenu = mainMenu
    }
}

@MainActor
private final class MenuHandler: NSObject {
    static var shared: MenuHandler?
    private let state: AppState

    init(state: AppState) {
        self.state = state
    }

    @objc func openSettings() {
        state.section = .settings
    }
}
