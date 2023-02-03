// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module main

import shy.lib as shy
import shy.embed
import shy.particle
import shy.easy

fn main() {
	mut app := &App{}
	shy.run[App](mut app)!
}

[heap]
struct App {
	embed.ExampleApp
mut:
	eps &easy.ParticleSystem = shy.null
}

[markused]
pub fn (mut a App) init() ! {
	a.ExampleApp.init()!

	a.eps = a.easy.new_particle_system(
		width: a.canvas.width
		height: a.canvas.height
		pool: 300
	)

	scale := f32(6.0)
	a.eps.add(particle.Emitter{
		rate: 50
		position: shy.vec2[f32](shy.half * a.canvas.width, shy.half * a.canvas.height)
		velocity: particle.PointDirection{
			point: shy.vec2[f32](0.0, -0.5 * scale * 0.5)
			point_variation: shy.vec2[f32](0.2, 0.5)
		}
		size_variation: shy.vec2[f32](10.0 * scale, 10 * scale)
		life_time: 2000
		life_time_variation: 1000
		movement_velocity: 40
	})

	// For demo purposes, replace the default particle painter
	// with one that paints in red <3
	a.eps.replace_default_painter(a.easy.image_particle_painter(
		color: shy.colors.shy.red
	))
}

[markused]
pub fn (mut a App) frame(dt f64) {
	a.eps.draw()
}

[markused]
pub fn (mut a App) event(e shy.Event) {
	a.ExampleApp.event(e)

	mut emitters := a.eps.emitters()
	for mut em in emitters {
		em.position.x = a.mouse.x
		em.position.y = a.mouse.y
	}
}
