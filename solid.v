// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module solid

import time
import solid.mth
import solid.log { Log }

pub const null = unsafe { nil }

pub enum Scope {
	shape_draw
	text_draw
}

pub enum ScopeAction {
	open
	close
}

// Solid carries all of solid's internal state.
[heap]
pub struct Solid {
	config    Config
	stopwatch time.StopWatch = time.new_stopwatch(auto_start: true)
pub mut:
	paused   bool
	shutdown bool
mut:
	log     Log
	ready   bool
	running bool
	resync  bool
	//
	fps_frame    u32
	fps_snapshot u32
	frame        u64
	//
	keys_state map[int]bool
	mb_state   map[int]bool
	// The backend blackbox - the implementation specific struct
	backend Backend
}

// new returns a new, initialized, `Solid` struct allocated in heap memory.
pub fn new(config Config) &Solid {
	mut s := &Solid{
		config: config
	}
	s.init()
	return s
}

// run runs the application instance `T`.
pub fn run<T>(mut ctx T, config Config) {
	mut solid_instance := new(config)
	ctx.solid = solid_instance
	ctx.init()

	main_loop<T>(mut ctx, mut solid_instance)

	ctx.quit()
	solid_instance.deinit()
}

fn main_loop<T>(mut ctx T, mut s Solid) {
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
	s.resync = true
	mut prev_frame_time := i64(s.performance_counter())
	mut frame_accumulator := i64(0)

	for s.running {
		if !s.ready {
			s.log.gwarn(@MOD + '.' + @FN + '.' + 'lifecycle', 'not ready. Waiting 1 second...')
			time.sleep(1 * time.second)
			continue
		}

		s.fps_frame++
		s.frame++

		now := s.ticks()

		// count fps in 1 sec (1000 ms)
		if now >= fps_timer + 1000 {
			fps_timer = now
			s.fps_snapshot = s.fps_frame // - 1
			s.fps_frame = 0
		}

		// Ask backend to clear the screen
		s.clear_screen()

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
		for i in 0 .. solid.time_history_count - 1 {
			time_averager[i] = time_averager[i + 1]
		}
		time_averager[solid.time_history_count - 1] = delta_time
		delta_time = 0
		// for i := 0; i < time_history_count; i++ {
		for i in 0 .. solid.time_history_count {
			delta_time += time_averager[i]
		}
		delta_time /= solid.time_history_count

		// add to the accumulator
		frame_accumulator += delta_time

		// spiral of death protection
		if frame_accumulator > desired_frametime * 8 {
			s.resync = true
		}

		// Timer resync if requested
		// Typical good after level load or similar
		if s.resync {
			frame_accumulator = 0
			delta_time = desired_frametime
			s.resync = false
		}

		// Process system events at this point
		s.process_events<T>(mut ctx)

		if s.shutdown {
			s.log.gdebug(@MOD + '.' + @FN, 'shutdown is $s.shutdown, leaving main loop...')
			break
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
			ctx.frame(f_dt)
			// display() / swap buffers
			s.display()
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
			ctx.frame(1.0)
			// display() / swap buffers
			s.display()
		}
	}
}

// process_events processes all events and delegate them to T
fn (mut s Solid) process_events<T>(mut ctx T) {
	for {
		event := s.poll_event() or { break }

		if event is MouseButtonEvent {
			solid_mouse_id := int(event.button)
			match event.state {
				.down {
					s.mb_state[solid_mouse_id] = true
				}
				.up {
					s.mb_state[solid_mouse_id] = false
				}
			}
		}
		if event is KeyEvent {
			solid_key_id := int(event.key_code)
			match event.state {
				.down {
					s.keys_state[solid_key_id] = true
				}
				.up {
					s.keys_state[solid_key_id] = false
				}
			}
		}

		ctx.event(event)

		// Handle debug output control here
		if event is KeyEvent {
			key_code := event.key_code
			if event.state == .down {
				if s.key_is_down(.comma) {
					if key_code == .s {
						s.log.print_status('STATUS')
						return
					}

					if key_code == .f1 {
						s.log.ginfo(@STRUCT + '.' + 'performance', 'Current FPS $s.fps_snapshot')
						return
					}

					if key_code == .f2 {
						s.log.ginfo(@STRUCT + '.' + 'performance', 'Current Performance Count $s.performance_counter()')
						return
					}

					if key_code == .f3 {
						s.log.ginfo(@STRUCT + '.' + 'performance', 'Current Performance Frequency $s.performance_frequency()')
						return
					}

					// Log print control
					if s.key_is_down(.l) {
						s.log.on(.log)

						if key_code == .f {
							s.log.toggle(.flood)
							return
						}
						if key_code == .minus || s.key_is_down(.minus) {
							s.log.off(.log)
						} else if key_code == ._1 {
							s.log.toggle(.info)
						} else if key_code == ._2 {
							s.log.toggle(.warn)
						} else if key_code == ._3 {
							s.log.toggle(.error)
						} else if key_code == ._4 {
							s.log.toggle(.debug)
						} else if key_code == ._5 {
							s.log.toggle(.critical)
						}
						return
					}
				}
			}
		}
	}
}

[inline]
pub fn (s Solid) fps() u32 {
	return s.fps_snapshot
}

pub fn (s Solid) ticks() u64 {
	return u64(s.stopwatch.elapsed().milliseconds())
}

pub fn (s Solid) key_is_down(keycode KeyCode) bool {
	if key_state := s.keys_state[int(keycode)] {
		return key_state
	}
	return false
}

pub fn (s Solid) is_mouse_button_held(button MouseButton) bool {
	if state := s.mb_state[int(button)] {
		return state
	}
	return false
}

pub fn (s Solid) window() Window {
	// TODO
	win := Window{
		ref: s.backend.window
		id: 0
	}
	return win
}
