mod config;
mod engine;
mod handler;
mod keyboard;
mod state;

use config::{get_layout_path, load_layout};
use handler::handle_event;
use rdev::{grab, Event};
use state::GlobalState;

lazy_static::lazy_static! {
    static ref GLOBAL_STATE: GlobalState = GlobalState::new();
    static ref LAYOUT: config::Layout = load_layout();
}

fn main() {
    println!("--- OpenLipi: Keyboard Layout Engine ---");
    println!("Status: ACTIVE (Press F10 to Toggle ON/OFF)");
    println!("Layout: {}", get_layout_path());
    println!("\nListening for keyboard events...\n");

    if let Err(e) = grab(callback) {
        eprintln!("Error: {:?}", e);
    }
}

fn callback(event: Event) -> Option<Event> {
    handle_event(event, &GLOBAL_STATE, &LAYOUT)
}