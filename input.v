// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module shy

[heap]
pub struct Input {
mut:
	shy     &Shy
	mice      []&Mouse
	keyboards []&Keyboard
	pads      []&Gamepad
}

pub fn (mut ip Input) mouse(n int) !&Mouse {
	return ip.mice[0]
}

pub fn (mut ip Input) keyboard(n int) !&Keyboard {
	return ip.keyboards[n]
}

pub struct Keyboard {
mut:
	shy &Shy
	keys  map[int]bool // key states
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
