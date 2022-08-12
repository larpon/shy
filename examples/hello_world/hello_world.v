// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module main

import solid

fn main() {
	mut app := &App{}
	config := solid.Config{}
	solid.run<App>(mut app, config)!
}

[heap]
struct App {
	solid.ExampleApp
}

[markused]
pub fn (mut a App) frame(dt f64) {
	mx, my := a.solid.mouse.position(.window)

	mut draw := a.solid.draw2d()
	draw.begin()
	draw.text_at('Hello Solid World!', 10, 20)
	draw.text_at('$mx,$my', mx - 10, my + 35)
	draw.end()
}
