// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module lib

import time
import shy.analyse
import shy.mth

#include <emscripten.h>

fn C.emscripten_set_main_loop_arg(fn (voidptr), voidptr, int, bool)
fn C.emscripten_cancel_main_loop()

type FnWithVoidptrArgument = fn (voidptr)

fn (mut a ShyAPI) emscripten_main[T](mut ctx T, mut s Shy) ! {
	s.log.gdebug('${@MOD}.${@FN}', 'entering emscripten core loop')

	s.running = true
	s.state.in_hot_code = true

	// Kudos to @spytheman for this way of passing generics to C
	f := FnWithVoidptrArgument(emscripten_main_impl[T])
	C.emscripten_set_main_loop_arg(f, voidptr(ctx), 0, true)

	s.state.in_hot_code = false
}

fn emscripten_main_impl[T](mut ctx T) {
	mut app := unsafe { &T(ctx) }
	mut s := app.shy

	mut api := unsafe { s.api() }
	wm := api.wm()
	mut events := unsafe { api.events() }

	mut root := wm.root

	// if !s.ready {
	// 	s.log.gwarn('${@MOD}.${@FN}', 'not ready. Waiting 1 second...')
	// 	time.sleep(1 * time.second)
	// 	s.timer.restart()
	// 	// continue
	// }
	$if shy_analyse ? {
		analyse.count('${@MOD}.${@STRUCT}.${@FN}.running', 1)
	}

	// Process events
	for {
		event := events.poll() or { break }
		app.event(event)
	}

	// Update alarms
	s.alarms.update()

	// Update assets (async loading)
	api.assets.update()

	// Since Shy is, currently, single threaded windows
	// will render their own children. So, this is a cascade action.
	s.state.rendering = true
	root.tick_and_render(mut app)
	s.state.rendering = false

	if s.shutdown {
		s.log.gdebug('${@MOD}.${@FN}', 'shutdown is ${s.shutdown}, leaving main loop...')
		s.running = false
		C.emscripten_cancel_main_loop()
		return
	}
}
