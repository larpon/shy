// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module lib

// import time
import shy.analyse
// import shy.mth

#include <emscripten.h>
#include <emscripten/html5.h>

// Types (em_types.h)

// type EmResult = C.EMSCRIPTEN_RESULT // int

enum EmResult {
	success             = C.EMSCRIPTEN_RESULT_SUCCESS             // 0
	deferred            = C.EMSCRIPTEN_RESULT_DEFERRED            // 1
	not_supported       = C.EMSCRIPTEN_RESULT_NOT_SUPPORTED       // -1
	failed_not_deferred = C.EMSCRIPTEN_RESULT_FAILED_NOT_DEFERRED // -2
	invalid_target      = C.EMSCRIPTEN_RESULT_INVALID_TARGET      // -3
	unknown_target      = C.EMSCRIPTEN_RESULT_UNKNOWN_TARGET      // -4
	invalid_param       = C.EMSCRIPTEN_RESULT_INVALID_PARAM       // -5
	failed              = C.EMSCRIPTEN_RESULT_FAILED              // -6
	no_data             = C.EMSCRIPTEN_RESULT_NO_DATA             // -7
	timed_out           = C.EMSCRIPTEN_RESULT_TIMED_OUT           // -8
}

// emscripten.h
fn C.emscripten_set_main_loop_arg(fn (voidptr), voidptr, int, bool)
fn C.emscripten_cancel_main_loop()
fn C.emscripten_run_script_int(charptr) int

// html5.h
fn C.emscripten_get_canvas_element_size(const_target &char, width &int, height &int) EmResult
fn C.emscripten_set_canvas_element_size(const_target &char, width int, height int) EmResult

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

fn emscripten_get_canvas_width() int {
	width := C.emscripten_run_script_int(c'document.querySelector("#canvas").width;')
	return width
}

fn emscripten_get_canvas_height() int {
	height := C.emscripten_run_script_int(c'document.querySelector("#canvas").height;')
	return height
}
