// Copyright(C) 2023 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module main

import shy.lib as shy
import shy.embed
import shy.ease

fn main() {
	mut app := &App{}
	shy.run[App](mut app)!
}

[heap]
struct App {
	embed.ExampleApp
mut:
	a_r    &shy.Animator[f32] = shy.null
	origin shy.Anchor = .center
}

[markused]
pub fn (mut a App) init() ! {
	a.ExampleApp.init()!

	a_config := shy.AnimatorConfig{
		ease: ease.Ease{
			kind: .sine
			mode: .in_out
			// custom_fn: custom_ease
		}
		// recycle: true
		loops: shy.infinite
		loop: .pingpong
	}

	a.a_r = a.shy.new_animator[f32](a_config)

	if !a.a_r.running {
		a.a_r.init(0, 360, 5000)
		a.a_r.run()
	}
}

[markused]
pub fn (mut a App) frame(dt f64) {
	center := shy.vec2((shy.half * a.window.width), (shy.half * a.window.height))

	origin := a.origin
	rotation := f32(a.a_r.value()) * shy.deg2rad

	a.quick.triangle(
		a: center
		b: center + shy.vec2(f32(100), 30)
		c: center + shy.vec2(f32(50), 135)
		rotation: rotation
		origin: origin
	)

	// Mark center of window
	a.quick.rect(
		x: center.x
		y: center.y
		width: 2
		height: 2
		fills: .body
		color: shy.rgb(0, 0, 255)
	)

	a.quick.text(
		x: a.window.width * 0.01
		y: a.window.height * (1.0 - 0.01)
		origin: .bottom_left
		text: 'Click mouse left/right to change transform origin
Origin: ${a.origin}
Rotation: ${rotation * shy.rad2deg:.1f}°'
	)
}

[markused]
pub fn (mut a App) event(e shy.Event) {
	a.ExampleApp.event(e)
	match e {
		shy.MouseButtonEvent {
			if a.mouse.is_button_down(.left) {
				a.origin = a.origin.next()
			}
			if a.mouse.is_button_down(.right) {
				a.origin = a.origin.prev()
			}
		}
		else {}
	}
}
