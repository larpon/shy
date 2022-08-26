// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module shy

import os.font

struct API {
	ShyStruct
mut:
	wm          &WM
	gfx         &GFX
	audio       &Audio
	input       &Input
	system      &System
	font_system FontSystem
}

pub fn (mut a API) init(shy_instance &Shy) ! {
	mut s := unsafe { shy_instance }
	a.shy = s
	s.log.gdebug(@STRUCT + '.' + 'lifecycle', @FN + ' called')
	boot := Boot{
		shy: s
	}
	a.wm = boot.init()!

	a.system = &System{
		shy: s
	}

	a.audio = &Audio{
		shy: s
	}

	a.wm.init()!

	a.gfx = &GFX{
		shy: s
	}

	a.input = &Input{
		shy: s
	}

	a.audio.init()!
	a.gfx.init()!
	a.input.init()!

	// Initialize font drawing sub system
	a.font_system.init(FontSystemConfig{
		shy: s
		// prealloc_contexts: 8
		preload: {
			'system': font.default()
		}
	})! // font_system.b.v
}

pub fn (mut a API) shutdown() ! {
	s := a.shy
	s.log.gdebug(@STRUCT + '.' + 'lifecycle', @FN + ' called')

	a.input.shutdown()!
	a.font_system.shutdown()!
	a.gfx.shutdown()!
	a.audio.shutdown()!

	a.wm.shutdown()!
}

fn (mut a API) on_end_of_frame() {
	a.font_system.on_end_of_frame()
}
