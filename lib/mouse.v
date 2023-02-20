// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module lib

pub const default_mouse_id = u8(0)

pub enum MouseButton {
	left
	right
	middle
	x1
	x2
	unknown // Only used as a last resort. I.e when converting from an external system fails.
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

pub type OnMouseMotionFn = fn (event MouseMotionEvent) bool

pub type OnMouseButtonFn = fn (event MouseButtonEvent) bool

[heap]
pub struct Mouse {
	ShyStruct
pub:
	id u8
mut:
	bs              map[int]bool // button states
	on_button_click []OnMouseButtonFn
	on_button_down  []OnMouseButtonFn
	on_button_up    []OnMouseButtonFn
	on_motion       []OnMouseMotionFn
pub mut:
	// mouse position inside window (canvas/drawable area coordinate space)
	x int
	y int
}

pub fn (mut m Mouse) on_motion(handler OnMouseMotionFn) {
	m.on_motion << handler
}

pub fn (mut m Mouse) on_button_click(handler OnMouseButtonFn) {
	m.on_button_click << handler
}

pub fn (mut m Mouse) on_button_down(handler OnMouseButtonFn) {
	m.on_button_down << handler
}

pub fn (mut m Mouse) on_button_up(handler OnMouseButtonFn) {
	m.on_button_up << handler
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
	w_w, w_h := win.wh()
	mgx, mgy := m.position(.global)
	return mgx > w_x && mgx < w_x + w_w && mgy > w_y && mgy < w_y + w_h
}
