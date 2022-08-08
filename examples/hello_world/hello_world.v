// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module main

import solid

fn main() {
	mut app := &App{}
	config := solid.Config{}
	solid.run<App>(mut app, config)
}

[heap]
struct App {
mut:
	solid &solid.Solid = unsafe { nil } // Initialized by solid.run<T>(...)
}

pub fn (mut a App) init() {}

// TODO
[markused]
pub fn (mut a App) frame(dt f64) {
	mx, my := a.solid.mouse_position(.window)

	a.solid.scope(.open, .text_draw)
	mut text_draw := a.solid.text_draw()
	text_draw.text_at('Hello Solid World at $mx,$my', mx, my + 40)
	a.solid.scope(.close, .text_draw)
}

[markused]
pub fn (mut a App) fixed_update(dt f64) {}

[markused]
pub fn (mut a App) variable_update(dt f64) {}

// TODO
[markused]
pub fn (mut a App) event(e solid.Event) {
	match e {
		solid.QuitEvent {
			a.solid.shutdown = true
		}
		solid.KeyEvent {
			a.on_key_event(e)
		}
		else {
			// eprintln(@STRUCT + '.' + @FN + ' unhandled event $e')
		}
	}
}

// TODO
[markused]
pub fn (mut a App) quit() {}

pub fn (mut a App) on_key_event(e solid.KeyEvent) {
	key := e.key_code
	match e.state {
		.up {}
		.down {
			match key {
				.escape {
					a.solid.shutdown = true
				}
				else {
					eprintln('key down: $key')
				}
			}
		}
	}
}
