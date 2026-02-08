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

# Copy Info.plist
cp "$MACOS_DIR/Info.plist" "$CONTENTS_DIR/Info.plist"

echo "App built at: $APP_DIR"

cat <<EOF

Next steps:
1) Open System Settings → Privacy & Security → Accessibility, add $APP_NAME.app.
2) Run the app from $APP_DIR.
3) Use the menu bar to select layouts.
EOF