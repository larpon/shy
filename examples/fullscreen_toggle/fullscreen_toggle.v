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
	log   solid.Log
	solid &solid.Solid = unsafe { nil } // Initialized by solid.run<T>(...)
}

pub fn (mut a App) init() {
	a.log.info(@STRUCT + '.' + @FN + ' log status: ' + a.log.status_string())
}

// TODO
[markused]
pub fn (mut a App) frame(f_dt f64) {
	mx, my := a.solid.mouse_position(.window)

	mut draw := a.solid.shape_draw()

	a.solid.scope(.open, .shape_draw)

	draw.radius = 3.25
	draw.colors[0] = solid.rgb(155, 44, 123)
	draw.colors[1] = solid.rgba(255, 255, 255, 127)
	draw.rectangle(mx - 50, my - 50, 100, 100)

	a.solid.scope(.close, .shape_draw)

	a.solid.scope(.open, .text_draw)
	mut text_draw := a.solid.text_draw()
	text_draw.text_at('$mx,$my', 10, 20)

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
		solid.WindowEvent {
			if e.kind == .resized {
				a.on_resized()
			}
		}
		else {
			// a.log.debug(@STRUCT + '.' + @FN + 'unhandled event $e')
		}
	}
}

// TODO
[markused]
pub fn (mut a App) quit() {
	a.log.debug(@STRUCT + '.' + @FN + ' called')
	a.log.free()
}

pub fn (mut a App) on_key_event(e solid.KeyEvent) {
	key := e.key_code
	alt_is_held := (a.solid.key_is_down(.lalt) || a.solid.key_is_down(.ralt))
	match e.state {
		.up {}
		.down {
			match key {
				.escape {
					a.solid.shutdown = true
				}
				else {
					a.log.info(@STRUCT + '.' + @FN + ' key down: $key')
					if key == .f || key == .f11 || key == .f || (key == .@return && alt_is_held) {
						mut win := a.solid.window()
						win.toggle_fullscreen()
					}
				}
			}
		}
	}
}

fn (mut a App) on_resized() {
	w, h := a.solid.window().size()
	a.log.debug(@STRUCT + '.' + @FN + ' ${w}x$h')
}
