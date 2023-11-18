// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
//
// This example tests if the rectangles look as expected at a stroke width of 1
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

@[markused]
pub fn (mut a App) frame(dt f64) {
	a.TestApp.frame(dt)
	canvas := a.window.canvas()

	a.quick.rect(
		x: canvas.width / 2
		y: canvas.height / 2
		width: canvas.width
		height: canvas.height
		origin: .center
		stroke: shy.Stroke{
			width: 1
		}
	)

	a.quick.rect(
		x: canvas.width / 2
		y: canvas.height / 2
		width: canvas.width / 2
		height: canvas.height / 2
		origin: .center
		stroke: shy.Stroke{
			width: 1
		}
	)
}
