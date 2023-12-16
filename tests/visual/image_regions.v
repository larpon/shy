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
pub fn (mut a App) init() ! {
	a.ExampleApp.init()!

	a.quick.load(shy.ImageOptions{
		source: a.asset('images/shy.png')
	})!
}

@[markused]
pub fn (mut a App) frame(dt f64) {
	a.live_frame(dt)
}

@[live]
pub fn (mut a App) live_frame(dt f64) {
	cx := shy.half * a.window.width
	cy := shy.half * a.window.height

	rw := -1 // 256 // -1 // 256
	rh := -1 // 256 // -1 // 256
	margin := f32(10)

	rs := f32(0.6) // f32(0.5) //256/512

	a.quick.image(
		x: cx
		y: cy
		width: rw
		height: rh
		source: a.asset('images/shy.png')
		origin: shy.Anchor.bottom_right
		scale: rs
		offset: shy.vec2(-margin, -margin)
		region: shy.Rect{0, 0, 256, 256}
	)
	a.quick.image(
		x: cx
		y: cy
		width: rw
		height: rh
		source: a.asset('images/shy.png')
		origin: shy.Anchor.bottom_left
		scale: rs
		offset: shy.vec2(margin, -margin)
		region: shy.Rect{256, 0, 256, 256}
	)

	a.quick.image(
		x: cx
		y: cy
		width: rw
		height: rh
		source: a.asset('images/shy.png')
		origin: shy.Anchor.top_left
		scale: rs
		offset: shy.vec2(margin, margin)
		region: shy.Rect{256, 256, 256, 256}
	)

	a.quick.image(
		x: cx
		y: cy
		width: rw
		height: rh
		source: a.asset('images/shy.png')
		origin: shy.Anchor.top_right
		scale: rs
		offset: shy.vec2(-margin, margin)
		region: shy.Rect{0, 256, 256, 256}
	)
}
