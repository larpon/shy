// Copyright(C) 2023 Lars Pontoppidan. All rights reserved.
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
	center := shy.vec2((shy.half * a.window.width), (shy.half * a.window.height))
	half := shy.vec2(f32(50), 50)
	// Draws a triangle "pointing" at the center of the window
	a.quick.triangle(
		a: center - half
		b: center - half + shy.vec2(f32(100), 0)
		c: center
	)
}
