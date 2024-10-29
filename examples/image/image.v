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

@[markused]
pub fn (mut a App) init() ! {
	a.ExampleApp.init()!

	a.quick.load(shy.ImageOptions{
		source: a.asset('images/shy.png')
	})!
}

@[markused]
pub fn (mut a App) frame(dt f64) {
	a.quick.image(
		x:      shy.half * a.window.width
		y:      shy.half * a.window.height
		source: a.asset('images/shy.png')
		origin: shy.Anchor.center
	)
}
