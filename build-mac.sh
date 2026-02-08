#!/usr/bin/env bash
set -euo pipefail

APP_NAME="OpenLipi"
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
MACOS_DIR="$ROOT_DIR/macos-app"
BUILD_DIR="$ROOT_DIR/build/mac"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
APP_MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
BIN_DIR="$RESOURCES_DIR/bin"
LAYOUTS_DIR="$RESOURCES_DIR/layouts"

mkdir -p "$APP_MACOS_DIR" "$RESOURCES_DIR" "$BIN_DIR" "$LAYOUTS_DIR"

# Build Rust binary (release)
cargo build --release --manifest-path "$ROOT_DIR/Cargo.toml"

# Bundle Rust binary
cp "$ROOT_DIR/target/release/OpenLipi" "$BIN_DIR/OpenLipi"
chmod +x "$BIN_DIR/OpenLipi"

# Bundle layouts
rm -rf "$LAYOUTS_DIR"
cp -R "$ROOT_DIR/layouts" "$LAYOUTS_DIR"

# Generate menu bar icons
# swiftc "$MACOS_DIR/make_icons.swift" -o "$MACOS_DIR/make_icons" -framework AppKit
# "$MACOS_DIR/make_icons" "$MACOS_DIR"
# rm -f "$MACOS_DIR/make_icons"

# Bundle icons
cp "$MACOS_DIR/icons/icon_on_light.png" "$RESOURCES_DIR/icon_on_light.png"
cp "$MACOS_DIR/icons/icon_off_light.png" "$RESOURCES_DIR/icon_off_light.png"
cp "$MACOS_DIR/icons/icon_on_dark.png" "$RESOURCES_DIR/icon_on_dark.png"
cp "$MACOS_DIR/icons/icon_off_dark.png" "$RESOURCES_DIR/icon_off_dark.png"

# Compile Swift source
swiftc -parse-as-library "$MACOS_DIR/OpenLipiMenuBar.swift" -o "$APP_MACOS_DIR/$APP_NAME" \
  -framework Cocoa

# Make executable
chmod +x "$APP_MACOS_DIR/$APP_NAME"

# Copy Info.plist
cp "$MACOS_DIR/Info.plist" "$CONTENTS_DIR/Info.plist"

# Code sign the app (ad-hoc signature to prevent "corrupted" error)
codesign --force --deep --sign - "$APP_DIR"

echo "App built at: $APP_DIR"

# Create DMG
echo ""
echo "📦 Creating DMG installer..."
VERSION="0.1.0"
DMG_NAME="${APP_NAME}-v${VERSION}-macos"
DMG_DIR="$BUILD_DIR/dmg"
FINAL_DMG="$BUILD_DIR/${DMG_NAME}.dmg"

# Clean up previous DMG builds
rm -rf "$DMG_DIR"
rm -f "$FINAL_DMG"

# Create DMG directory structure
mkdir -p "$DMG_DIR"
cp -R "$APP_DIR" "$DMG_DIR/"
ln -s /Applications "$DMG_DIR/Applications"

# Add README
cat > "$DMG_DIR/README.txt" << 'DMGEOF'
OpenLipi - Keyboard Layout Engine for Indian Languages

Installation:
1. Drag OpenLipi.app to the Applications folder
2. Open OpenLipi from Applications
3. Grant Accessibility permissions when prompted
4. Use the menu bar to select layouts

Requirements:
- macOS 10.15 or later
- Accessibility permissions

For more information, visit:
https://github.com/KrishnaSuravarapu/OpenLipi

DMGEOF

# Create temporary DMG
TEMP_DMG="$BUILD_DIR/temp-${DMG_NAME}.dmg"
hdiutil create -volname "$APP_NAME" \
    -srcfolder "$DMG_DIR" \
    -ov -format UDRW \
    "$TEMP_DMG" > /dev/null

# Mount and configure
MOUNT_DIR="/Volumes/$APP_NAME"
hdiutil attach "$TEMP_DMG" -readwrite -noverify -noautoopen > /dev/null 2>&1 || true
sleep 2

# Set DMG appearance
osascript > /dev/null 2>&1 <<APPLESCRIPT || true
tell application "Finder"
  tell disk "$APP_NAME"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set the bounds of container window to {100, 100, 600, 400}
    set viewOptions to the icon view options of container window
    set arrangement of viewOptions to not arranged
    set icon size of viewOptions to 100
    set position of item "$APP_NAME.app" of container window to {120, 120}
    set position of item "Applications" of container window to {380, 120}
    set position of item "README.txt" of container window to {250, 250}
    close
    open
    update without registering applications
    delay 2
  end tell
end tell
APPLESCRIPT

# Unmount and compress
sync
hdiutil detach "$MOUNT_DIR" > /dev/null 2>&1 || true
sleep 2

hdiutil convert "$TEMP_DMG" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -o "$FINAL_DMG" > /dev/null

# Clean up
rm -f "$TEMP_DMG"
rm -rf "$DMG_DIR"

DMG_SIZE=$(du -h "$FINAL_DMG" | cut -f1)
echo "✅ DMG created: $FINAL_DMG ($DMG_SIZE)"

cat <<EOF

Next steps:
1) Open System Settings → Privacy & Security → Accessibility, add $APP_NAME.app.
2) Run the app: open $APP_DIR
3) Or install from DMG: open $FINAL_DMG
EOF