#!/bin/bash
set -e

# CleanMac Packaging & DMG Build Script
# This script compiles the Swift PM target, builds a standard .app bundle,
# embeds resources, and outputs a double-clickable .dmg installer.

APP_NAME="CleanMac"
BUNDLE_IDENTIFIER="com.caotin.CleanMac"
VERSION="1.0.0"
BUILD_NUMBER="1"

echo "=========================================="
echo " Starting CleanMac Build & DMG Packaging"
echo "=========================================="

# 1. Clean previous build staging
echo "🧹 Cleaning old build files..."
rm -rf build

# 2. Compile the Swift project in release mode
echo "⚙️  Compiling project in release mode..."
swift build -c release

# Determine the binary paths
# Some system/swift setups might append host arch to bin path, swift build --show-bin-path handles this cleanly
BUILD_DIR=$(swift build -c release --show-bin-path)
echo "📂 Compiled binaries located in: $BUILD_DIR"

if [ ! -f "$BUILD_DIR/CleanMac" ]; then
    echo "❌ Error: Could not find CleanMac binary in $BUILD_DIR"
    exit 1
fi

# 3. Create .app structure
echo "📦 Creating CleanMac.app bundle structure..."
APP_BUNDLE="build/${APP_NAME}.app"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

# 4. Copy Binary
echo "💾 Copying executable binary..."
cp "$BUILD_DIR/CleanMac" "${APP_BUNDLE}/Contents/MacOS/CleanMac"
chmod +x "${APP_BUNDLE}/Contents/MacOS/CleanMac"

# 5. Copy Icon resources
echo "🎨 Copying app icon..."
if [ -f "Sources/CleanMacApp/Resources/CleanMac.icns" ]; then
    cp "Sources/CleanMacApp/Resources/CleanMac.icns" "${APP_BUNDLE}/Contents/Resources/"
else
    echo "⚠️  Warning: CleanMac.icns icon not found in Sources/CleanMacApp/Resources"
fi

# 6. Copy Resource bundle for SPM dependencies (Crucial for assets like images, scripts)
# Swift Package Manager bundles resource files under the target name + .bundle
SPM_BUNDLE_NAME="CleanMac_CleanMacApp.bundle"
if [ -d "$BUILD_DIR/$SPM_BUNDLE_NAME" ]; then
    echo "📦 Copying SPM resource bundle: $SPM_BUNDLE_NAME"
    cp -R "$BUILD_DIR/$SPM_BUNDLE_NAME" "${APP_BUNDLE}/Contents/Resources/"
else
    # Search recursively in the build folder in case it is nested
    FOUND_BUNDLE=$(find "$BUILD_DIR" -name "$SPM_BUNDLE_NAME" -type d -print -quit)
    if [ -n "$FOUND_BUNDLE" ]; then
        echo "📦 Found and copying SPM resource bundle at: $FOUND_BUNDLE"
        cp -R "$FOUND_BUNDLE" "${APP_BUNDLE}/Contents/Resources/"
    else
        echo "⚠️  Warning: SPM resource bundle ($SPM_BUNDLE_NAME) not found. Dynamic resources might not load."
    fi
fi

# 7. Generate Info.plist
echo "📝 Generating Info.plist..."
cat <<EOF > "${APP_BUNDLE}/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>CleanMac</string>
    <key>CFBundleIconFile</key>
    <string>CleanMac.icns</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_IDENTIFIER}</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${BUILD_NUMBER}</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>LSUIElement</key>
    <false/>
</dict>
</plist>
EOF

# 8. Create DMG Disk Image
echo "💿 Packaging app into installer DMG..."
DMG_NAME="build/${APP_NAME}.dmg"
TMP_DMG="build/${APP_NAME}_tmp.dmg"
DMG_STAGE="build/dmg_stage"

mkdir -p "$DMG_STAGE"
cp -R "$APP_BUNDLE" "$DMG_STAGE/"

# Create symlink to /Applications inside the DMG so users can drag & drop
ln -s /Applications "$DMG_STAGE/Applications"

echo "   Creating raw read-write DMG disk image..."
hdiutil create -srcfolder "$DMG_STAGE" -volname "$APP_NAME" -format UDRW "$TMP_DMG" -quiet

echo "   Converting to compressed read-only DMG disk image..."
hdiutil convert "$TMP_DMG" -format UDZO -imagekey zlib-level=9 -o "$DMG_NAME" -quiet

# Cleanup temporary files
rm -f "$TMP_DMG"
rm -rf "$DMG_STAGE"

echo "=========================================="
echo " Success! CleanMac DMG is ready."
echo " Location: $DMG_NAME"
echo "=========================================="
