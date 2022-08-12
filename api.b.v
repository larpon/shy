// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module solid

import os.font
// Some code found from
// "Minimal sprite rendering example with SDL2 for windowing, sokol_gfx for graphics API using OpenGL 3.3 on MacOS"
// https://gist.github.com/sherjilozair/c0fa81250c1b8f5e4234b1588e755bca
import sdl

pub fn (mut a API) init(solid_instance &Solid) ! {
	mut s := unsafe { solid_instance }
	a.solid = s
	boot := Boot{
		solid: s
	}
	a.wm = boot.init()!

	s.log.gdebug(@STRUCT + '.' + 'lifecycle', @FN + ' called')

	a.wm.init()!

	a.gfx = &GFX{
		solid: s
	}
	a.mouse = &Mouse{
		solid: s
	}

	a.gfx.init()!
	a.mouse.init()!

	// TODO move to input sub system
	// Initialize input systems (keyboard, mouse etc.)
	a.init_input()

	// Initialize font drawing sub system
	a.font_system.init(FontSystemConfig{
		solid: s
		// prealloc_contexts: 8
		preload: {
			'system': font.default()
		}
	}) // font_system.b.v

	// Initialize drawing sub system
	a.shape_draw_system.init(&s) // shape_draw_system.b.v
}

fn (mut a API) init_input() {
	mut s := a.solid
	// Check for joysticks/game controllers
	if sdl.num_joysticks() < 1 {
		s.log.ginfo(@STRUCT + '.' + 'input', 'no joysticks or game controllers connected')
	} else {
		// Load joystick(s)
		for i in 0 .. 5 {
			/*
			controller = sdl.joystick_open(i)
			if isnil(game_controller) {
				error_msg := unsafe { cstring_to_vstring(sdl.get_error()) }
				println('Warning: Unable to open controller $i SDL Error: $error_msg' )
				continue
			}*/
			if sdl.is_game_controller(i) {
				controller := sdl.game_controller_open(i)
				if controller == sdl.null {
					error_msg := unsafe { cstring_to_vstring(sdl.get_error()) }
					s.log.gerror(@STRUCT + '.' + 'input', 'unable to open controller $i:\n$error_msg')
					continue
				}
				controller_name := unsafe { cstring_to_vstring(sdl.game_controller_name_for_index(i)) }
				s.log.ginfo(@STRUCT + '.' + 'input', 'detected controller $i as "$controller_name"')
				s.api.controllers[i] = controller

				// Open the device
				haptic := sdl.haptic_open_from_joystick(sdl.game_controller_get_joystick(controller))
				if haptic == sdl.null {
					// error_msg := unsafe { cstring_to_vstring(sdl.get_error()) }
					s.log.ginfo(@STRUCT + '.' + 'input', 'controller $i ($controller_name) does not seem to have haptic features')
				} else {
					// See if it can do sine waves
					if (sdl.haptic_query(haptic) & u32(sdl.haptic_sine)) == 0 {
						s.log.ginfo(@STRUCT + '.' + 'input', 'controller $i ($controller_name) does not seem to have haptic SINE effects')
					} else {
						/*
						// Create the effect
						mut effect := sdl.HapticEffect{}
						unsafe {
							vmemset( &effect, 0, int(sizeof(effect)) ) // 0 is safe default
						}

						effect.@type = u16(sdl.haptic_sine)
						effect.periodic.direction.@type = u8(sdl.haptic_polar) // Polar coordinates
						effect.periodic.direction.dir[0] = 18000 // Force comes from south
						effect.periodic.period = 1000 // 1000 ms
						effect.periodic.magnitude = 20000 // 20000/32767 strength
						effect.periodic.length = 5000 // 5 seconds long
						effect.periodic.attack_length = 1000 // Takes 1 second to get max strength
						effect.periodic.fade_length = 1000 // Takes 1 second to fade away

						// Upload the effect
						effect_id := sdl.haptic_new_effect( haptic, &effect )

						// Test the effect
						sdl.haptic_run_effect( haptic, effect_id, 1 )
						sdl.delay( 5000) // Wait for the effect to finish

						// We destroy the effect, although closing the device also does this
						sdl.haptic_destroy_effect( haptic, effect_id )
						*/
					}
				}
				// Close the device
				sdl.haptic_close(haptic)
			} else {
				// sdl.joystick_close(i)
				// eprintln('Warning: Not adding controller $i - not a game controller' )
				continue
			}
		}
	}
}

pub fn (mut a API) shutdown() ! {
	s := a.solid
	s.log.gdebug(@STRUCT + '.' + 'lifecycle', @FN + ' called')

	a.font_system.shutdown()

	a.shape_draw_system.shutdown()

	a.gfx.shutdown()!

	a.wm.shutdown()!

	s.log.gdebug(@STRUCT + '.' + 'death', 'bye bye')
	s.log.free()
}

pub fn (s &Solid) draw2d() Draw2D {
	mut d2d := Draw2D{}
	d2d.init(s)
	return d2d
}

struct API {
mut:
	solid &Solid = unsafe { nil }
pub mut:
	wm    &WM
	gfx   &GFX
	mouse &Mouse
	// Font backend
	font_system FontSystem
	//
	shape_draw_system ShapeDrawSystem
	//
	controllers map[int]&sdl.GameController
}

fn (mut a API) on_end_of_frame() {
	a.font_system.on_end_of_frame()
}

pub fn (a API) performance_counter() u64 {
	return sdl.get_performance_counter()
}

pub fn (a API) performance_frequency() u64 {
	return sdl.get_performance_frequency()
}
