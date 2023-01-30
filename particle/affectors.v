// Copyright(C) 2020 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license file distributed with this software package

module particle

import shy.vec
import math

enum PhysicsType {
	constant
	linear
	inverse_linear
	quadratic
	inverse_quadratic
}

enum AffectParameter {
	position
	velocity
	acceleration
}

type Affector = AttractorAffector | CustomAffector | GravityAffector

pub struct CustomAffector {
pub mut:
	enabled bool
}

pub struct GravityAffector {
pub mut:
	enabled bool

	position vec.Vec2[f64] // Center position of the affector
	size     vec.Vec2[f64] // Max size of the affector

	groups []string // Leave empty to affect all particles

	angle     f32
	magnitude f32
	/*
	location			StochasticDirection
	velocity			StochasticDirection
	acceleration		StochasticDirection
	*/

	relative bool

	shape Shape // TODO
	// mut:
	// system				&System = 0
	// dt					f64			// current delta time this frame
}

fn (mut ga GravityAffector) collides(p &Particle) bool {
	if p.position.x >= ga.position.x - (ga.size.x * 0.5)
		&& p.position.x <= ga.position.x + (ga.size.x * 0.5) {
		return p.position.y >= ga.position.y - (ga.size.y * 0.5)
			&& p.position.y <= ga.position.y + (ga.size.y * 0.5)
	}
	return false
}

fn (mut ga GravityAffector) affect(mut p Particle) {
	// println('Affecting particle')

	// if !magnitude {
	//	return false
	//}
	// if (need_recalc) {
	//	need_recalc = false
	dx := ga.magnitude * math.cos((ga.angle - 90) * rad_pi_div_180)
	dy := ga.magnitude * math.sin((ga.angle - 90) * rad_pi_div_180)
	//}
	p.velocity.x += dx * p.system.dt
	p.velocity.y += dy * p.system.dt
}

pub struct AttractorAffector {
pub mut:
	enabled bool

	position vec.Vec2[f64] // Center position of the affector
	strength f32

	groups []string // Leave empty to affect all particles

	affected_parameter       AffectParameter // What attribute of the particles is affected
	proportional_to_distance PhysicsType     // How the distance from the particle to the point affects the strength of the attraction
}

fn (mut aa AttractorAffector) affect(mut p Particle) {
	// println('Affecting particle by attaction')

	if aa.strength == 0.0 {
		return
	}
	mut dx := aa.position.x - p.position.x
	mut dy := aa.position.y - p.position.y

	r := math.sqrt((dx * dx) + (dy * dy))
	theta := math.atan2(dy, dx)
	mut ds := 0.0

	match aa.proportional_to_distance {
		.inverse_quadratic {
			ds = (aa.strength / math.max(1.0, r * r))
		}
		.inverse_linear {
			ds = (aa.strength / math.max(1.0, r))
		}
		.quadratic {
			ds = (aa.strength * math.max(1.0, r * r))
		}
		.linear {
			ds = (aa.strength * math.max(1.0, r))
		}
		.constant { // default
			ds = aa.strength
		}
	}
	ds *= p.system.dt
	dx = ds * math.cos(theta)
	dy = ds * math.sin(theta)

	match aa.affected_parameter {
		.position {
			p.position.x += dx
			p.position.y += dy
		}
		.acceleration {
			p.acceleration.x += dx
			p.acceleration.y += dy
		}
		.velocity { // default
			p.velocity.x += dx
			p.velocity.y += dy
		}
	}
}
