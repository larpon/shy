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

[heap]
struct App {
	embed.ExampleApp
}

[markused]
pub fn (mut a App) init() ! {
	a.ExampleApp.init()!

	a.quick.load(shy.ImageOptions{
		source: a.asset('images/shy.png')
	})!
}

[markused]
pub fn (mut a App) frame(dt f64) {
	cx := shy.half * a.window.width()
	cy := shy.half * a.window.height()

	margin := f32(10)

	a.quick.image(
		x: cx
		y: cy
		source: a.asset('images/shy.png')
		origin: .bottom_right
		offset: shy.vec2(-margin, -margin)
		region: shy.Rect{0, 0, 256, 256}
	)
	a.quick.image(
		x: cx
		y: cy
		source: a.asset('images/shy.png')
		origin: .bottom_left
		offset: shy.vec2(margin, -margin)
		region: shy.Rect{256, 0, 256, 256}
	)

	a.quick.image(
		x: cx
		y: cy
		source: a.asset('images/shy.png')
		origin: .top_left
		offset: shy.vec2(margin, margin)
		region: shy.Rect{256, 256, 256, 256}
	)

	a.quick.image(
		x: cx
		y: cy
		source: a.asset('images/shy.png')
		origin: .top_right
		offset: shy.vec2(-margin, margin)
		region: shy.Rect{0, 256, 256, 256}
	)
}
