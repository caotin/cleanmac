# CleanMac 🧹💻

A native, lightweight, and modern macOS utility designed specifically for developers to monitor system health, optimize memory, and safely clean up bulky workspaces—such as orphaned `node_modules` folders and unused Docker resources.

Built with **SwiftUI** and **AppKit** for high performance, native look-and-feel, and deep system integrations.

![CleanMac App Screenshot](screenshot.png)

---

## Key Features

- **🏠 Current Machine Dashboard**: Real-time diagnostic overview of your Mac, including chip model, memory pressure, disk usage, uptime, system temperatures, and Docker daemon status.
- **🧠 Memory Cleanup**: Dynamic, safe memory diagnostics and optimization to reclaim RAM when your Mac is under heavy load.
- **📦 Node Modules Cleanup**: Deep scans your projects to identify massive `node_modules` folders, categorizing them by size and last modified date for targeted cleanup.
- **🐋 Docker Cleanup**: Safely cleans stopped containers, unused images, dangling volumes, and build cache to reclaim gigabytes of disk space.
- **🛡️ Safety-First Approach**: All scans provide full interactive previews and require explicit confirmation before deleting files. All operations are logged.

---

## Requirements

- **Operating System**: macOS Sonoma (14.0) or higher.
- **Development Tools**: Xcode 15+ or Swift Command Line Tools (Swift 6.0+ recommended).

---

## Getting Started (Development)

Since CleanMac is fully organized as a **Swift Package Manager (SPM)** project, you can easily develop, test, and run it locally without Xcode or by opening the package in Xcode.

### Run via Command Line

To run the application in debug mode:

```bash
swift run
```

### Run Tests

To run the unit test suite:

```bash
swift test
```

---

## Building & Packaging (DMG)

We have automated the process of compiling the binary in release mode, bundling the resources (assets, icons), creating a macOS `.app` bundle, and packaging it into a double-clickable `.dmg` file.

### 1. Build the App and DMG Installer

Run the automated build script:

```bash
./build_dmg.sh
```

This script will:
1. Compile the project in release mode (`swift build -c release`).
2. Create the macOS bundle structure (`build/CleanMac.app`).
3. Embed the application icons and SPM resource bundle.
4. Output a compressed, read-only disk image at `build/CleanMac.dmg`.

### 2. Verify the Package

Once the script completes, open the output folder:

```bash
open build/
```

Double-click `CleanMac.dmg`, and drag **CleanMac** into your **Applications** folder to install it.


## Security & Gatekeeper Troubleshooting

Because CleanMac is an open-source tool and is not codesigned/notarized using a paid Apple Developer Account, macOS **Gatekeeper** will automatically quarantine the downloaded application and display a warning saying:
> **“CleanMac” is damaged and can’t be opened. You should move it to the Trash.**

To allow CleanMac to run on your Mac, you can manually strip the quarantine attribute using the Terminal.

### How to open CleanMac:
1. Drag **CleanMac** from the DMG to your **Applications** folder.
2. Open your **Terminal** app and run the following command:
   ```bash
   xattr -cr /Applications/CleanMac.app
   ```
3. Launch **CleanMac** from your Applications folder or Launchpad.

---

## License

This project is open-source and available under the MIT License.
