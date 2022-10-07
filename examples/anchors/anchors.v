// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module main

import shy.lib as shy
import shy.vec
import shy.embed

fn main() {
	mut app := &App{}
	shy.run<App>(mut app)!
}

[heap]
struct App {
	embed.ExampleApp
mut:
	origin shy.Anchor
	align  shy.TextAlign = .baseline | .left
}

[markused]
pub fn (mut a App) frame(dt f64) {
	win := a.window
	win_w, win_h := win.wh()
	a.quick.rect(
		x: win_w / 2
		y: win_h / 2
		origin: a.origin
		w: 50
		h: 50
		color: shy.colors.blue
	)

	a.quick.text(
		x: win_w / 2
		y: win_h / 2
		origin: .bottom_center
		// align: .left | .bottom
		offset: vec.vec2<f32>(0, -50 - 20)
		text: 'Current draw origin:\n$a.origin'
	)

	tx, ty := a.origin.pos_wh(win.Rect.w, win.Rect.h)
	a.quick.text(
		x: tx
		y: ty
		origin: a.origin
		text: '$a.origin / ' + a.align.str_clean()
		size: 42
	)

	// Visualize the tx,ty coordinate
	a.quick.rect(
		x: tx
		y: ty
		origin: .center
		w: 4
		h: 4
	)

	// Mark center of window
	a.quick.rect(
		x: win_w / 2
		y: win_h / 2
		origin: .center
		w: 2
		h: 2
	)

	test_text := 'Test text
with some lines...
Line 1
line 2
line 3'

	at_x := f32(win_w) * 0.15
	at_y := f32(win_h) * 0.15
	a.quick.text(
		x: at_x
		y: at_y
		origin: a.origin
		align: a.align
		text: test_text
	)

	a.quick.rect(
		x: at_x
		y: at_y
		origin: .center
		w: 4
		h: 4
	)
}

[markused]
pub fn (mut a App) event(e shy.Event) {
	a.ExampleApp.event(e)

	match e {
		shy.KeyEvent {
			if e.state == .down {
				match e.key_code {
					.left {
						a.origin = a.origin.prev()
					}
					.right {
						a.origin = a.origin.next()
					}
					else {}
				}
			}
		}
		shy.MouseButtonEvent {
			if e.state == .down {
				match e.button {
					.left {
						a.origin = a.origin.next()
					}
					.right {
						a.align = a.align.next()
					}
					else {}
				}
			}
		}
		else {}
	}
}
