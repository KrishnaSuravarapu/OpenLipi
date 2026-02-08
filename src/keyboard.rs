use rdev::Key;

/// Maps rdev::Key to its string representation
pub fn get_key_name(key: Key) -> Option<String> {
    match key {
        // Letter keys
        Key::KeyA => Some("a".into()),
        Key::KeyB => Some("b".into()),
        Key::KeyC => Some("c".into()),
        Key::KeyD => Some("d".into()),
        Key::KeyE => Some("e".into()),
        Key::KeyF => Some("f".into()),
        Key::KeyG => Some("g".into()),
        Key::KeyH => Some("h".into()),
        Key::KeyI => Some("i".into()),
        Key::KeyJ => Some("j".into()),
        Key::KeyK => Some("k".into()),
        Key::KeyL => Some("l".into()),
        Key::KeyM => Some("m".into()),
        Key::KeyN => Some("n".into()),
        Key::KeyO => Some("o".into()),
        Key::KeyP => Some("p".into()),
        Key::KeyQ => Some("q".into()),
        Key::KeyR => Some("r".into()),
        Key::KeyS => Some("s".into()),
        Key::KeyT => Some("t".into()),
        Key::KeyU => Some("u".into()),
        Key::KeyV => Some("v".into()),
        Key::KeyW => Some("w".into()),
        Key::KeyX => Some("x".into()),
        Key::KeyY => Some("y".into()),
        Key::KeyZ => Some("z".into()),

        // Number keys
        Key::Num0 => Some("0".into()),
        Key::Num1 => Some("1".into()),
        Key::Num2 => Some("2".into()),
        Key::Num3 => Some("3".into()),
        Key::Num4 => Some("4".into()),
        Key::Num5 => Some("5".into()),
        Key::Num6 => Some("6".into()),
        Key::Num7 => Some("7".into()),
        Key::Num8 => Some("8".into()),
        Key::Num9 => Some("9".into()),

        // Punctuation and symbols
        Key::SemiColon => Some(";".into()),
        Key::Quote => Some("'".into()),
        Key::LeftBracket => Some("[".into()),
        Key::RightBracket => Some("]".into()),
        Key::Comma => Some(",".into()),
        Key::Dot => Some(".".into()),
        Key::Slash => Some("/".into()),
        Key::BackSlash => Some("\\".into()),

        _ => None,
    }
}

/// Checks if the key is a shift key
pub fn is_shift(key: Key) -> bool {
    matches!(key, Key::ShiftLeft | Key::ShiftRight)
}

/// Checks if the key is a non-shift modifier
pub fn is_modifier_non_shift(key: Key) -> bool {
    matches!(
        key,
        Key::MetaLeft | Key::MetaRight | Key::Alt | Key::AltGr | Key::ControlLeft | Key::ControlRight
    )
}

#[derive(Default)]
pub struct ModifierState {
    pub meta: bool,
    pub alt: bool,
    pub ctrl: bool,
}

impl ModifierState {
    /// Updates modifier state based on key press/release
    pub fn update(&mut self, key: Key, pressed: bool) {
        match key {
            Key::MetaLeft | Key::MetaRight => self.meta = pressed,
            Key::Alt | Key::AltGr => self.alt = pressed,
            Key::ControlLeft | Key::ControlRight => self.ctrl = pressed,
            _ => (),
        }
    }

    /// Returns true if any modifier is currently pressed
    pub fn is_active(&self) -> bool {
        self.meta || self.alt || self.ctrl
    }
}
