use crate::config::Layout;
use enigo::{Enigo, Keyboard, Settings};
use std::cell::RefCell;

thread_local! {
    static ENIGO: RefCell<Enigo> = RefCell::new(
        Enigo::new(&Settings::default()).expect("Could not initialize Enigo")
    );
}

pub struct TypingEngine;

impl TypingEngine {
    /// Injects text using the Enigo library
    pub fn inject_text(text: &str) {
        ENIGO.with(|enigo_cell| {
            let mut enigo = enigo_cell.borrow_mut();
            let _ = enigo.text(text);
        });
    }

    /// Handles character mapping and matra application
    pub fn process_key(
        key_id: &str,
        shifted: bool,
        last_char: &Option<String>,
        config: &Layout,
    ) -> (bool, Option<String>) {
        // Check for special rules first
        if let Some(rule_char) = Self::get_special_rule(key_id, config) {
            Self::inject_text(rule_char);
            return (true, Some(rule_char.to_string()));
        }

        // Standard mappings
        let lookup_key = if shifted {
            key_id.to_uppercase()
        } else {
            key_id.to_string()
        };

        if let Some(output_char) = config.mappings.get(&lookup_key) {
            // Check for matra application
            if let Some(last) = last_char {
                if let Some(matra) = Self::try_apply_matra(last, output_char, config) {
                    Self::inject_text(matra);
                    return (true, Some(format!("{}{}", last, matra)));
                }
            }

            // Regular character mapping
            Self::inject_text(output_char);
            return (true, Some(output_char.clone()));
        }

        (false, None)
    }

    /// Attempts to apply a matra if conditions are met
    fn try_apply_matra<'a>(last_char: &str, current_char: &str, config: &'a Layout) -> Option<&'a String> {
        if let (Some(consonants), Some(matra_map)) = (&config.consonants, &config.matra_map) {
            if consonants.contains(last_char) {
                return matra_map.get(current_char);
            }
        }
        None
    }

    /// Gets special rule character if exists
    fn get_special_rule<'a>(key: &str, config: &'a Layout) -> Option<&'a String> {
        config
            .special_rules
            .as_ref()
            .and_then(|rules| rules.get(key))
    }
}
