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
	embed.TestApp
}

const image_path = 'images/shy.png'

@[markused]
pub fn (mut a App) init() ! {
	a.TestApp.init()!

	a.quick.load(shy.ImageOptions{
		source: a.asset(image_path)
	})!
}

@[markused]
pub fn (mut a App) frame(dt f64) {
	win_size := a.window.size()
	win_w := f32(win_size.width)
	win_h := f32(win_size.height)

	a.quick.line_segment(
		a: shy.vec2(win_w * 0.1, win_h * 0.1)
		b: shy.vec2(win_w * 0.9, win_h * 0.9)
		width: 6.0
		color: shy.colors.shy.blue
	)

	a.quick.rect(
		x: (win_w * 0.75)
		y: (win_h * 0.75)
		width: 100
		height: 100
		rotation: 45 * shy.deg2rad
		origin: shy.Anchor.center
	)

	a.quick.image(
		x: 0.75 * f32(a.window.width)
		y: shy.half * a.window.height
		source: a.asset(image_path)
		origin: .center
	)

	a.quick.text(
		x: win_w
		y: win_h
		text: 'Shy Test!'
		origin: .bottom_right
	)

	a.quick.line_segment(
		a: shy.vec2(win_w * 0.1, win_h * 0.2)
		b: shy.vec2(win_w * 0.6, win_h * 0.9)
	)

	a.quick.line_segment(
		a: shy.vec2(win_w * 0.1, win_h * 0.2)
		b: shy.vec2(f32(a.mouse.x), a.mouse.y)
		width: 4.0
		color: shy.colors.shy.green
		ray: true
	)

	a.quick.image(
		x: 0.90 * f32(a.window.width)
		y: shy.half * a.window.height
		source: a.asset(image_path)
		origin: .center
	)

	a.quick.circle(
		x: (win_w * 0.25)
		y: (win_h * 0.75)
		radius: 100
		stroke: shy.Stroke{
			width: 10
		}
	)

	a.quick.text(
		x: (win_w * 0.25)
		y: (win_h * 0.75)
		text: 'Shy'
		origin: .center
	)

	a.quick.rect(
		x: (win_w * 0.75)
		y: (win_h * 0.75)
		width: 100
		height: 100
		rotation: 45 * shy.deg2rad
		origin: shy.Anchor.center
	)
}
