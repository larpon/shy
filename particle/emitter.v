// Copyright(C) 2020 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license file distributed with this software package

module particle

import math
import rand
import shy.lib as shy
import shy.vec
import shy.analyse

pub struct Emitter {
pub mut:
	enabled bool = true

	position vec.Vec2[f32] // Center position of the emitter
	// Size of the emitter. when shape == .point the size has no effect
	size shy.Size = shy.Size{100, 100}

	velocity     StochasticDirection
	acceleration StochasticDirection

	start_size            vec.Vec2[f32] = default_size // Emitted particles start their life in this size
	end_size              vec.Vec2[f32] // Emitted particles end their life in this size
	size_variation        vec.Vec2[f32] // Particle size will vary up/down to a maximum of this value
	emit_size_keep_aspect bool = true

	life_time           f32 = 1000 // How long the particles emitted will last
	life_time_variation f32 // Particle life time will vary up/down to a maximum of this value

	rate f32 = 10.0 // Particles emitted per second

	group string // Logical group the emitted particles belong to

	shape Shape = .point
	/*
	Provide an additional starting velocity to the emitted particles based on the emitter's movement.
	The added velocity vector will have the same angle as the emitter's movement,
	with a magnitude that is the magnitude of the emitters movement multiplied by the  movement_velocity.
	*/
	movement_velocity      f32
	movement_velocity_flip bool
mut:
	position_last_frame vec.Vec2[f32]

	system  &System = unsafe { nil }
	dt      f64    // current delta time this frame
	elapsed f32 // Elapsed time accumulator

	burst_position vec.Vec2[f32] // Center position of the burst
	burst_amount   int
	pulse_duration int
}

/*
pub fn (mut e Emitter) move_to(v vec.Vec2[f32]) {
	e.position.from(v)
}*/

pub fn (mut e Emitter) burst(amount int) {
	// e.burst_position.from(e.position)
	e.burst_amount = amount
}

pub fn (mut e Emitter) burst_at(amount int, position vec.Vec2[f32]) {
	e.burst(amount)
	e.burst_position.from(position)
}

pub fn (mut e Emitter) pulse(duration_ms int) {
	e.pulse_duration = duration_ms
}

pub fn (mut e Emitter) update(dt f64) {
	e.dt = dt

	if e.burst_amount > 0 {
		e.emit()
		e.position_last_frame.from(e.position)
		return
	}

	if e.pulse_duration > 0 {
		e.pulse_duration -= int(dt * 1000)
		if e.pulse_duration <= 0 {
			e.pulse_duration = 0
			e.enabled = false
		} else {
			e.enabled = true
		}
	}

	if !e.enabled {
		return
	}
	e.emit()
	e.position_last_frame.from(e.position)
}

// emit initializes and sends particles into the system.
fn (mut e Emitter) emit() {
	mut s := e.system
	dt := e.dt
	e.elapsed += f32(dt)

	mut reserve := e.rate * e.elapsed

	mut bursting := false
	if e.burst_amount > 0 {
		analyse.max('${@MOD}.${@STRUCT}.burst_amount', e.burst_amount)
		bursting = true
		if s.bin.len >= e.burst_amount {
			reserve = e.burst_amount
		} else {
			reserve = s.bin.len
		}
		e.burst_amount -= int(reserve)
	}

	if reserve < 1 {
		// eprintln('Accumulating time. Reserve ${reserve} elapsed ${e.elapsed} dt ${dt} rate ${e.rate}')
		return
	}
	e.elapsed = 0
	// eprintln('Reserving ${reserve} particles from pool of ${s.bin.len}')
	mut p := &Particle(0)
	for i := 0; i < s.bin.len && reserve > 0; i++ {
		p = s.bin[i]
		p.reset()

		p.group = e.group

		if bursting && !e.burst_position.eq_scalar(0.0) {
			match e.shape {
				.point {
					p.position.from(e.burst_position)
				}
				.rectangle {
					area := shy.rect(e.position.x, e.position.y, e.size.width, e.size.height).displaced_from(.center)
					p.position.x = rand.f32_in_range(area.x, area.x + area.width) or {
						e.position.x
					}
					p.position.y = rand.f32_in_range(area.y, area.y + area.height) or {
						e.position.y
					}
				}
			}
			e.position_last_frame.from(p.position) // Stop movement_velocity this frame
		} else {
			match e.shape {
				.point {
					p.position.from(e.position)
				}
				// .ellipse {
				// 	panic('TODO implement this')
				// }
				.rectangle {
					area := shy.rect(e.position.x, e.position.y, e.size.width, e.size.height).displaced_from(.center)
					p.position.x = rand.f32_in_range(area.x, area.x + area.width) or {
						e.position.x
					}
					p.position.y = rand.f32_in_range(area.y, area.y + area.height) or {
						e.position.y
					}
				}
			}
		}

		e.apply_stochastic_direction(mut p.velocity, e.velocity)
		e.apply_stochastic_direction(mut p.acceleration, e.acceleration)

		p.life_time = e.life_time
		if e.life_time_variation != 0.0 {
			p.life_time += rand.f32_in_range(-e.life_time_variation, e.life_time_variation) or {
				-e.life_time_variation
			}
		}
		p.size = e.start_size
		p.end.size = e.end_size
		if !e.size_variation.eq_scalar(0.0) {
			mut sv := e.size_variation.copy()
			sv.abs()
			if e.emit_size_keep_aspect {
				sv_aspect := math.max(sv.x, sv.y)
				p.size.plus_scalar(rand.f32_in_range(-sv_aspect, sv_aspect) or { -sv_aspect })
			} else {
				if sv.x > 0 {
					p.size.x += rand.f32_in_range(-sv.x, sv.x) or { -sv.x }
				}
				if sv.y > 0 {
					p.size.y += rand.f32_in_range(-sv.y, sv.y) or { -sv.y }
				}
			}
		}
		p.set_init()
		// Send the particle into the system
		s.pool << p
		// Remove from the available particle bin
		s.bin.delete(i)
		reserve--
	}

	if e.burst_amount <= 0 {
		bursting = false
		e.burst_position.zero()
	}
}

