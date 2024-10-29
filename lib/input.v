// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module lib

@[heap]
pub struct Input {
	ShyStruct
mut:
	mice      map[u8]&Mouse
	keyboards map[u8]&Keyboard
	gamepads  []&Gamepad
}

pub fn (ip Input) mouse(n u8) ?&Mouse {
	if mouse := ip.mice[n] {
		return mouse
	}
	return none
}

pub fn (ip Input) keyboard(n u8) ?&Keyboard {
	if keyboard := ip.keyboards[n] {
		return keyboard
	}
	return none
}

pub fn (ip Input) gamepad(n i32) ?&Gamepad {
	for gamepad in ip.gamepads {
		if gamepad.id == n && !isnil(gamepad) {
			return unsafe { gamepad }
		}
	}
	return none
}

pub fn (ip Input) has_gamepad(n i32) bool {
	for gamepad in ip.gamepads {
		if gamepad.id == n {
			return true
		}
	}
	return false
}

pub const default_keyboard_id = u8(0)

@[heap]
pub struct Keyboard {
	ShyStruct
pub:
	id u8 // NOTE SDL doesn't really support multiple keyboard events, but who knows what the future holds?
mut:
	keys map[int]bool // key states, TODO(lmp): should be i32
}

@[inline]
pub fn (k &Keyboard) is_key_down(keycode KeyCode) bool {
	// TODO(lmp): workaround memory leak in code below. See https://github.com/vlang/v/issues/19454
	key_state := k.keys[int(keycode)]
	return key_state
	// if key_state := k.keys[int(keycode)] {
	//	return key_state
	//}
	// return false
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
	k.shy.log.gdebug('${@STRUCT}.${@FN}', '')
	// NOTE: pure function `on_keyboard_event` used instead of closure (k.on_event) for better support on platforms that does not support closures
	k.shy.api.events.on_event(on_keyboard_event)
}

fn on_keyboard_event(s &Shy, e Event) bool {
	// Exit as early as possible
	if e !is KeyEvent {
		return false
	}
	mut api := unsafe { s.api() }
	match e {
		KeyEvent {
			if mut k := api.input.keyboard(e.which) {
				return k.on_event(e)
			}
			return false
		}
		else {
			return false
		}
	}
	return false
}

fn (mut k Keyboard) on_event(e Event) bool {
	// Exit as early as possible
	if e !is KeyEvent {
		return false
	}
	match e {
		KeyEvent {
			if e.which == k.id {
				// eprintln('Setting key event for keyboard ${k.id}')
				k.set_key_state(e.key_code, e.state)
			}
			return false
		}
		else {
			return false
		}
	}
	return false
}
