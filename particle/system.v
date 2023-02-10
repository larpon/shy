// Copyright(C) 2020 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license file distributed with this software package
module particle

import shy.lib as shy
import shy.analyse

const (
	rad_pi_div_180 = f32(0.017453292520444443) // ~ pi/180 in radians
)

type Component = Affector | Emitter

// System
pub struct SystemConfig {
	shy.Rect
	pool u32
}

pub fn new_system(sc SystemConfig) &System {
	mut s := &System{
		Rect: sc.Rect
	}
	s.init(sc)
	return s
}

[heap; noinit]
pub struct System {
	shy.Rect
mut:
	pool []&Particle
	bin  []&Particle

	emitters  []Emitter
	affectors []Affector
	painters  []Painter

	dt f64
pub mut:
	pause bool
}

fn (mut s System) init(sc SystemConfig) {
	// OPTIMISATIONS
	// .noslices - tells the compiler that we're 100% sure that
	//  the pool array is *never* sliced (E.g. ps := s.pool[2..6])
	//
	// .noshrink - tells the compiler that we do not want
	//  delete operations on the array to reallocate memory - this breaks the idea of using a pool in the first place
	unsafe { s.pool.flags.set(.noslices | .noshrink) }
	unsafe { s.bin.flags.set(.noslices | .noshrink) }
	$if debug {
		eprintln(@MOD + '.' + @STRUCT + '::' + @FN + ' creating ${sc.pool} particles.')
	}
	for i := 0; i < sc.pool; i++ {
		p := s.new_particle()
		s.bin << p
	}
	$if debug {
		eprintln(@MOD + '.' + @STRUCT + '::' + @FN + ' created ${sc.pool} particles.')
	}
}

pub fn (mut s System) add(cp Component) {
	mut c := unsafe { cp }
	match mut c {
		Emitter {
			// eprintln('Adding emitter')
			// e := c as Emitter
			c.system = s
			s.emitters << c
			// e := s.emitter_at(0) or {panic(err)}
		}
		Affector {
			mut a := c
			match mut a {
				GravityAffector {
					// eprintln('Adding gravity affector')
					s.affectors << a
				}
				AttractorAffector {
					// eprintln('Adding attractor affector')
					s.affectors << a
				}
				else {
					panic('TODO: Unknown Affector type')
				}
			}
		}
		/*
		else {
			println('Unknown system component (V BUG unprintable)') //${c} BUG doesn't print
			return
		}*/
	}
}

pub fn (mut s System) add_painter(p Painter) int {
	s.painters << p
	return s.painters.len - 1
}

pub fn (mut s System) remove_painter_at(index int) {
	s.painters.delete(int(index))
}

pub fn (s &System) emitter_at(index int) ?&Emitter {
	unsafe {
		if mut emitter := s.emitters[index] {
			// TODO println('ggg${ptr_str(emitter)}')
			return &emitter
		}
	}
	return none
}

pub fn (s &System) emitters() []&Emitter {
	mut collected := []&Emitter{}
	for i := 0; i < s.emitters.len; i++ {
		emitter := &s.emitters[i]
		collected << emitter
	}
	return collected
}

pub fn (s &System) emitters_in_groups(groups []string) []&Emitter {
	mut collected := []&Emitter{}
	for i := 0; i < s.emitters.len; i++ {
		emitter := &s.emitters[i]
		for group in groups {
			if emitter.group == group {
				collected << emitter
			}
		}
	}
	return collected
}

pub fn (mut s System) update(dt f64) {
	s.dt = dt
	if s.pause {
		return
	}
	// Guard against total freeze on low framerates
	if s.dt <= 0.0 {
		s.dt = 0.000001
	}
	// Emitters extract particles from the bin to the pool
	for i := 0; i < s.emitters.len; i++ {
		s.emitters[i].update(dt)
	}
	analyse.max('${@MOD}.${@STRUCT}.pool.len', s.pool.len)
	// Run through the pool of currently active particles
	mut p := &Particle(0)
	for i := 0; i < s.pool.len; i++ {
		p = s.pool[i]
		if p.is_dead() {
			s.bin << p
			s.pool.delete(i)
			continue
		}
		// Init painters if necessary
		if !p.is_ready() {
			for mut painter in s.painters {
				painter.init(mut p)
			}
		}
		// Affect particle
		for mut affector in s.affectors {
			match mut affector {
				GravityAffector {
					if affector.groups.len == 0 || p.group in affector.groups {
						if affector.collides(p) {
							affector.affect(mut p)
						}
					}
				}
				AttractorAffector {
					if affector.groups.len == 0 || p.group in affector.groups {
						affector.affect(mut p)
					}
				}
				else {
					// eprintln('Affector type ${painter} not supported') // <- struct printing results in some C error
					panic('TODO: Affector type not supported')
				}
			}
		}

		p.update(dt)
		if p.is_dead() {
			s.bin << p
			s.pool.delete(i)
			continue
		}
		// TODO could be optimized so particle pool is only only traversed once??
		// Draw call would be here... remove other draw calls
	}
}

pub fn (s System) draw(f_dt f64) {
	mut p := &Particle(0)
	// for mut p in s.pool {
	for i := 0; i < s.pool.len; i++ {
		p = s.pool[i]
		if p.is_dead() || !p.is_ready() {
			continue
		}
		for painter in s.painters {
			if p.group in painter.groups {
				painter.draw(p, f_dt)
			}
		}
	}
}

pub fn (mut s System) reset() {
	eprintln(@MOD + '.' + @STRUCT + '::' + @FN)
	eprintln('Resetting ${s.pool.len} from pool ${s.bin.len}')
	for p in s.pool {
		mut pm := unsafe { p }
		pm.reset()
		pm.life_time = 0
	}
	for p in s.bin {
		mut pm := unsafe { p }
		pm.reset()
		pm.life_time = 0
	}
}

pub fn (mut s System) free() {
	// eprintln('Freeing ${s.pool.len} from pool')
	for p in s.pool {
		if isnil(p) {
			print(ptr_str(p) + ' ouch')
			continue
		}
		unsafe {
			p.free()
		}
	}
	s.pool.clear()

	// eprintln('Freeing ${s.bin.len} from bin')
	for p in s.bin {
		if isnil(p) {
			eprint(ptr_str(p) + ' ouch')
			continue
		}

		unsafe {
			// println('Freeing from bin')
			p.free()
		}
	}
	s.bin.clear()
}
