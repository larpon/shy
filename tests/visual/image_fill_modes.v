// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module main

import shy.lib as shy
import shy.embed

const test_width = 256

const test_height = 256

const images = {
	'256x128': 'shy_256x128.png'
	'128x256': 'shy_128x256.png'
	'512x256': 'shy_512x256.png'
	'256x512': 'shy_256x512.png'
	'128x64':  'shy_128x64.png'
	'64x128':  'shy_64x128.png'
	'512x512': 'shy_512x512.png'
	'256x256': 'shy_256x256.png'
	'128x128': 'shy_128x128.png'
	'64x64':   'shy_64x64.png'
}

fn main() {
	mut app := &App{}
	shy.run[App](mut app)!
}

@[heap]
struct App {
	embed.TestApp
mut:
	origin    shy.Anchor = .center
	fill_mode shy.ImageFillMode
	image     string = '64x128'
}

@[markused]
pub fn (a App) asset_fill_mode(path string, fill_mode shy.ImageFillMode) shy.AssetSource {
	return match fill_mode {
		.tile {
			a.TestApp.asset(path, tag: 'tile_xy')
		}
		.stretch_horizontally_tile_vertically {
			a.TestApp.asset(path, tag: 'tile_y')
		}
		.stretch_vertically_tile_horizontally {
			a.TestApp.asset(path, tag: 'tile_x')
		}
		.tile_vertically {
			a.TestApp.asset(path, tag: 'tile_y')
		}
		.tile_horizontally {
			a.TestApp.asset(path, tag: 'tile_x')
		}
		else {
			a.TestApp.asset(path)
		}
	}
}

@[markused]
pub fn (mut a App) init() ! {
	a.TestApp.init()!

	for _, image in images {
		a.quick.load(shy.ImageOptions{
			source: a.asset(image)
		})!
		a.quick.load(shy.ImageOptions{
			wrap_u: .repeat
			source: a.asset(image, tag: 'tile_x')
		})!
		a.quick.load(shy.ImageOptions{
			wrap_v: .repeat
			source: a.asset(image, tag: 'tile_y')
		})!
		a.quick.load(shy.ImageOptions{
			wrap_u: .repeat
			wrap_v: .repeat
			source: a.asset(image, tag: 'tile_xy')
		})!
	}
}

@[markused]
pub fn (mut a App) frame(dt f64) {
	a.live_frame(dt)
}

//[live]
pub fn (mut a App) live_frame(dt f64) {
	cx := shy.half * a.canvas().width
	cy := shy.half * a.canvas().height

	a.quick.rect(
		x: cx
		y: cy
		width: test_width
		height: test_height
		origin: shy.Anchor.center
		fills: .stroke
		stroke: shy.Stroke{
			width: 9
		}
	)

	a.quick.rect(
		x: cx
		y: cy
		width: shy.half * test_width
		height: test_height
		origin: shy.Anchor.center
		fills: .stroke
		stroke: shy.Stroke{
			width: 9
		}
	)

	a.quick.rect(
		x: cx
		y: cy
		width: test_width
		height: shy.half * test_height
		origin: shy.Anchor.center
		fills: .stroke
		stroke: shy.Stroke{
			width: 9
		}
	)

	a.quick.image(
		x: cx
		y: cy
		width: test_width
		height: test_height
		source: a.asset_fill_mode(images[a.image], a.fill_mode)
		origin: a.origin
		fill_mode: a.fill_mode
		// scale: rs
		// offset: shy.vec2(-margin, -margin)
		// region: shy.Rect{0, 0, 256, 256}
	)

	a.quick.rect(
		x: cx
		y: cy
		width: test_width
		height: test_height
		origin: a.origin
		fills: .stroke
		stroke: shy.Stroke{
			color: shy.colors.red
			width: 1
		}
	)

	a.quick.rect(
		x: cx
		y: cy
		width: 3
		height: 3
		origin: shy.Anchor.center
		fills: .body
		color: shy.colors.blue
	)

	a.quick.text(
		// x:
		y: a.canvas().height
		// width: rw
		// height: rh
		origin: shy.Anchor.bottom_left
		text: 'Image (n/m): ${images[a.image]}
Origin (up/down): ${a.origin}
FillMode (left/right): ${a.fill_mode}'
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
					.left {
						a.fill_mode = a.fill_mode.prev()
					}
					.right {
						a.fill_mode = a.fill_mode.next()
					}
					.up {
						a.origin = a.origin.prev()
					}
					.down {
						a.origin = a.origin.next()
					}
					.n {
						avail := images.keys()
						mut i := avail.index(a.image) + 1
						if i < 0 {
							i = avail.len - 1
						}
						if i >= avail.len {
							i = 0
						}
						a.image = avail[i]
					}
					.m {
						avail := images.keys()
						mut i := avail.index(a.image) - 1
						if i < 0 {
							i = avail.len - 1
						}
						if i >= avail.len {
							i = 0
						}
						a.image = avail[i]
					}
					else {}
				}
			}
		}
		else {}
	}
}
