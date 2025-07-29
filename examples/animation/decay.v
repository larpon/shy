// Copyright(C) 2025 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module main

import shy.lib as shy
import shy.embed
import shy.vec
import shy.utils

fn main() {
	mut app := &App{}
	shy.run[App](mut app)!
}

@[heap]
pub struct App {
	embed.ExampleApp
mut:
	follower vec.Vec2[f32]
}

pub fn (mut a App) init() ! {
	a.ExampleApp.init()!
}

pub fn (mut a App) frame(dt f64) {
	mouse := a.mouse

	mut text_mouse := a.easy.text()
	text_mouse.x = mouse.x - 20
	text_mouse.y = mouse.y - 20
	text_mouse.text = '${text_mouse.x},${text_mouse.y}'
	text_mouse.draw()

	mut text_follower := a.easy.text()
	text_follower.x = a.follower.x - 20
	text_follower.y = a.follower.y - 20
	text_follower.text = '${text_follower.x},${text_follower.y}'
	text_follower.draw()

	win := a.window
	a.quick.text(
		x:      win.width * 0.01
		y:      win.height * (1.0 - 0.01)
		origin: shy.Anchor.bottom_left
		text:   'Frame: ${win.state.frame}
mouse at ${mouse.x},${mouse.y}
follower at ${a.follower.x:.1f},${a.follower.y:.1f}
FPS: ${win.fps()} ${win.state.update_rate}@hz dT: ${dt:.3f}'
	)
}

pub fn (mut a App) variable_update(dt f64) {
	a.follower.x = utils.exp_decay(a.follower.x, a.mouse.x, 1.5, dt)
	a.follower.y = utils.exp_decay(a.follower.y, a.mouse.y, 1.5, dt)
}
