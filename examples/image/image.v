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
pub fn (mut a App) init() ! {
	a.ExampleApp.init()!

	a.quick.load(
		uri: a.asset('img/shy_logo.png')
	)!
}

[markused]
pub fn (mut a App) frame(dt f64) {
	a.quick.image(
		x: f32(a.window.width()) * 0.5
		y: f32(a.window.height()) * 0.5
		uri: a.asset('img/shy_logo.png')
		origin: .center
	)
}
