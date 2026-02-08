
use enigo::{Enigo, Keyboard, Settings, Direction};
use rdev::{listen, Event, EventType, Key};
use serde::Deserialize;
use std::collections::HashMap;
use std::fs;
use std::sync::Mutex;

#[derive(Deserialize)]
struct Layout {
    mappings: HashMap<String, String>,
    special_rules: HashMap<String, String>,
}

lazy_static::lazy_static! {
    static ref ENIGO: Mutex<Enigo> = Mutex::new(Enigo::new(&Settings::default()).unwrap());
    static ref SHIFT_PRESSED: Mutex<bool> = Mutex::new(false);
    static ref CONFIG: Layout = {
        let data = fs::read_to_string("layouts/telugu/apple.json")
            .expect("Unable to read layout file");
        serde_json::from_str(&data).expect("JSON was not well-formatted")
    };
}

fn main() {
    println!("LipiBridge active using layout: Apple Telugu");
    if let Err(e) = listen(callback) { println!("Error: {:?}", e); }
}

fn callback(event: Event) {
    match event.event_type {
        EventType::KeyPress(key) => {
            if is_shift(key) { *SHIFT_PRESSED.lock().unwrap() = true; }
            else { handle_typing(key); }
        }
        EventType::KeyRelease(key) => {
            if is_shift(key) { *SHIFT_PRESSED.lock().unwrap() = false; }
        }
        _ => (),
    }
}

fn handle_typing(key: Key) {
    let shifted = *SHIFT_PRESSED.lock().unwrap();
    let mut enigo = ENIGO.lock().unwrap();

    if let Some(key_id) = get_key_name(key) {
        // 1. Check Special Rules (e.g., 'f' for Virama, no backspace)
        if let Some(rule_char) = CONFIG.special_rules.get(&key_id) {
            let _ = enigo.text(rule_char);
            return;
        }

        // 2. Standard Mappings (requires backspacing the original English char)
        let lookup_key = if shifted { key_id.to_uppercase() } else { key_id };
        if let Some(telugu_char) = CONFIG.mappings.get(&lookup_key) {
            let _ = enigo.key(enigo::Key::Backspace, Direction::Click);
            let _ = enigo.text(telugu_char);
        }
    }
}

fn is_shift(key: Key) -> bool { matches!(key, Key::ShiftLeft | Key::ShiftRight) }

fn get_key_name(key: Key) -> Option<String> {
    match key {
        Key::KeyA => Some("a".into()), Key::KeyS => Some("s".into()),
        Key::KeyD => Some("d".into()), Key::KeyF => Some("f".into()),
        Key::KeyG => Some("g".into()), Key::KeyJ => Some("j".into()),
        // Add all keys from your mapping here...
        _ => None,
    }
}
