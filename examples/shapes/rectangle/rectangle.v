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
pub struct App {
	embed.ExampleApp
}

pub fn (mut a App) frame(dt f64) {
	// Draws a square at the center of the window
	a.quick.rect(
		x:      (shy.half * a.window.width)
		y:      (shy.half * a.window.height)
		width:  100
		height: 100
		origin: shy.Anchor.center
	)
}
