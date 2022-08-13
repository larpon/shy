// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module shy

import os.font
// Some code found from
// "Minimal sprite rendering example with SDL2 for windowing, sokol_gfx for graphics API using OpenGL 3.3 on MacOS"
// https://gist.github.com/sherjilozair/c0fa81250c1b8f5e4234b1588e755bca
import sdl

pub fn (mut a API) init(shy_instance &Shy) ! {
	mut s := unsafe { shy_instance }
	a.shy = s
	s.log.gdebug(@STRUCT + '.' + 'lifecycle', @FN + ' called')
	boot := Boot{
		shy: s
	}
	a.wm = boot.init()!

	a.wm.init()!

	a.gfx = &GFX{
		shy: s
	}

	a.input = &Input{
		shy: s
	}

	a.gfx.init()!
	a.input.init()!

	// Initialize font drawing sub system
	a.font_system.init(FontSystemConfig{
		shy: s
		// prealloc_contexts: 8
		preload: {
			'system': font.default()
		}
	}) // font_system.b.v

	// Initialize drawing sub system
	a.shape_draw_system.init(&s) // shape_draw_system.b.v

	s.wm = a.wm
	s.gfx = a.gfx
	s.input = a.input
}

pub fn (mut a API) shutdown() ! {
	s := a.shy
	s.log.gdebug(@STRUCT + '.' + 'lifecycle', @FN + ' called')

	a.shape_draw_system.shutdown()

	a.font_system.shutdown()

	a.gfx.shutdown()!

	a.wm.shutdown()!
}

pub fn (s &Shy) draw2d() Draw2D {
	mut d2d := Draw2D{}
	d2d.init(s)
	return d2d
}

struct API {
mut:
	shy &Shy = shy.null
pub mut:
	wm    &WM
	gfx   &GFX
	input &Input
	// Font backend
	font_system FontSystem
	//
	shape_draw_system ShapeDrawSystem
}

fn (mut a API) on_end_of_frame() {
	a.font_system.on_end_of_frame()
}

pub fn (a API) performance_counter() u64 {
	return sdl.get_performance_counter()
}

pub fn (a API) performance_frequency() u64 {
	return sdl.get_performance_frequency()
}
