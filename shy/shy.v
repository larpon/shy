// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module shy

import time
// import shy.api
import shy.mth
import shy.log { Log }

pub const null = unsafe { nil }

const vet_tag = 'VET'

//
pub enum ButtonState {
	up
	down
}

struct State {
mut:
	resync bool
	//
	fps_frame    u32
	fps_snapshot u32
	frame        u64
	//
	in_hot_code   bool
	in_frame_call bool
}

struct ShyStruct {
pub mut: // TODO error: field `App.shy` is not public - make this just "pub" to callers - and mut to internal system
	shy &Shy // = shy.null
}

fn (sb ShyStruct) init() ! {}

fn (sb ShyStruct) shutdown() ! {}

struct ShyFrame {
	ShyStruct
}

[if !prod]
fn (mut sf ShyFrame) begin() {
	assert sf.shy.state.in_frame_call, '${@STRUCT}.${@FN}' +
		' can only be called inside a .frame() call'
}

[if !prod]
fn (mut sf ShyFrame) end() {
	assert sf.shy.state.in_frame_call, '${@STRUCT}.${@FN}' +
		' can only be called inside a .frame() call'
}

// Shy carries all of shy's internal state.
[heap]
pub struct Shy {
	config Config
	timer  time.StopWatch = time.new_stopwatch(auto_start: true)
pub mut:
	paused   bool
	shutdown bool
mut:
	log     log.Log
	ready   bool
	running bool
	//
	state State
	// The "blackbox" api implementation specific struct
	api API
}

[inline]
pub fn (mut s Shy) init() ! {
	$if debug ? {
		s.log.set(.debug)
	}
	s.log.gdebug('${@STRUCT}.${@FN}', 'hi')
	s.api.init(s)!
	s.check_api()!
	s.ready = true
}

[inline]
pub fn (mut s Shy) shutdown() ! {
	s.ready = false
	s.api.shutdown()!
	s.log.shutdown()!
}

// new returns a new, initialized, `Shy` struct allocated in heap memory.
pub fn new(config Config) !&Shy {
	mut s := &Shy{
		config: config
	}
	s.init()!
	return s
}

// run runs the application instance `T`.
pub fn run<T>(mut ctx T, config Config) ! {
	mut shy_instance := new(config)!
	ctx.shy = shy_instance
	ctx.init()!

	main_loop<T>(mut ctx, mut shy_instance)!

	ctx.quit()
	shy_instance.shutdown()!
	unsafe { free(shy_instance) }
}

