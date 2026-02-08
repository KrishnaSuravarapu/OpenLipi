# OpenLipi macOS Menu Bar App

A native macOS menu bar application for managing the OpenLipi keyboard layout engine.

## Architecture

The app is structured using a clean separation of concerns:

### Main Components

#### `AppDelegate`
- Application lifecycle management
- Coordinates between managers
- Sets up menu and UI

#### `EngineManager`
- Manages the OpenLipi binary process
- Monitors engine status and output
- Handles pause/resume functionality
- Sends F10 events for toggle control

#### `LayoutManager`
- Discovers and presents available layouts
- Manages layout selection
- Handles custom binary and layout folder selection
- Persists user preferences via UserDefaults

#### `StatusBarManager`
- Updates menu bar icon and status
- Handles light/dark mode appearance
- Falls back to text-based status if icons unavailable
- Displays colored status indicator (green/gray)

## Key Features

### Auto-Start
The engine automatically starts when the app launches, using the last selected layout.

### Status Tracking
The app monitors the engine's stdout to detect when mapping is toggled (via F10), and updates the UI accordingly.

### Layout Discovery
Layouts are discovered by scanning the layouts directory hierarchy:
```
layouts/
  ├── telugu/
  │   └── apple.json
  └── hindi/
      └── phonetic.json
```

### Preference Storage
User preferences are stored using UserDefaults:
- `openlipi.binaryPath`: Custom binary location
- `openlipi.layoutsDir`: Custom layouts directory
- `openlipi.lastLayout`: Last selected layout file

### Bundled Resources
The app can bundle the OpenLipi binary and layouts inside the .app package:
- `Resources/bin/OpenLipi`: The binary
- `Resources/layouts/`: Layout files

## Building

Use the `build-mac.sh` script at the repo root:
```bash
./build-mac.sh
```

This will:
1. Build the Rust binary in release mode
2. Generate status icons (light/dark variants)
3. Compile the Swift app
4. Create the app bundle with all resources

The app will be available at `build-mac/OpenLipi.app`.

## Usage

1. Run the app: `open build-mac/OpenLipi.app`
2. The engine auto-starts with the last used layout
3. (Optional) Select custom binary via menu
4. (Optional) Choose different layouts folder
5. Select layout from the Layouts submenu
6. Use Pause/Resume to toggle mapping on/off

## Icon System

The app uses programmatically generated 22×22 PNG icons with four variants:
- `icon_on_light.png`: Active state for light mode
- `icon_on_dark.png`: Active state for dark mode
- `icon_off_light.png`: Paused state for light mode
- `icon_off_dark.png`: Paused state for dark mode

Icons feature:
- Telugu letter "ఱ" (Ra)
- Status dot (green when active, gray when paused)
- Transparent background with visible border
- Optimized for Retina displays

## Requirements

- macOS 10.15+
- Xcode Command Line Tools (for `swiftc`)
- Accessibility permissions for the app

## Development

### Testing
Test the app without rebuilding:
```bash
open build-mac/OpenLipi.app
```

### Debugging
Check Console.app for error messages from the app or engine process.

## Notes

- The app requires Accessibility permissions to function properly
- The build script bundles the Rust binary and layouts into the app
- User preferences are stored in macOS UserDefaults
- The app runs in the background (LSUIElement) without a dock icon
