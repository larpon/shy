// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module lib

import os
import time
import shy.analyse
// import shy.mth

#include <emscripten.h>
#include <emscripten/html5.h>

#flag wasm32_emscripten -lidbfs.js -sFORCE_FILESYSTEM
// #flag wasm32_emscripten -sEXPORTED_RUNTIME_METHODS=["FS"]
// -sWASMFS
// Types (em_types.h)

// type EmResult = C.EMSCRIPTEN_RESULT // int

const shy_js_fs_root = '/shy' // NOTE: can not be `/` ...

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
fn C.emscripten_run_script(charptr)
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

	// Update assets (tick the async loading)
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

fn emscripten_init() ! {
	C.emscripten_run_script(c'Module.Shy = {
	debug: function(){let a = Array.prototype.slice.call(arguments);a.unshift("shy");console.debug.apply(console,a);},
	error: function(){let a = Array.prototype.slice.call(arguments);a.unshift("shy");console.error.apply(console,a);}
};')
	emscripten_fs_init()!
}

// emscripten_fs_init initializes the emscripten virtual (IndexDB / IDBFS) filesystem.
// It should be called as early as possible *before* shy's userspace / context `init/1`
fn emscripten_fs_init() ! {
	$if wasm32_emscripten {
		emscripten_mount_fs() or {
			return error('${@MOD}.${@FN} mounting emscripten virtual filesystem failed, state can not be preserved. ${err}')
		}
		mut retries := u8(10)
		for !emscripten_fs_ready() {
			retries--
			if retries <= 0 {
				break
			}
			// eprintln('${@MOD}.${@FN} not ready. Waiting 1 second...')
			time.sleep(1 * time.second)
		}
		if !emscripten_fs_ready() {
			return error('${@MOD}.${@FN} timeout waiting for emscripten virtual filesystem. Still not ready, state can not be preserved')
		}
	}
}

// emscripten_mount_fs mounts the "root" folder in the browser
fn emscripten_mount_fs() ! {
	// https://stackoverflow.com/questions/75543945/wasm-idbfs-not-persistent
	path := shy_js_fs_root
	C.emscripten_run_script('const Shy = Module.Shy;
const path = "${path}";
try {
	// Shy.debug("${@FN}", "Calling FS.mkdir...");
	FS.mkdir(path);
} catch(e) {
	const v_fn = "${@FN}";
	Shy.error(v_fn, "FS.mkdir threw an exception", e);
	Shy.error(v_fn, "all write filesystem operations may not persist");
};
// Then mount with IDBFS type
FS.mount(FS.filesystems.IDBFS, {autoPersist: true}, path);
// Then sync
FS.syncfs(true, function (err) {
	if (err) { Shy.error("${@FN}", "FS.syncfs failed", err); }
	assert(!err);
});
'.str)
	return
}

fn emscripten_fs_ready() bool {
	path := shy_js_fs_root
	ok_file := os.join_path(path, '.shy')
	os.rm(ok_file) or {}
	os.write_file(ok_file, 'shy') or { return false }
	res := os.is_file(ok_file)
	if res {
		os.rm(ok_file) or { return false }
	}
	return res
}

fn debug_emscripten_mount_fs() ! {
	path := shy_js_fs_root
	C.emscripten_run_script('
function fsDeleteAllFiles(folder) {
  function impl(curFolder) {
    for (const name of FS.readdir(curFolder)) {
      if (name === "." || name === "..") continue;
      const path = `\${curFolder}/\${name}`;
      const { mode, timestamp } = FS.lookupPath(path).node;
      if (FS.isFile(mode)) {
		console.log("del fil",path);
		FS.unlink(path)
      } else if (FS.isDir(mode)) {
        impl(path);
		FS.rmdir(path)
		console.log("del dir",path);
      }
    }
  }
  impl(folder);
}

const path = "${path}";
try {
	FS.mkdir(path);
} catch(e) {
	console.error(\'shy\',\'FS.mount (emscripten_mount_fs) threw an exception\',e);
	console.error(\'shy\',\'FS.mount (emscripten_mount_fs) all write filesystem operations may not persist\');
	// fsDeleteAllFiles(path);
	// FS.rmdir(path);
	// FS.unmount(path);
	// FS.mkdir(path);
};
// Then mount with IDBFS type
FS.mount(FS.filesystems.IDBFS, {autoPersist: true}, path);
// Then sync
FS.syncfs(true, function (err) {
	if (err) { console.error(\'shy\',\'syncfs (emscripten_mount_fs) failed\',err); }
	assert(!err);
});
// const s = FS.analyzePath(path);
// if (!s.exists) {}
'.str)
	return
}