fn main_loop<T>(mut ctx T, mut s Shy) ! {
	s.log.gdebug(@MOD + '.' + @FN, 'entering main loop.\nConfig:\n$s.config')
	mut fps_timer := u64(0)

	run_config := s.config.run
	// update_rate         = f64(59.95) // TODO
	update_rate := run_config.update_rate // f64(60)
	// update_rate         = f64(120)
	update_multiplicity := run_config.update_multiplicity // int(1)
	lock_framerate := run_config.lock_framerate // false
	time_history_count := run_config.time_history_count // 4

	// V implementation of:
	// https://medium.com/@tglaiel/how-to-make-your-game-run-at-60fps-24c61210fe75
	// https://gafferongames.com/post/fix_your_timestep/
	// compute how many ticks one update should be
	performance_frequency := s.performance_frequency()
	fixed_deltatime := f64(1.0) / update_rate
	desired_frametime := i64(performance_frequency / update_rate)

	// These are to snap deltaTime to vsync values if it's close enough
	vsync_maxerror := i64(performance_frequency * f64(0.0002))
	time_60hz := i64(performance_frequency / 60) // since this is about snapping to common vsync values
	// time_60hz := i64(performance_frequency / update_rate)
	snap_frequencies := [
		time_60hz, /* 60fps */
		time_60hz * 2, /* 30fps */
		time_60hz * 3, /* 20fps */
		time_60hz * 4, /* 15fps */
		(time_60hz + 1) / 2, /* 120fps */
		/*
		//120hz, 240hz, or higher need to round up, so that adding 120hz twice guaranteed is at least the same as adding time_60hz once
		// (time_60hz+2)/3,  //180fps //that's where the +1 and +2 come from in those equations
		// (time_60hz+3)/4,  //240fps //I do not want to snap to anything higher than 120 in my engine, but I left the math in here anyway
		*/
	]!

	// time_history_count := 4
	// mut time_averager := [time_history_count]i64{init: desired_frametime}
	//
	// This is for delta time averaging
	// Time averaging could, arguably, be done using a ring buffer.
	mut time_averager := []i64{len: int(time_history_count), cap: int(time_history_count), init: desired_frametime}

	s.running = true
	s.state.resync = true
	mut prev_frame_time := i64(s.performance_counter())
	mut frame_accumulator := i64(0)

	s.state.in_hot_code = true
	for s.running {
		if !s.ready {
			s.log.gwarn('${@MOD}.${@FN}', 'not ready. Waiting 1 second...')
			time.sleep(1 * time.second)
			continue
		}

		s.state.fps_frame++
		s.state.frame++

		now := s.ticks()

		// count fps in 1 sec (1000 ms)
		if now >= fps_timer + 1000 {
			fps_timer = now
			s.state.fps_snapshot = s.state.fps_frame // - 1
			s.state.fps_frame = 0
		}

		// Process system events at this point
		s.process_events<T>(mut ctx)

		if s.shutdown {
			s.log.gdebug(@MOD + '.' + @FN, 'shutdown is $s.shutdown, leaving main loop...')
			break
		}

		root := s.api.wm.root
		mut windows := [root]

		if root.children.len > 0 {
			windows << root.children
		}
		for win in windows {
			if !win.ready {
				continue
			}
			win.make_current()

			// Ask gfx backend to clear the screen
			// s.api.gfx.begin()
			win.begin()

			// frame timer
			current_frame_time := i64(s.performance_counter())
			mut delta_time := current_frame_time - prev_frame_time
			prev_frame_time = current_frame_time

			// handle unexpected timer anomalies (overflow, extra slow frames, etc)
			// ignore extra-slow frames
			if delta_time > desired_frametime * 8 {
				delta_time = desired_frametime
			}
			if delta_time < 0 {
				delta_time = 0
			}

			// vsync time snapping
			for snap in snap_frequencies {
				if mth.abs(delta_time - snap) < vsync_maxerror {
					// eprintln('Snaping at $i')
					delta_time = snap
					break
				}
			}
			// Delta time averaging
			// for i := 0; i < time_history_count - 1; i++ {
			for i in 0 .. time_history_count - 1 {
				time_averager[i] = time_averager[i + 1]
			}
			time_averager[time_history_count - 1] = delta_time
			delta_time = 0
			// for i := 0; i < time_history_count; i++ {
			for i in 0 .. time_history_count {
				delta_time += time_averager[i]
			}
			delta_time /= time_history_count

			// add to the accumulator
			frame_accumulator += delta_time

			// spiral of death protection
			if frame_accumulator > desired_frametime * 8 {
				s.state.resync = true
			}

			// Timer resync if requested
			// Typical good after level load or similar
			if s.state.resync {
				frame_accumulator = 0
				delta_time = desired_frametime
				s.state.resync = false
			}

			// UNLOCKED FRAMERATE, INTERPOLATION ENABLED
			if !lock_framerate {
				mut consumed_delta_time := delta_time

				for frame_accumulator >= desired_frametime {
					// eprintln('(unlocked) s.fixed_update( $fixed_deltatime )')
					ctx.fixed_update(fixed_deltatime)

					if consumed_delta_time > desired_frametime {
						// cap variable update's dt to not be larger than fixed update,
						// and interleave it (so game state can always get animation frames it needs)

						// eprintln('(unlocked) 1 ctx.variable_update( $fixed_deltatime )')
						ctx.variable_update(fixed_deltatime)

						consumed_delta_time -= desired_frametime
					}
					frame_accumulator -= desired_frametime
				}

				c_dt := f64(consumed_delta_time) / s.performance_frequency()
				// eprintln('(unlocked) 2 ctx.variable_update( $c_dt )')
				ctx.variable_update(c_dt)

				f_dt := f64(frame_accumulator) / desired_frametime
				// eprintln('(unlocked) ctx.frame( $f_dt )')
				s.state.in_frame_call = true
				ctx.frame(f_dt)
			} else { // LOCKED FRAMERATE, NO INTERPOLATION
				for frame_accumulator >= desired_frametime * update_multiplicity {
					for i := 0; i < update_multiplicity; i++ {
						// eprintln('(locked) ctx.fixed_update( $fixed_deltatime )')
						ctx.fixed_update(fixed_deltatime)

						// eprintln('(locked) ctx.variable_update( $fixed_deltatime )')
						ctx.variable_update(fixed_deltatime)
						frame_accumulator -= desired_frametime
					}
				}

				// eprintln('(locked) ctx.frame( 1.0 )')
				s.state.in_frame_call = true
				ctx.frame(1.0)
			}
			s.state.in_frame_call = false
			s.api.on_frame_end()
			s.api.gfx.end()
			// win.end()
			s.api.gfx.commit()
			// win.commit()
			// display() / swap buffers
			// s.api.gfx.swap()
			win.swap()
		}
	}
	s.state.in_hot_code = false
}

// process_events processes all events and delegate them to T
fn (mut s Shy) process_events<T>(mut ctx T) {
	for {
		event := s.poll_event() or { break }
		ctx.event(event)
	}
}

fn (s Shy) check_api() ! {
	if isnil(s.api.wm) || isnil(s.api.gfx) || isnil(s.api.input) {
		return error('not all essential api systems where set')
	}
	if isnil(s.api.audio) {
		return error('not all audio api systems where set')
	}
	if isnil(s.api.gfx.draw) {
		return error('not all graphics api systems where set')
	}
	if isnil(s.api.input.mouse) || isnil(s.api.input.keyboard) {
		return error('not all input api systems where set')
	}
}

enum VetCategory {
	warn
}

enum VetArea {
	misc
	hot_code
}

[if shy_vet ?]
fn (s &Shy) vet_issue(c VetCategory, area VetArea, caller string, msg string) {
	mut prefix := caller + ' '
	prefix += match area {
		.misc { 'misc' }
		.hot_code { 'hot_code' }
	}
	match c {
		.warn {
			match area {
				.hot_code {
					if s.state.in_hot_code {
						s.log.gwarn('$shy.vet_tag ' + prefix, msg)
					}
				}
				else {
					s.log.gwarn('$shy.vet_tag ' + prefix, msg)
				}
			}
		}
	}
}
