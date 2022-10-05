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
pub fn (mut a App) frame(dt f64) {
	a.quick.rect(
		x: (a.window.width() / 2)
		y: (a.window.height() / 2)
		w: 100
		h: 100
		origin: .center
	)
}
