# OpenLipi

A keyboard layout engine for Indian languages with support for complex script features like matras (vowel diacritics) and special character rules.

## Features

- 🎯 Phonetic keyboard layouts for Indian languages
- 🔄 Automatic matra (vowel diacritic) application for Indic scripts
- ⚡ Real-time character transformation
- 🎛️ Toggle mapping on/off with F10
- 🍎 Native macOS menu bar app
- 🔧 Extensible JSON-based layout system
- 🌍 Easy to add new languages

## Quick Start

### Using the CLI

```bash
# Build and run with default Telugu layout
cargo run --release

# Use a specific layout
cargo run --release -- --layout layouts/telugu/apple.json

# Or set environment variable
export OPENLIPI_LAYOUT=layouts/telugu/apple.json
cargo run --release
```

### Using the macOS App

```bash
# Build the menu bar app (includes icons and bundled resources)
./build-mac.sh

# Run the app
open build-mac/OpenLipi.app
```

**Note**: Grant Accessibility permissions when prompted for the keyboard engine to work.

## Project Structure

```
OpenLipi/
├── src/                    # Rust keyboard engine (modular architecture)
│   ├── main.rs            # Entry point
│   ├── config.rs          # Layout loading & configuration
│   ├── keyboard.rs        # Key mapping utilities
│   ├── engine.rs          # Core typing engine
│   ├── handler.rs         # Event processing
│   ├── state.rs           # Global state management
│   └── README.md          # Detailed module documentation
├── macos-app/             # Native macOS menu bar application
│   ├── OpenLipiMenuBar.swift  # Menu bar app (4 manager classes)
│   ├── make_icons.swift   # Icon generation
│   └── README.md          # macOS app architecture
├── layouts/               # Language layout definitions
│   └── telugu/
│       └── apple.json     # Telugu phonetic layout
├── docs/
│   └── schema/            # Layout JSON schema documentation
├── build-mac.sh           # macOS app build script
├── Cargo.toml             # Rust project configuration
├── LICENSE                # MIT License
└── CONTRIBUTING.md        # Contribution guidelines
```

See individual README files in `src/` and `macos-app/` directories for detailed component documentation.

## Layout Configuration

### Priority Order
1. `--layout <path>` command line argument
2. `OPENLIPI_LAYOUT` environment variable
3. `config.json` file (copy from `config.json.example`)
4. Default: `layouts/telugu/apple.json`

### Layout Format

Layouts are JSON files with the following structure:

```json
{
  "layout_name": "Telugu Apple",
  "mappings": {
    "a": "అ",
    "k": "క"
  },
  "consonants": ["క", "గ", "చ"],
  "matra_map": {
    "అ": "ా",
    "ఇ": "ి"
  },
  "special_rules": {
    "f": "్"
  }
}
```

**Required fields:**
- `layout_name` - Display name
- `mappings` - Key → character mappings

**Optional fields:**
- `consonants` - Set of consonant characters (for matra application)
- `matra_map` - Vowel → diacritic mappings (for Indic scripts)
- `special_rules` - Custom transformation rules

See [docs/schema/layout.json](docs/schema/layout.json) for the complete schema.

## Adding a New Language

1. Create a layout file: `layouts/<language>/<variant>.json`
2. Define mappings for your keyboard layout
3. (Optional) Add consonants and matra_map for Indic scripts
4. Test: `cargo run -- --layout layouts/<language>/<variant>.json`

Example layouts are in the `layouts/` directory.

## Development

### Building

```bash
# Rust engine only
cargo build --release

# macOS app (includes Rust binary)
./build-mac.sh
```

### Requirements

- Rust 1.70+ (for the engine)
- macOS 10.15+ with Xcode Command Line Tools (for menu bar app)
- Accessibility permissions on macOS

### Architecture

OpenLipi uses a modular architecture:

- **Rust Engine**: Multi-module design with clear separation of concerns (config, keyboard handling, typing engine, event processing, state management)
- **macOS App**: Manager-based architecture with separate classes for engine, layout, and status bar management
- **Layout System**: JSON-based with schema validation and flexible field support

## Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT License - see [LICENSE](LICENSE) for details.

## Author

Krishna Suravarapu
