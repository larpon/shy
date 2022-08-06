// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module solid

pub enum MousePositionType {
	global
	window
}

// mouse_position
pub fn (s Solid) mouse_position(typ MousePositionType) (int, int) {
	match typ {
		.global {
			return s.global_mouse_position()
		}
		.window {
			return s.window_mouse_position()
		}
	}
}
