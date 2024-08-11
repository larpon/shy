// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module main

import shy.lib as shy
import shy.embed

fn main() {
	mut app := &App{}
	shy.run[App](mut app)!
}

@[heap]
struct App {
	embed.ExampleApp
}

@[markused]
pub fn (mut a App) frame(dt f64) {
	win_w := f32(a.window.width)
	win_h := f32(a.window.height)
	a.quick.line_segment(
		a:     shy.vec2(win_w * 0.1, win_h * 0.1)
		b:     shy.vec2(win_w * 0.9, win_h * 0.9)
		width: 6.0
		color: shy.colors.shy.blue
	)
	a.quick.line_segment(
		a: shy.vec2(win_w * 0.1, win_h * 0.2)
		b: shy.vec2(win_w * 0.6, win_h * 0.9)
	)
	a.quick.line_segment(
		a:     shy.vec2(win_w * 0.1, win_h * 0.2)
		b:     shy.vec2(f32(a.mouse.x), a.mouse.y)
		width: 4.0
		color: shy.colors.shy.green
		ray:   true
	)
}