fn (mut e Emitter) apply_stochastic_direction(mut v vec.Vec2[f32], sd StochasticDirection) {
	match sd {
		PointDirection {
			v.from(sd.point)

			if !sd.point_variation.eq_scalar(0.0) {
				mut pv := sd.point_variation + vec.Vec2[f32]{0, 0} //.copy()
				pv.abs()
				if pv.x > 0 {
					v.x += rand.f32_in_range(-pv.x, pv.x) or { -pv.x }
				}
				if pv.y > 0 {
					v.y += rand.f32_in_range(-pv.y, pv.y) or { -pv.y }
				}
			}

			if e.movement_velocity != 0.0 && !e.position.eq(e.position_last_frame) {
				d := if e.movement_velocity_flip {
					e.position_last_frame - e.position
				} else {
					e.position - e.position_last_frame
				}
				fvm := (e.movement_velocity / 1000)
				angle_rad := d.angle()
				magnitude := f32(e.position.manhattan_distance(d))

				v.x += fvm * (magnitude * math.cosf(angle_rad)) * f32(e.dt)
				v.y += fvm * (magnitude * math.sinf(angle_rad)) * f32(e.dt)
			}
		}
		AngleDirection {
			mut angle := sd.angle
			if sd.angle_variation != 0.0 {
				av := math.abs(sd.angle_variation)
				angle += rand.f32_in_range(-av, av) or { -av }
			}
			mut magnitude := sd.magnitude
			if sd.magnitude_variation != 0.0 {
				mv := math.abs(sd.magnitude_variation)
				magnitude += rand.f32_in_range(-mv, mv) or { -mv }
			}
			v.x = magnitude * math.cosf(f32(math.radians(angle)))
			v.y = magnitude * math.sinf(f32(math.radians(angle)))
		}
		TargetDirection {
			mut target := e.position - sd.target
			if !sd.target_variation.eq_scalar(0.0) {
				mut tv := sd.target_variation + vec.Vec2[f32]{0, 0} // .copy()
				tv.abs()
				if tv.x > 0 {
					target.x += rand.f32_in_range(-tv.x, tv.x) or { -tv.x }
				}
				if tv.y > 0 {
					target.y += rand.f32_in_range(-tv.y, tv.y) or { -tv.y }
				}
			}
			mut angle_rad := f32(0)
			if target.x != 0.0 {
				angle_rad = f32(math.atan2(-target.y, -target.x)) // flip (-) values to reach screen coordinates
			}

			mut magnitude := sd.magnitude
			if sd.proportional_magnitude {
				magnitude = f32(e.position.manhattan_distance(sd.target))
			}
			if sd.magnitude_variation != 0.0 {
				mv := math.abs(sd.magnitude_variation)
				magnitude += f32(rand.f32_in_range(-mv, mv) or { -mv })
			}
			v.x = magnitude * math.cosf(angle_rad)
			v.y = magnitude * math.sinf(angle_rad)
		}
	}
}
