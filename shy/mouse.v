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

pub fn (m Mouse) in_window(win &Window) bool {
	// m.position(.window) doesn't always work since SDL need mouse movement
	// before being able to generate *window local* mouse events
	w_x, w_y := win.position()
	w_w, w_h := win.size()
	mgx, mgy := m.position(.global)
	return mgx > w_x && mgx < w_x + w_w && mgy > w_y && mgy < w_y + w_h
}
