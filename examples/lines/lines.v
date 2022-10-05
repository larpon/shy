// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module main

import shy.shy
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
pub fn (mut a App) frame(dt f64) {
	win_size := a.window.size()
	win_w := f32(win_size.w)
	win_h := f32(win_size.h)
	a.quick.line_segment(
		a: shy.vec2(win_w * 0.1, win_h * 0.1)
		b: shy.vec2(win_w * 0.9, win_h * 0.9)
		radius: 6.0
		color: shy.colors.shy.blue
	)
	a.quick.line_segment(
		a: shy.vec2(win_w * 0.1, win_h * 0.2)
		b: shy.vec2(win_w * 0.6, win_h * 0.9)
	)
	a.quick.line_segment(
		a: shy.vec2(win_w * 0.1, win_h * 0.2)
		b: shy.vec2(f32(a.mouse.x), a.mouse.y)
		radius: 4.0
		color: shy.colors.shy.green
		ray: true
	)
}
