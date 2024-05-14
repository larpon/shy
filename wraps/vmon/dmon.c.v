// Copyright(C) 2021-2022 Lars Pontoppidan. All rights reserved.

module vmon

import os
import sync
import c

const used_import = c.used_import
const ctx = &Context(unsafe { nil }) // Sorry - I could find no other way - this is C interop :(

pub enum WatchFlag {
	recursive       = C.DMON_WATCHFLAGS_RECURSIVE // 0x1, monitor all child directories
	follow_symlinks = C.DMON_WATCHFLAGS_FOLLOW_SYMLINKS // 0x2, resolve symlinks (linux only)
	// outofscope_links = C.DMON_WATCHFLAGS_OUTOFSCOPE_LINKS // 0x4, TODO not implemented in dmon C yet
	// ignore_directories = C.DMON_WATCHFLAGS_IGNORE_DIRECTORIES // 0x8, TODO not implemented in dmon C yet
}

// Action is c.dmon_action
pub enum Action {
	create = C.DMON_ACTION_CREATE // = 1,
	delete = C.DMON_ACTION_DELETE
	modify = C.DMON_ACTION_MODIFY
	move   = C.DMON_ACTION_MOVE
}

type FnWatchCallback = fn (watch_id WatchID, action Action, root_path string, file_path string, old_file_path string, user_data voidptr)

// fn watch_cb(watch_id C.dmon_watch_id, action C.dmon_action, rootdir charptr, filepath charptr, oldfilepath charptr, user voidptr) { }
// voidptr(watch_cb)

struct Context {
mut:
	cb_wrappers []&WatchCallBackWrap
	freed       bool
}

@[heap]
struct WatchCallBackWrap {
	callback ?FnWatchCallback
	path     string
mut:
	mutex     &sync.Mutex
	user_data voidptr
}

pub type WatchID = u32

fn init() {
	dbg(@MOD, @FN, '')
	ctx_oof := &Context{}

	// TODO Sorry - I have no other choice
	unsafe {
		x := &vmon.ctx
		*x = ctx_oof
	}
	C.dmon_init()

	C.atexit(done)
	// TODO for all os.signal(C.SIGXXX,done) ?
	//$if debug ? {
	os.signal_opt(.int, done_interrupt) or { return }
	//}
}

@[manualfree; unsafe]
fn done() {
	mut ctx_ptr := unsafe { vmon.ctx }
	if !isnil(ctx_ptr) && !ctx_ptr.freed {
		dbg(@MOD, @FN, '')
		dbg(@MOD, @FN, 'freeing resources')
		C.dmon_deinit()
		unsafe {
			for i := 0; i < ctx_ptr.cb_wrappers.len; i++ {
				free(ctx_ptr.cb_wrappers[i])
			}
		}
		ctx_ptr.cb_wrappers.clear()
		ctx_ptr.freed = true
		unsafe {
			free(ctx_ptr)
			ctx_ptr = nil
		}
	}
}

fn done_interrupt(_ os.Signal) {
	dbg(@MOD, @FN, '')
	unsafe {
		done()
	}
	exit(1)
}

