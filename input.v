// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module shy

[heap]
pub struct Input {
	ShyStruct
mut:
	mice      map[u32]&Mouse
	keyboards map[u32]&Keyboard
	pads      []&Gamepad
}

pub fn (ip Input) mouse(n u32) !&Mouse {
	return ip.mice[n]
}

pub fn (ip Input) keyboard(n u32) !&Keyboard {
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
			k.keys[int(key_code)] = false
		}
		.down {
			k.keys[int(key_code)] = true
		}
	}
}

pub fn (mut k Keyboard) init() ! {
	k.shy.log.gdebug(@STRUCT + '.' + 'lifecycle', @FN + ' called')
}
