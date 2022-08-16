// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module main

import shy

fn main() {
	mut app := &App{}
	config := shy.Config{}
	shy.run<App>(mut app, config)!
}

[heap]
struct App {
	shy.ExampleApp
}

[markused]
pub fn (mut a App) frame(dt f64) {
	mx, my := a.mouse.position(.window)

	mut draw := a.shy.draw2d()
	draw.begin()
	draw.text_at('Hello Shy World!', 11, 20)
	draw.text_at('$mx,$my', mx - 10, my + 35)
	draw.end()
}
