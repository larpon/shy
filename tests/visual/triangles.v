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

@[heap]
struct App {
	embed.ExampleApp
mut:
	a_r    &shy.Animator[f32] = shy.null
	origin shy.Anchor = .center
}

@[markused]
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

@[markused]
pub fn (mut a App) frame(dt f64) {
	center := shy.vec2((shy.half * a.canvas().width), (shy.half * a.canvas().height))
	// center := shy.vec2(f32(200),200)

	/*
	a.quick.triangle(
		a: center
		b: center + shy.vec2(f32(50), -50) // TODO origin bug
		c: center + shy.vec2(f32(100), 0)
		origin: .center
	)*/

	origin := a.origin // shy.Anchor.top_center
	rotation := f32(a.a_r.value()) * shy.deg2rad

	mut tri_q1 := a.easy.triangle(
		a: center
		b: center + shy.vec2(f32(-100), -10)
		c: center + shy.vec2(f32(-50), -150) // TODO origin bug
		origin: origin
		rotation: rotation
		color: shy.rgba(0, 127, 0, 127)
		// scale: 0.4
	)
	tri_q1.draw()
	a.quick.rect(
		Rect: tri_q1.bbox()
		fills: .stroke
	)

	mut tri_q2 := a.easy.triangle(
		a: center
		b: center + shy.vec2(f32(100), -10)
		c: center + shy.vec2(f32(50), -150) // TODO origin bug
		origin: origin
		rotation: rotation
		color: shy.rgba(0, 0, 127, 127)
	)
	tri_q2.draw()
	a.quick.rect(
		Rect: tri_q2.bbox()
		fills: .stroke
	)

	mut tri_q3 := a.easy.triangle(
		a: center
		b: center + shy.vec2(f32(100), 10)
		c: center + shy.vec2(f32(50), 150) // TODO origin bug
		color: shy.rgba(127, 0, 0, 127)
		rotation: rotation
		// scale: 0.4
		origin: origin
	)
	// println('a: ${tri.a} b: ${tri.b} c: ${tri.c}')
	tri_q3.draw()

	a.quick.rect(
		Rect: tri_q3.bbox()
		fills: .stroke
	)

	mut tri_q4 := a.easy.triangle(
		c: center
		a: center + shy.vec2(f32(-100), 10)
		b: center + shy.vec2(f32(-50), 150) // TODO origin bug
		origin: origin
		rotation: rotation
		color: shy.rgba(127, 0, 127, 127)
	)
	tri_q4.draw()
	a.quick.rect(
		Rect: tri_q4.bbox()
		fills: .stroke
	)

	a.quick.rect(
		x: center.x
		y: center.y
		width: 2
		height: 2
		fills: .body
		color: shy.rgb(0, 255, 0)
	)

	a.quick.text(
		x: a.canvas().width * 0.01
		y: a.canvas().height * (1.0 - 0.01)
		origin: .bottom_left
		text: 'Click mouse left/right to change transform origin
Origin: ${a.origin}'
	)
}

@[markused]
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
