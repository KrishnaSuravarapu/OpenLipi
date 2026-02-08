# OpenLipi Source Code Structure

This directory contains the core Rust implementation of the OpenLipi keyboard layout engine.

## Module Organization

### `main.rs`
- Entry point of the application
- Initializes global state and layout configuration
- Sets up the keyboard event grabbing loop

### `config.rs`
- Layout configuration management
- Handles loading layouts from JSON files
- Supports multiple configuration sources (CLI args, env vars, config file)

### `keyboard.rs`
- Keyboard event utilities
- Key-to-string mapping
- Modifier key handling and state tracking

### `engine.rs`
- Core typing engine implementation
- Character mapping and transformation
- Matra (vowel diacritic) application logic for Indic scripts

### `handler.rs`
- Event processing pipeline
- Coordinates keyboard events with the typing engine
- Manages event suppression and passthrough

### `state.rs`
- Global state management
- Thread-safe state containers using Mutex and AtomicBool
- Tracks shift/modifier state, last character, injection status

## Key Design Patterns

### Thread Safety
All shared state is protected using `Mutex` or `AtomicBool` to ensure safe concurrent access from the event loop.

### Event Flow
1. Keyboard event captured by `rdev::grab()`
2. Event passed to `handler::handle_event()`
3. Handler checks state and delegates to `engine::TypingEngine`
4. Engine performs character transformation and text injection
5. Event is either suppressed (None) or passed through (Some)

### Layout System
Layouts are JSON-based with the following structure:
- `mappings`: Key → Character mappings
- `special_rules`: Custom transformation rules
- `consonants`: Set of consonant characters (for Indic scripts)
- `matra_map`: Vowel → Diacritic mappings (for Indic scripts)

## Adding New Features

### Adding a New Layout Field
1. Update the `Layout` struct in `config.rs`
2. Update the schema documentation in `docs/schema/layout.json`
3. Implement handling logic in `engine.rs`

### Adding a New Keyboard Feature
1. Add the feature logic to `engine.rs`
2. Update `handler.rs` if special event handling is needed
3. Update state management in `state.rs` if new global state is required
