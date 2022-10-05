// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module lib

struct API {
	ShyStruct
mut:
	wm      &WM      = null
	gfx     &GFX     = null
	assets  &Assets  = null
	audio   &Audio   = null
	input   &Input   = null
	system  &System  = null
	scripts &Scripts = null
}

pub fn (mut a API) init(shy_instance &Shy) ! {
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

	// a.gfx.init_subsystems()!

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

pub fn (mut a API) shutdown() ! {
	a.shy.log.gdebug('${@STRUCT}.${@FN}', 'bye')

	a.input.shutdown()!
	a.scripts.shutdown()!
	a.assets.shutdown()!
	a.audio.shutdown()!
	a.system.shutdown()!
	a.wm.shutdown()!
	a.gfx.shutdown()!
	unsafe { a.free() }
}

[manualfree; unsafe]
fn (mut a API) free() {
	a.shy.log.gdebug('${@STRUCT}.${@FN}', '')
	unsafe {
		free(a.input)
		free(a.scripts)
		free(a.assets)
		free(a.gfx)
		free(a.audio)
		free(a.system)
		free(a.wm)
	}
}

pub fn (a &API) check_health() ! {
	if isnil(a.wm) || isnil(a.gfx) || isnil(a.input) {
		return error('${@STRUCT}.${@FN} not all essential api structs where set')
	}
	if isnil(a.scripts) {
		return error('${@STRUCT}.${@FN} not all script api structs where set')
	}
	if isnil(a.audio) {
		return error('${@STRUCT}.${@FN} not all audio api structs where set')
	}
	if isnil(a.gfx) || isnil(a.gfx.draw) {
		return error('${@STRUCT}.${@FN} not all graphics api structs where set')
	}
	/*
	// TODO
	if isnil(a.input.mouse(0)) || isnil(a.input.keyboard(0)) {
		return error('${@STRUCT}.${@FN} not all input api structs where set')
	}
	*/
}

pub fn (a &API) wm() &WM {
	return a.wm
}

pub fn (a &API) gfx() &GFX {
	return a.gfx
}

pub fn (a &API) assets() &Assets {
	return a.assets
}

pub fn (a &API) audio() &Audio {
	return a.audio
}

pub fn (a &API) input() &Input {
	return a.input
}

pub fn (a &API) system() &System {
	return a.system
}

pub fn (a &API) scripts() &Scripts {
	return a.scripts
}
