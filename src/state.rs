use crate::keyboard::ModifierState;
use rdev::Key;
use std::collections::HashSet;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Mutex;
use std::time::Instant;

/// Global state management for the keyboard engine
pub struct GlobalState {
    shift_pressed: Mutex<bool>,
    mapping_enabled: Mutex<bool>,
    last_inject: Mutex<Option<Instant>>,
    suppressed_keys: Mutex<HashSet<Key>>,
    modifiers: Mutex<ModifierState>,
    last_char: Mutex<Option<String>>,
    injecting: AtomicBool,
}

impl GlobalState {
    pub fn new() -> Self {
        Self {
            shift_pressed: Mutex::new(false),
            mapping_enabled: Mutex::new(true),
            last_inject: Mutex::new(None),
            suppressed_keys: Mutex::new(HashSet::new()),
            modifiers: Mutex::new(ModifierState {
                meta: false,
                alt: false,
                ctrl: false,
            }),
            last_char: Mutex::new(None),
            injecting: AtomicBool::new(false),
        }
    }

    pub fn is_shift_pressed(&self) -> bool {
        *self.shift_pressed.lock().unwrap()
    }

    pub fn set_shift_pressed(&self, pressed: bool) {
        *self.shift_pressed.lock().unwrap() = pressed;
    }

    pub fn is_mapping_enabled(&self) -> bool {
        *self.mapping_enabled.lock().unwrap()
    }

    pub fn toggle_mapping(&self) -> bool {
        let mut enabled = self.mapping_enabled.lock().unwrap();
        *enabled = !*enabled;
        *enabled
    }

    pub fn is_injecting(&self) -> bool {
        self.injecting.load(Ordering::Relaxed)
    }

    pub fn set_injecting(&self, value: bool) {
        self.injecting.store(value, Ordering::Relaxed);
    }

    pub fn set_last_inject(&self, time: Instant) {
        *self.last_inject.lock().unwrap() = Some(time);
    }

    pub fn get_last_inject(&self) -> Option<Instant> {
        *self.last_inject.lock().unwrap()
    }

    pub fn suppress_key(&self, key: Key) {
        self.suppressed_keys.lock().unwrap().insert(key);
    }

    pub fn remove_suppressed_key(&self, key: Key) -> bool {
        self.suppressed_keys.lock().unwrap().remove(&key)
    }

    pub fn update_modifier(&self, key: Key, pressed: bool) {
        self.modifiers.lock().unwrap().update(key, pressed);
    }

    pub fn are_modifiers_active(&self) -> bool {
        self.modifiers.lock().unwrap().is_active()
    }

    pub fn get_last_char(&self) -> Option<String> {
        self.last_char.lock().unwrap().clone()
    }

    pub fn set_last_char(&self, ch: Option<String>) {
        *self.last_char.lock().unwrap() = ch;
    }
}
