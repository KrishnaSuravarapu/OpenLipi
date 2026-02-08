use serde::Deserialize;
use std::collections::{HashMap, HashSet};
use std::env;
use std::fs;

#[derive(Deserialize)]
pub struct Layout {
    pub mappings: HashMap<String, String>,
    pub special_rules: Option<HashMap<String, String>>,
    pub consonants: Option<HashSet<String>>,
    pub matra_map: Option<HashMap<String, String>>,
}

#[derive(Deserialize, Default)]
struct AppConfig {
    layout_path: Option<String>,
}

/// Determines the layout file path from CLI args, env vars, or config file
pub fn get_layout_path() -> String {
    // Check CLI arguments first
    let args: Vec<String> = env::args().collect();
    let mut next_is_layout = false;
    for arg in args.iter().skip(1) {
        if next_is_layout {
            return arg.to_string();
        }
        if arg == "--layout" {
            next_is_layout = true;
            continue;
        }
        if let Some(value) = arg.strip_prefix("--layout=") {
            return value.to_string();
        }
    }

    // Check environment variable
    if let Ok(env_path) = env::var("OPENLIPI_LAYOUT") {
        if !env_path.trim().is_empty() {
            return env_path;
        }
    }

    // Check config.json
    if let Ok(cfg) = fs::read_to_string("config.json") {
        if let Ok(app_cfg) = serde_json::from_str::<AppConfig>(&cfg) {
            if let Some(path) = app_cfg.layout_path {
                return path;
            }
        }
    }

    // Default fallback
    "layouts/telugu/apple.json".to_string()
}

/// Loads the layout configuration from the determined path
pub fn load_layout() -> Layout {
    let path = get_layout_path();
    let data = fs::read_to_string(&path)
        .unwrap_or_else(|_| panic!("Unable to read layout file at {}", path));
    serde_json::from_str(&data).expect("JSON was not well-formatted")
}
