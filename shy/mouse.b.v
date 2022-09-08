// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module shy

import sdl

pub fn (mut m Mouse) init() ! {
	m.shy.log.gdebug(@STRUCT + '.' + @FN, '$m.id hi')
}

pub fn (mut m Mouse) show() {
	sdl.show_cursor(sdl.enable)
}

pub fn (mut m Mouse) hide() {
	sdl.show_cursor(sdl.disable)
}

// xy returns the mouse coordinate relative to `position_type`.
pub fn (m Mouse) position(position_type MousePositionType) (int, int) {
	match position_type {
		.global {
			mut mx := 0
			mut my := 0
			sdl.get_global_mouse_state(&mx, &my)
			// println('global sdl: $mx,$my mouse: $m.x,$m.y')
			return mx, my
		}
		.window {
			mut mx := 0
			mut my := 0
			sdl.get_mouse_state(&mx, &my)
			return mx, my
		}
	}
}
