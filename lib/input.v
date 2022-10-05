// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module lib

[heap]
pub struct Input {
	ShyStruct
mut:
	mice      map[u8]&Mouse
	keyboards map[u8]&Keyboard
	pads      []&Gamepad
}

pub fn (ip Input) mouse(n u8) !&Mouse {
	return ip.mice[n]
}

pub fn (ip Input) keyboard(n u8) !&Keyboard {
	return ip.keyboards[n]
}

pub struct Keyboard {
	ShyStruct
mut:
	keys map[int]bool // key states
}

[inline]
pub fn (k Keyboard) is_key_down(keycode KeyCode) bool {
	if key_state := k.keys[int(keycode)] {
		return key_state
	}
	return false
}

pub fn (mut k Keyboard) set_key_state(key_code KeyCode, button_state ButtonState) {
	match button_state {
		.up {
			k.keys[i32(key_code)] = false
		}
		.down {
			k.keys[i32(key_code)] = true
		}
	}
}

pub fn (mut k Keyboard) init() ! {
	k.shy.log.gdebug('${@STRUCT}.${@FN}', 'hi')
}
