// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module lib

import sdl

pub fn (mut m Mouse) init() ! {
	m.shy.log.gdebug('${@STRUCT}.${@FN}', '$m.id hi')

	// m.position(.window) doesn't work since SDL need mouse movement
	// before being able to generate *window local* mouse events
	win := m.shy.api.wm.root()
	w_x, w_y := win.position()
	w_w, w_h := win.wh()
	mgx, mgy := m.position(.global)
	if mgx > w_x && mgx < w_x + w_w && mgy > w_y && mgy < w_y + w_h {
		m.x = mgx - w_x
		m.y = mgy - w_y
	}
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
			mut mx, mut my := 0, 0
			sdl.get_global_mouse_state(&mx, &my)
			// println('global sdl: $mx,$my mouse: $m.x,$m.y')
			return mx, my
		}
		.window {
			mut mx, mut my := 0, 0
			sdl.get_mouse_state(&mx, &my)
			return mx, my
		}
	}
}
