// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module main

import shy.shy

fn main() {
	mut app := &App{}
	shy.run<App>(mut app)!
}

[heap]
struct App {
	shy.ExampleApp
}

[markused]
pub fn (mut a App) init() ! {
	a.ExampleApp.init()!
}

[markused]
pub fn (mut a App) frame(dt f64) {
	mut win := a.shy.active_window()
	mouse := a.mouse

	colors := if win.id == 0 {
		shy.ColorsSolidAndOutline{
			solid: shy.colors.shy.blue
		}
	} else {
		shy.ColorsSolidAndOutline{}
	}
	a.easy.rect(
		x: (win.width() / 2) - 50
		y: (win.height() / 2) - 50
		w: 100
		h: 100
		colors: colors
	)
	a.easy.text(
		x: (win.width() / 6)
		y: (win.height() / 6)
		text: 'Window $win.id\n(press W to open a new child window)\nMouse: $mouse.x,$mouse.y'
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
