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
	assets &Assets
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

	a.wm.init()!

	a.audio = &Audio{
		shy: s
	}
	a.audio.init()!

	a.assets = &Assets{
		shy: s
	}
	a.assets.init()!

	a.gfx = &GFX{
		shy: s
	}
	a.gfx.init()!

	// Initialize font drawing sub system
	a.fonts.init(FontsConfig{
		shy: s
		// prealloc_contexts: 8
		preload: {
			'system': font.default()
		}
	})! // fonts.b.v

	a.input = &Input{
		shy: s
	}
	a.input.init()!
}

pub fn (mut a API) shutdown() ! {
	a.shy.log.gdebug(@STRUCT + '.' + @FN, 'bye')

	a.input.shutdown()!
	a.fonts.shutdown()!
	a.assets.shutdown()!
	a.gfx.shutdown()!
	a.audio.shutdown()!
	a.system.shutdown()!
	a.wm.shutdown()!
	unsafe { a.free() }
}

[unsafe]
fn (mut a API) free() {
	a.shy.log.gdebug(@STRUCT + '.' + @FN, '')
	unsafe {
		free(a.input)
		free(a.assets)
		free(a.fonts)
		free(a.gfx)
		free(a.audio)
		free(a.system)
		free(a.wm)
	}
}

fn (mut a API) on_frame_begin() {}

fn (mut a API) on_frame_end() {
	a.fonts.on_frame_end()
}
