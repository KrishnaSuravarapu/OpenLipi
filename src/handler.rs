use crate::config::Layout;
use crate::engine::TypingEngine;
use crate::keyboard::{get_key_name, is_modifier_non_shift, is_shift};
use crate::state::GlobalState;
use rdev::{Event, EventType, Key};
use std::time::{Duration, Instant};

const DEBOUNCE_MS: u64 = 50;

/// Main event handler for keyboard events
pub fn handle_event(event: Event, state: &GlobalState, config: &Layout) -> Option<Event> {
    // Skip if we're currently injecting text
    if state.is_injecting() {
        return Some(event);
    }

    // Debounce recent injections
    if let Some(ts) = state.get_last_inject() {
        if ts.elapsed() < Duration::from_millis(DEBOUNCE_MS) {
            return Some(event);
        }
    }

    match event.event_type {
        EventType::KeyPress(key) => handle_key_press(key, event.name, state, config),
        EventType::KeyRelease(key) => handle_key_release(key, state),
        _ => Some(event),
    }
}

fn handle_key_press(
    key: Key,
    name: Option<String>,
    state: &GlobalState,
    config: &Layout,
) -> Option<Event> {
    // Handle toggle key (F10)
    if key == Key::F10 {
        let enabled = state.toggle_mapping();
        println!("Lipi Mapping: {}", if enabled { "ON" } else { "OFF" });
        return None;
    }

    // Handle modifiers
    if is_modifier_non_shift(key) {
        state.update_modifier(key, true);
        return Some(Event {
            event_type: EventType::KeyPress(key),
            time: std::time::SystemTime::now(),
            name: name.clone(),
        });
    }

    if is_shift(key) {
        state.set_shift_pressed(true);
        return Some(Event {
            event_type: EventType::KeyPress(key),
            time: std::time::SystemTime::now(),
            name: name.clone(),
        });
    }

    // Skip processing if modifiers are active
    if state.are_modifiers_active() {
        return Some(Event {
            event_type: EventType::KeyPress(key),
            time: std::time::SystemTime::now(),
            name: name.clone(),
        });
    }

    // Only process if mapping is enabled
    if !state.is_mapping_enabled() {
        return Some(Event {
            event_type: EventType::KeyPress(key),
            time: std::time::SystemTime::now(),
            name: name.clone(),
        });
    }

    // Process typing
    if process_typing(key, name.clone(), state, config) {
        state.suppress_key(key);
        return None;
    }

    Some(Event {
        event_type: EventType::KeyPress(key),
        time: std::time::SystemTime::now(),
        name,
    })
}

fn handle_key_release(key: Key, state: &GlobalState) -> Option<Event> {
    if is_shift(key) {
        state.set_shift_pressed(false);
        return Some(Event {
            event_type: EventType::KeyRelease(key),
            time: std::time::SystemTime::now(),
            name: None,
        });
    }

    if is_modifier_non_shift(key) {
        state.update_modifier(key, false);
        return Some(Event {
            event_type: EventType::KeyRelease(key),
            time: std::time::SystemTime::now(),
            name: None,
        });
    }

    if state.remove_suppressed_key(key) {
        return None;
    }

    Some(Event {
        event_type: EventType::KeyRelease(key),
        time: std::time::SystemTime::now(),
        name: None,
    })
}

fn process_typing(
    key: Key,
    name: Option<String>,
    state: &GlobalState,
    config: &Layout,
) -> bool {
    let key_id = match name {
        Some(n) if !n.is_empty() => n,
        _ => match get_key_name(key) {
            Some(n) => n,
            None => return false,
        },
    };

    let shifted = state.is_shift_pressed();
    let last_char = state.get_last_char();

    state.set_injecting(true);
    state.set_last_inject(Instant::now());

    let (handled, new_char) = TypingEngine::process_key(&key_id, shifted, &last_char, config);

    state.set_injecting(false);

    if handled {
        state.set_last_char(new_char);
        return true;
    } else {
        state.set_last_char(Some(key_id));
    }

    false
}
