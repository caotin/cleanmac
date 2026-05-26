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

---

## Releasing to GitHub

To release the application so other users can download and use the `.dmg`, follow these steps:

### Step 1: Version and Tag the Release

Create a semantic git tag for your release (replace `v1.0.0` with your target version) and push it to GitHub:

```bash
# Tag the current commit
git tag -a v1.0.0 -m "Release version 1.0.0"

# Push the tag to your origin remote
git push origin v1.0.0
```

### Step 2: Build the Production DMG

Run the build script to generate the latest installer package:

```bash
./build_dmg.sh
```

### Step 3: Create the Release on GitHub

You can publish the release either through the web browser or using the GitHub CLI:

#### Option A: Via the GitHub Web UI
1. Go to your repository on [GitHub](https://github.com).
2. On the right-side panel, click on **Releases** -> **Draft a new release**.
3. Choose the tag you just pushed (`v1.0.0`).
4. Enter a release title (e.g., `CleanMac v1.0.0`).
5. Write your release notes (e.g., highlighting new features and improvements).
6. **Important**: Drag and drop the generated `build/CleanMac.dmg` into the *Attach binaries by dropping them here* box.
7. Click **Publish release**.

#### Option B: Via GitHub CLI (`gh`)
If you have the `gh` command-line tool installed, run:

```bash
gh release create v1.0.0 build/CleanMac.dmg \
  --title "CleanMac v1.0.0" \
  --notes "Initial public release of CleanMac featuring dashboard diagnostics, Memory optimization, node_modules scanner, and Docker cleanups."
```

Users can now download `CleanMac.dmg` from the GitHub Releases section and run it natively on their Macs!

---

## License

This project is open-source and available under the MIT License.
