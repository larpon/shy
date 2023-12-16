// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module main

import shy.lib as shy
import shy.embed
import shy.mth

const dimensions = [
	u16(64),
	128,
	256,
	512,
	1024,
	2048,
]!

fn main() {
	mut app := &App{}
	shy.run[App](mut app)!
}

@[heap]
struct App {
	embed.TestApp
mut:
	origin    shy.Anchor
	dimension u16 = 256
	dim_index u16 = 2 // index of "256" in dimensions
}

@[markused]
pub fn (mut a App) init() ! {
	a.TestApp.init()!
}

@[markused]
pub fn (mut a App) frame(dt f64) {
	a.live_frame(dt)
}

@[live]
pub fn (mut a App) live_frame(dt f64) {
	max_width := a.window.width
	max_height := a.window.height

	cx := max_width * 0.5
	cy := max_height * 0.5

	min_x, max_x := mth.max(max_width * 0.1, 20), mth.max(max_width * 0.9, 220)
	min_y, max_y := mth.max(max_height * 0.1, 20), mth.max(max_height * 0.9, 220)

	a.quick.rect(
		x: cx
		y: cy
		width: a.dimension
		height: a.dimension
		origin: shy.Anchor.center
		radius: a.dimension / 2
		color: shy.rgba(255, 0, 0, 127)
		stroke: shy.Stroke{
			color: shy.rgba(255, 255, 255, 127)
			width: a.dimension * 2 // test if rendering overflows on too big lines
		}
	)

	a.quick.rect(
		x: min_x
		y: min_y
		width: a.dimension
		height: a.dimension
		origin: shy.Anchor.center
		radius: a.dimension / 2
		color: shy.rgba(255, 0, 0, 127)
		stroke: shy.Stroke{
			color: shy.rgba(255, 255, 255, 127)
			width: a.dimension / 2
		}
	)

	a.quick.rect(
		x: min_x
		y: max_y
		width: a.dimension
		height: a.dimension
		origin: shy.Anchor.bottom_left
		radius: a.dimension / 10
		color: shy.rgba(0, 0, 255, 127)
		stroke: shy.Stroke{
			color: shy.rgba(255, 255, 255, 127)
			width: 10
		}
	)

	a.quick.rect(
		x: max_x
		y: max_y
		width: a.dimension
		height: a.dimension
		origin: shy.Anchor.bottom_right
		radius: a.dimension / 8
		color: shy.rgba(255, 0, 0, 127)
		stroke: shy.Stroke{
			color: shy.rgba(255, 255, 255, 127)
			width: 1
		}
	)

	a.quick.rect(
		x: max_x
		y: min_y
		width: a.dimension
		height: a.dimension
		origin: shy.Anchor.top_right
		radius: a.dimension / 8
		color: shy.rgba(255, 0, 0, 127)
		fills: .body
	)

	a.quick.text(
		y: a.canvas().height
		origin: shy.Anchor.bottom_left
		text: 'Press "D" to change dimensions
Origin (up/down): ${a.origin}
Dimensions ${a.dimension}x${a.dimension}'
	)
}

@[markused]
pub fn (mut a App) event(e shy.Event) {
	a.TestApp.event(e)
	match e {
		shy.MouseButtonEvent {
			if a.mouse.is_button_down(.left) {
				a.origin = a.origin.next()
			}
			if a.mouse.is_button_down(.right) {
				a.origin = a.origin.prev()
			}
		}
		shy.KeyEvent {
			if e.state == .down {
				match e.key_code {
					.left {}
					.right {}
					.up {
						a.origin = a.origin.prev()
					}
					.down {
						a.origin = a.origin.next()
					}
					.d {
						a.dim_index++
						if a.dim_index > dimensions.len - 1 {
							a.dim_index = 0
						}

						a.dimension = dimensions[a.dim_index]
					}
					else {}
				}
			}
		}
		else {}
	}
}
