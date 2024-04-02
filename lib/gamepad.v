// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module lib

import sdl

pub const default_gamepad_id = i32(0)

pub enum GamepadButton {
	invalid
	a
	b
	x
	y
	back
	guide
	start
	left_stick
	right_stick
	left_shoulder
	right_shoulder
	dpad_up
	dpad_down
	dpad_left
	dpad_right
	misc_1
	paddle_1
	paddle_2
	paddle_3
	paddle_4
	touchpad
	// max
}

pub fn GamepadButton.from_sdl_controller_button(button sdl.GameControllerButton) GamepadButton {
	$if shy_gamepad ? {
		return match button {
			.invalid {
				GamepadButton.invalid
			}
			.a {
				GamepadButton.a
			}
			.b {
				GamepadButton.b
			}
			.x {
				GamepadButton.x
			}
			.y {
				GamepadButton.y
			}
			.back {
				GamepadButton.back
			}
			.guide {
				GamepadButton.guide
			}
			.start {
				GamepadButton.start
			}
			.leftstick {
				GamepadButton.left_stick
			}
			.rightstick {
				GamepadButton.right_stick
			}
			.leftshoulder {
				GamepadButton.left_shoulder
			}
			.rightshoulder {
				GamepadButton.right_shoulder
			}
			.dpad_up {
				GamepadButton.dpad_up
			}
			.dpad_down {
				GamepadButton.dpad_down
			}
			.dpad_left {
				GamepadButton.dpad_left
			}
			.dpad_right {
				GamepadButton.dpad_right
			}
			.misc1 {
				GamepadButton.misc_1
			}
			.paddle1 {
				GamepadButton.paddle_1
			}
			.paddle2 {
				GamepadButton.paddle_2
			}
			.paddle3 {
				GamepadButton.paddle_3
			}
			.paddle4 {
				GamepadButton.paddle_4
			}
			.touchpad {
				GamepadButton.touchpad
			}
			.max {
				GamepadButton.invalid
			}
		}
	} $else {
		return GamepadButton.invalid
	}
}

pub enum GamepadAxis {
	invalid
	left_x
	left_y
	right_x
	right_y
	trigger_left
	trigger_right
}

pub fn GamepadAxis.from_sdl_controller_axis(axis sdl.GameControllerAxis) GamepadAxis {
	$if shy_gamepad ? {
		return match axis {
			.invalid {
				GamepadAxis.invalid
			}
			.leftx {
				GamepadAxis.left_x
			}
			.lefty {
				GamepadAxis.left_y
			}
			.rightx {
				GamepadAxis.right_x
			}
			.righty {
				GamepadAxis.right_y
			}
			.triggerleft {
				GamepadAxis.trigger_left
			}
			.triggerright {
				GamepadAxis.trigger_right
			}
			.max {
				GamepadAxis.invalid
			}
		}
	} $else {
		return GamepadAxis.invalid
	}
}

pub enum GamepadSensorType {
	invalid
	unknown
	accelerometer
	gyroscope
	sensor_accelerometer_left
	sensor_gyroscope_left
	sensor_accelerometer_right
	sensor_gyroscope_right
}

pub fn GamepadSensorType.from_sdl_sensor_type(sensor_type sdl.SensorType) GamepadSensorType {
	$if shy_gamepad ? {
		return match sensor_type {
			.invalid {
				GamepadSensorType.invalid
			}
			.unknown {
				GamepadSensorType.unknown
			}
			.accel {
				GamepadSensorType.accelerometer
			}
			.gyro {
				GamepadSensorType.gyroscope
			}
			.sensor_accel_l {
				GamepadSensorType.sensor_accelerometer_left
			}
			.sensor_gyro_l {
				GamepadSensorType.sensor_gyroscope_left
			}
			.sensor_accel_r {
				GamepadSensorType.sensor_accelerometer_right
			}
			.sensor_gyro_r {
				GamepadSensorType.sensor_gyroscope_right
			}
		}
	} $else {
		return GamepadSensorType.invalid
	}
}

pub struct Gamepad {
	ShyStruct
	id i32
mut:
	name          string
	handle        &sdl.GameController
	is_haptic     bool
	button_states map[int]bool // key states, TODO(lmp) should be i32
}

pub fn (mut gp Gamepad) init() ! {
	gp.shy.log.gdebug('${@STRUCT}.${@FN}', '')
	s := gp.shy
	// Open the device
	haptic := sdl.haptic_open_from_joystick(sdl.game_controller_get_joystick(gp.handle))
	if haptic == sdl.null {
		// error_msg := unsafe { cstring_to_vstring(sdl.get_error()) }
		s.log.gdebug('${@STRUCT}.${@FN}', 'controller ${gp.id} (${gp.name}) does not seem to have haptic features')
	} else {
		// See if it can do sine waves
		if (sdl.haptic_query(haptic) & u32(sdl.haptic_sine)) == 0 {
			s.log.gdebug('${@STRUCT}.${@FN}', 'controller ${gp.id} (${gp.name}) does not seem to support haptic SINE effects')
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

@[inline]
pub fn (gp &Gamepad) is_button_down(button GamepadButton) bool {
	// TODO(lmp) workaround memory leak in code below. See https://github.com/vlang/v/issues/19454
	key_state := gp.button_states[int(button)]
	return key_state
	// if key_state := k.keys[int(keycode)] {
	//	return key_state
	//}
	// return false
}

pub fn (mut gp Gamepad) set_button_state(button GamepadButton, button_state ButtonState) {
	gp.button_states[int(button)] = match button_state {
		.up {
			false
		}
		.down {
			true
		}
	}
}