@[manualfree]
fn c_watch_callback_wrap(watch_id c.WatchID, action Action, rootdir charptr, filepath charptr, oldfilepath charptr, user &WatchCallBackWrap) {
	d := user

	unsafe {
		fp := ''
		rp := ''
		ofp := ''
		if !isnil(filepath) {
			fp = filepath.vstring().clone() // tos_clone(byteptr(filepath))
		}
		if !isnil(rootdir) {
			rp = rootdir.vstring().clone() // tos_clone(byteptr(rootdir))
		}
		if !isnil(oldfilepath) {
			ofp = oldfilepath.vstring().clone() // tos_clone(byteptr(oldfilepath))
		}

		$if debug ? {
			watchid := watch_id.id
			vaction := action
			base_msg := 'filesystem event in "${rp}" id: ${watchid}  "${vaction}"'
			match int(action) {
				1 {
					dbg(@MOD, @FN, '${base_msg} "${fp}"')
				}
				2 {
					dbg(@MOD, @FN, '${base_msg} "${fp}"')
				}
				3 {
					dbg(@MOD, @FN, '${base_msg} "${fp}"')
				}
				4 {
					dbg(@MOD, @FN, '${base_msg} "${ofp}" to "${fp}"')
				}
				else {
					dbg(@MOD, @FN, '${base_msg} ouch "${ofp}" to "${fp}"')
				}
			}
			base_msg.free()
		}

		d.mutex.@lock()

		// lock d {
		// cb := d.callback
		if callback := d.callback {
			callback(watch_id.id, action, rp, fp, ofp, d.user_data)
		}
		// cb(watch_id.id, c_action_to_v(action), rp, fp, ofp, d.user_data)
		// cb(d.user_data)
		//}

		d.mutex.unlock()

		if !isnil(filepath) {
			fp.free()
		}
		if !isnil(rootdir) {
			rp.free()
		}
		if !isnil(oldfilepath) {
			ofp.free()
		}
	}
}

//          Watch for directories
//          You can watch multiple directories by calling this function multiple times
//              rootdir: root directory to monitor
//              watch_cb: callback function to receive events.
//                        NOTE that this function is called from another thread, so you should
//                        beware of data races in your application when accessing data within this
//                        callback
//              flags: watch flags, see dmon_watch_flags_t
//              user_data: user pointer that is passed to callback function
//          Returns the Id of the watched directory after successful call, or returns Id=0 if error

// watch watches `path` directory for changes and calls `watch_cb` when a file event occurs.
// Please note that watching occurs in another system thread
// so please guard your `user_data` accordingly.
pub fn watch(path string, watch_cb FnWatchCallback, flags u32, user_data voidptr) !WatchID {
	dbg(@MOD, @FN, 'watching "${path}"')

	if !os.is_dir(path) {
		return error(@MOD + '.' + @FN + ': "${path}" is not a valid directory')
	}

	watch_cb_wrap := &WatchCallBackWrap{
		path: path
		mutex: sync.new_mutex()
		user_data: user_data
		callback: watch_cb
	}

	mut ctx_ptr := unsafe { vmon.ctx }
	if !isnil(ctx_ptr) {
		ctx_ptr.cb_wrappers << watch_cb_wrap
	}

	wid := C.dmon_watch(path.str, c_watch_callback_wrap, flags, watch_cb_wrap).id

	if wid == 0 {
		return error(@MOD + '.' + @FN +
			': an error occurred while setting up watching for "${path}"')
	}
	return wid
}

pub fn unwatch(id WatchID) {
	dbg(@MOD, @FN, 'unwatching "${id}"') // Good for crash debugging
	mut ctx_ptr := unsafe { vmon.ctx }
	C.dmon_unwatch(c.WatchID{ id: u32(id) })
	if !isnil(ctx_ptr) {
		wid := int(id) - 1
		mut cbw := ctx_ptr.cb_wrappers[wid]
		dbg(@MOD, @FN, 'unwatching id ${id} ("${cbw.path}")')
		ctx_ptr.cb_wrappers.delete(wid)
		// Wear a life-belt
		cbw.mutex.@lock()
		cbw.user_data = unsafe { nil }
		cbw.mutex.unlock()
		unsafe {
			free(cbw.mutex)
		}
		unsafe {
			free(cbw)
		}
	}
}

// fn watch_cb(watch_id C.dmon_watch_id, action C.dmon_action, rootdir charptr, filepath charptr, oldfilepath charptr, user voidptr) { }
// voidptr(watch_cb)

@[if debug]
fn dbg(mod string, fnc string, msg string) {
	println(mod + '.' + fnc + if msg == '' { '' } else { ': ' + msg })
}
