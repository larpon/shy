// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module shy

import sdl

// TODO move
pub struct Gamepad {
	id int
mut:
	shy     &Shy
	name      string
	handle    &sdl.GameController
	is_haptic bool
}

pub fn (mut gp Gamepad) init() ! {
	s := gp.shy
	// Open the device
	haptic := sdl.haptic_open_from_joystick(sdl.game_controller_get_joystick(gp.handle))
	if haptic == sdl.null {
		// error_msg := unsafe { cstring_to_vstring(sdl.get_error()) }
		s.log.ginfo(@STRUCT + '.' + 'input', 'controller $gp.id ($gp.name) does not seem to have haptic features')
	} else {
		// See if it can do sine waves
		if (sdl.haptic_query(haptic) & u32(sdl.haptic_sine)) == 0 {
			s.log.gdebug(@STRUCT + '.' + 'input', 'controller $gp.id ($gp.name) does not seem to support haptic SINE effects')
		} else {
			gp.is_haptic = true
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
}

// init initializes input systems (keyboard, mouse etc.)
pub fn (mut ip Input) init() ! {
	ip.shy.log.gdebug(@STRUCT + '.' + 'lifecycle', @FN + ' called')
	s := ip.shy
	mut mouse := &Mouse{
		shy: s
	}
	mouse.init()!
	ip.mice << mouse

	mut keyboard := &Keyboard{
		shy: s
	}
	keyboard.init()!
	ip.keyboards << keyboard
	ip.init_input()!
}

fn (mut ip Input) init_input() ! {
	mut s := ip.shy
	// Check for joysticks/game controllers
	if sdl.num_joysticks() < 1 {
		s.log.ginfo(@STRUCT + '.' + 'input', 'no joysticks or game controllers connected')
	} else {
		// Load joystick(s) / controller(s)
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

				mut pad := &Gamepad{
					id: i
					shy: s
					name: controller_name
					handle: controller
				}
				pad.init()!
				ip.pads << pad
				// s.api.controllers[i] = controller
			} else {
				// sdl.joystick_close(i)
				// eprintln('Warning: Not adding controller $i - not a game controller' )
				continue
			}
		}
	}
}
