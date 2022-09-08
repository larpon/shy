// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module shy

pub const default_mouse_id = u8(0)

pub enum MouseButton {
	left
	right
	middle
	x1
	x2
}

[flag]
pub enum MouseButtons {
	left
	right
	middle
	x1
	x2
}

pub enum MousePositionType {
	global
	window
}

pub enum MouseWheelDirection {
	normal
	flipped
}

pub struct Mouse {
	ShyStruct
pub:
	id u8
mut:
	bs map[int]bool // button states
pub mut:
	x int
	y int
}

pub fn (mut m Mouse) set_button_state(button MouseButton, button_state ButtonState) {
	match button_state {
		.up {
			m.bs[int(button)] = false
		}
		.down {
			m.bs[int(button)] = true
		}
	}
}

[inline]
pub fn (m &Mouse) is_button_down(button MouseButton) bool {
	if state := m.bs[int(button)] {
		return state
	}
	return false
}
