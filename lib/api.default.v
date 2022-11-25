// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module lib

import time

// ShyAPI is the *default* API implementation.
// The methods and members define what sub-systems
// is available and can be accessed publically.
//
// The `ShyAPI` struct is the default embedded struct of the
// wrapper `API` struct defined in `lib/api.v`.
// The API can be replaced and/or expanded as needed.
// Hopefully we do not need to write many new API's
// but rather modify or re-write the sub-systems instead.
// (It will most likely be the GFX and WM/Window sub-systems).
pub struct ShyAPI {
	ShyStruct
mut:
	wm      &WM      = null
	gfx     &GFX     = null
	draw    &Draw    = null
	assets  &Assets  = null
	audio   &Audio   = null
	input   &Input   = null
	system  &System  = null
	scripts &Scripts = null
}

pub fn (mut a ShyAPI) init(shy_instance &Shy) ! {
	mut s := unsafe { shy_instance }
	a.shy = s
	s.log.gdebug('${@STRUCT}.${@FN}', 'hi')
	boot := Boot{
		shy: s
	}
	a.wm = boot.init()!

	a.system = &System{
		shy: s
	}
	a.system.init()!

	a.assets = &Assets{
		shy: s
	}
	a.assets.init()!

	a.gfx = &GFX{
		shy: s
	}
	$if !wasm32_emscripten {
		// NOTE When targeting WASM/emscripten graphics needs to be initialized
		// after the first GL context is set. This could arguably be structured
		// more optimal. Instead the windowing system will initialize the gfx
		// when needed. See Window.init() method.
		a.gfx.init()!
	}

	a.wm.init()!

	a.draw = &Draw{
		shy: s
	}
	a.draw.init()!

	a.audio = &Audio{
		shy: s
	}
	a.audio.init()!

	a.scripts = &Scripts{
		shy: s
	}
	a.scripts.init()!

	a.input = &Input{
		shy: s
	}
	a.input.init()!
}

pub fn (mut a ShyAPI) shutdown() ! {
	a.shy.log.gdebug('${@STRUCT}.${@FN}', '')

	a.input.shutdown()!
	a.scripts.shutdown()!
	a.draw.shutdown()!
	a.assets.shutdown()!
	a.audio.shutdown()!
	a.system.shutdown()!
	a.wm.shutdown()!
	a.gfx.shutdown()!
	unsafe { a.free() }
}

[manualfree; unsafe]
fn (mut a ShyAPI) free() {
	a.shy.log.gdebug('${@STRUCT}.${@FN}', '')
	unsafe {
		free(a.input)
		free(a.scripts)
		free(a.assets)
		free(a.draw)
		free(a.gfx)
		free(a.audio)
		free(a.system)
		free(a.wm)
	}
}

// health returns an error if something in the API isn't working
// as expected, nothing otherwise.
pub fn (a &ShyAPI) health() ! {
	if isnil(a.wm) || isnil(a.input) {
		return error('${@STRUCT}.${@FN} not all essential api structs where set')
	}
	if isnil(a.scripts) {
		return error('${@STRUCT}.${@FN} not all script api structs where set')
	}
	if isnil(a.audio) {
		return error('${@STRUCT}.${@FN} not all audio api structs where set')
	}
	if isnil(a.gfx) || isnil(a.draw) {
		return error('${@STRUCT}.${@FN} not all graphics api structs where set')
	}
	/*
	// TODO
	if isnil(a.input.mouse(0)) || isnil(a.input.keyboard(0)) {
		return error('${@STRUCT}.${@FN} not all input api structs where set')
	}
	*/
}

pub fn (a &ShyAPI) wm() &WM {
	return a.wm
}

pub fn (a &ShyAPI) gfx() &GFX {
	return a.gfx
}

pub fn (a &ShyAPI) assets() &Assets {
	return a.assets
}

pub fn (a &ShyAPI) draw() &Draw {
	return a.draw
}

pub fn (a &ShyAPI) audio() &Audio {
	return a.audio
}

pub fn (a &ShyAPI) input() &Input {
	return a.input
}

pub fn (a &ShyAPI) system() &System {
	return a.system
}

pub fn (a &ShyAPI) scripts() &Scripts {
	return a.scripts
}

// V embeds with generics is not quite ready yet.
// TODO BUG WORKAROUND this should've been:
pub fn (mut a ShyAPI) main<T>(mut ctx T, mut s Shy) ! {
	// pub fn api_main<T>(mut ctx T, mut s Shy) ! {
	s.log.gdebug('${@MOD}.${@FN}', 'entering core loop')

	mut api := unsafe { s.api() }

	wm := api.wm()
	mut input := unsafe { api.input() }

	mut root := wm.root

	s.running = true
	s.state.in_hot_code = true
	for s.running {
		if !s.ready {
			s.log.gwarn('${@MOD}.${@FN}', 'not ready. Waiting 1 second...')
			time.sleep(1 * time.second)
			s.timer.restart()
			continue
		}

		// TODO re-write event processing to be per window?
		// Process system events
		for {
			event := input.poll_event() or { break }
			ctx.event(event)
		}

		// Windows will render their children, so this is a cascade action
		s.state.rendering = true
		root.render<T>(mut ctx)
		s.state.rendering = false

		if s.shutdown {
			s.log.gdebug('${@MOD}.${@FN}', 'shutdown is ${s.shutdown}, leaving main loop...')
			s.running = false
			break
		}
	}
	s.state.in_hot_code = false
}
