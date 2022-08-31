// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module shy

import os.font

struct API {
	ShyStruct
mut:
	wm     &WM
	gfx    &GFX
	audio  &Audio
	input  &Input
	system &System
	fonts  Fonts
}

pub fn (mut a API) init(shy_instance &Shy) ! {
	mut s := unsafe { shy_instance }
	a.shy = s
	s.log.gdebug(@STRUCT + '.' + @FN, 'hi')
	boot := Boot{
		shy: s
	}
	a.wm = boot.init()!

	a.system = &System{
		shy: s
	}
	a.system.init()!

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

	// Initialize font drawing sub system
	a.fonts.init(FontsConfig{
		shy: s
		// prealloc_contexts: 8
		preload: {
			'system': font.default()
		}
	})! // fonts.b.v

	a.input.init()!
}

pub fn (mut a API) shutdown() ! {
	s := a.shy
	s.log.gdebug(@STRUCT + '.' + @FN, 'bye')

	a.input.shutdown()!
	a.fonts.shutdown()!
	a.gfx.shutdown()!
	a.audio.shutdown()!
	a.system.shutdown()!
	a.wm.shutdown()!
}

fn (mut a API) on_frame_begin() {}

fn (mut a API) on_frame_end() {
	a.fonts.on_frame_end()
}
