// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module main

import shy
import shy.log

fn main() {
	mut app := &App{}
	config := shy.Config{}
	shy.run<App>(mut app, config)
}

[heap]
struct App {
	shy.App
mut:
	log log.Log
}

pub fn (mut a App) init() {
	a.log.info(@STRUCT + '.' + @FN + ' log status: ' + a.log.status_string())
}

pub fn (mut a App) frame(f_dt f64) {
	mx, my := a.shy.mouse_position(.window)

	mut draw := a.shy.shape_draw()

	a.shy.scope(.open, .shape_draw)

	draw.radius = 3.25
	draw.colors[0] = shy.rgb(155, 44, 123)
	draw.colors[1] = shy.rgba(255, 255, 255, 127)
	draw.rectangle(mx - 50, my - 50, 100, 100)

	a.shy.scope(.close, .shape_draw)

	mut tdraw := a.shy.draw2d()
	tdraw.begin()
	tdraw.text_at('Press F11, "f" or Alt+Return to toggle fullscreen', 10, 20)
	tdraw.end()
}

pub fn (mut a App) event(e shy.Event) {
	match e {
		shy.QuitEvent {
			a.shy.shutdown = true
		}
		shy.KeyEvent {
			a.on_key_event(e)
		}
		shy.WindowEvent {
			if e.kind == .resized {
				a.on_resized()
			}
		}
		else {
			// a.log.debug(@STRUCT + '.' + @FN + 'unhandled event $e')
		}
	}
}

pub fn (mut a App) quit() {
	a.log.debug(@STRUCT + '.' + @FN + ' called')
	a.log.free()
}

pub fn (mut a App) on_key_event(e shy.KeyEvent) {
	key := e.key_code
	alt_is_held := (a.shy.key_is_down(.lalt) || a.shy.key_is_down(.ralt))
	match e.state {
		.up {}
		.down {
			match key {
				.escape {
					a.shy.shutdown = true
				}
				else {
					a.log.info(@STRUCT + '.' + @FN + ' key down: $key')
					if key == .f || key == .f11 || (key == .@return && alt_is_held) {
						mut win := a.shy.window()
						win.toggle_fullscreen()
					}
				}
			}
		}
	}
}

fn (mut a App) on_resized() {
	w, h := a.shy.window().size()
	a.log.debug(@STRUCT + '.' + @FN + ' ${w}x$h')
}
