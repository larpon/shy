// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module main

import shy.lib as shy
import shy.embed

fn main() {
	mut app := &App{}
	shy.run<App>(mut app)!
}

[heap]
struct App {
	embed.ExampleApp
}

[markused]
pub fn (mut a App) init() ! {
	a.ExampleApp.init()!
}

[markused]
pub fn (mut a App) frame(dt f64) {
	mut win := a.shy.active_window()
	mouse := a.mouse

	mut color := shy.Color{}
	if win.id == 0 {
		color = shy.colors.shy.blue
	}
	a.quick.rect(
		x: (win.width() / 2) - 50
		y: (win.height() / 2) - 50
		w: 100
		h: 100
		color: color
	)

	a.quick.text(
		x: (win.width() / 10)
		y: (win.height() / 10)
		text: 'Window ${win.id}\n(press W to open a new child window)\nMouse: ${mouse.x},${mouse.y}'
	)
}

[markused]
pub fn (mut a App) event(e shy.Event) {
	a.ExampleApp.event(e)
	match e {
		shy.KeyEvent {
			if e.state == .up {
				return
			}
			key := e.key_code
			match key {
				.w {
					a.window.new_window(
						title: 'New Shy Window'
						w: 400
						h: 300
					) or { panic(err) }
				}
				else {}
			}
		}
		else {}
	}
}
