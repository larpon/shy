// Copyright(C) 2020 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license file distributed with this software package

module particle

import shy.lib as shy
import shy.vec
import shy.utils

const (
	default_size      = vec.Vec2[f64]{6, 6}
	default_life_time = 1000.0
	default_color     = shy.Color{255, 255, 255, 255}
)

pub fn (mut s System) new_particle() &Particle {
	ip := ParticleState{
		// init: particle.null
		// end: particle.null
		// system: s
		position: vec.Vec2[f64]{0, 0}
		velocity: vec.Vec2[f64]{0, 0}
		acceleration: vec.Vec2[f64]{0, 0}
		size: particle.default_size
		rotation: 0
		scale: 1
		color: particle.default_color
		life_time: particle.default_life_time
	}

	ep := ParticleState{
		// init: particle.null
		// end: particle.null
		// system: s
		position: ip.position
		velocity: ip.velocity
		acceleration: ip.acceleration
		size: ip.size
		rotation: ip.rotation
		scale: ip.scale
		color: ip.color
		life_time: 0.0
	}

	p := &Particle{
		system: s
		init: ip
		end: ep
		//
		position: ip.position
		velocity: ip.velocity
		acceleration: ip.acceleration
		size: ip.size
		rotation: ip.rotation
		scale: ip.scale
		color: ip.color
		life_time: ip.life_time
	}
	return p
}

pub struct ParticleState {
mut:
	position     vec.Vec2[f64]
	velocity     vec.Vec2[f64]
	acceleration vec.Vec2[f64]
	size         vec.Vec2[f64]
	rotation     f32
	scale        f32
	color        shy.Color
	life_time    f32
}

fn (p ParticleState) eq(pa ParticleState) bool {
	return p.position.eq_epsilon(pa.position) && p.velocity.eq_epsilon(pa.velocity)
		&& p.acceleration.eq_epsilon(pa.acceleration) && p.size.eq_epsilon(pa.size)
		&& p.rotation == pa.rotation && p.scale == pa.scale && p.color == pa.color
		&& p.life_time == pa.life_time
}

/*
* Particle
*/
[heap]
pub struct Particle {
mut:
	system &System
	// mut:
	init      ParticleState
	end       ParticleState
	group     string
	need_init bool
	// State
	position     vec.Vec2[f64]
	velocity     vec.Vec2[f64]
	acceleration vec.Vec2[f64]
	size         vec.Vec2[f64]
	rotation     f32
	scale        f32
	color        shy.Color
	life_time    f32
	//
}

pub fn (mut p Particle) set_init() {
	p.init.position = p.position
	p.init.velocity = p.velocity
	p.init.acceleration = p.acceleration
	p.init.size = p.size
	p.init.rotation = p.rotation
	p.init.scale = p.scale
	p.init.color = p.color
	p.init.life_time = p.life_time
	p.need_init = true
}

fn (p Particle) has_state(ps ParticleState) bool {
	return p.position.eq_epsilon(ps.position) && p.velocity.eq_epsilon(ps.velocity)
		&& p.acceleration.eq_epsilon(ps.acceleration) && p.size.eq_epsilon(ps.size)
		&& p.rotation == ps.rotation && p.scale == ps.scale && p.color == ps.color
		&& p.life_time == ps.life_time
}

pub fn (p Particle) is_ready() bool {
	return !p.has_state(p.init)
}

pub fn (mut p Particle) update(dt f64) {
	mut acc := p.acceleration
	acc.multiply_scalar(dt)
	p.velocity = p.velocity.add(acc)
	p.position = p.position.add(p.velocity)

	p.life_time -= f32(1000 * dt)
	if p.life_time > 0 {
		p.size.x = f32(utils.remap[f64](p.life_time, p.init.life_time, p.end.life_time,
			p.init.size.x, p.end.size.x))
		p.size.y = f32(utils.remap[f64](p.life_time, p.init.life_time, p.end.life_time,
			p.init.size.y, p.end.size.y))

		p.rotation = f32(utils.remap[f64](p.life_time, p.init.life_time, p.end.life_time,
			p.init.rotation, p.end.rotation)) // * f32(dt)
		p.scale = f32(utils.remap[f64](p.life_time, p.init.life_time, p.end.life_time,
			p.init.scale, p.end.scale)) // * f32(dt)
		// println('lt ${p.life_time}/${p.init.life_time} s ${p.scale} a ${p.color.a}')
	} else {
		p.life_time = 0
	}

	// println('${p.life_time:.2f}')
}

pub fn (p Particle) is_dead() bool {
	return p.life_time <= 0
}

pub fn (mut p Particle) reset() {
	p.position.zero()
	p.acceleration.zero()
	p.velocity.zero()
	p.color = particle.default_color

	p.rotation = 0
	p.scale = 1

	p.life_time = particle.default_life_time

	p.set_init()
}

pub fn (mut p Particle) free() {
	unsafe {
		free(p.init)
		free(p.end)
		free(p)
		// p = &Particle(0) // NOTE this stopped working
	}
}
