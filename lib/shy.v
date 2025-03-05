// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module lib

import time
import rand
import shy.log { Log }
import shy.analyse

pub const null = unsafe { nil }

pub const half = f32(0.5)
pub const quarter = f32(0.25)
pub const three_quarters = f32(0.75)
pub const one = f32(1.0)

const vet_tag = 'VET'

struct State {
mut:
	in_hot_code bool
	rendering   bool
}

// ShyStruct is meant to be used as an embed for all types that need to have access to
// all sub-systems of the Shy struct.
struct ShyStruct {
pub mut:
	// TODO: error: field `App.shy` is not public - make this just "pub" to callers - and mut to internal system
	shy &Shy = null
}

pub fn (s ShyStruct) str() string {
	return 'ShyStruct {
	shy: ${ptr_str(s.shy)}
}'
}

fn (s ShyStruct) init() ! {
	assert !isnil(s.shy), '${@STRUCT}.${@FN}' + 'shy is null'
}

fn (mut s ShyStruct) shutdown() ! {
	assert !isnil(s.shy), '${@STRUCT}.${@FN}' + 'shy is null'
	s.shy = null
}

struct ShyFrame {
	ShyStruct
}

@[if !prod; inline]
fn (mut sf ShyFrame) begin() {
	assert !isnil(sf.shy), '${@STRUCT}.${@FN}' + 'shy is null'
	assert sf.shy.state.rendering, '${@STRUCT}.${@FN}' +
		' can only be called inside a .frame() call'
}

@[if !prod; inline]
fn (mut sf ShyFrame) end() {
	assert !isnil(sf.shy), '${@STRUCT}.${@FN}' + 'shy is null'
	assert sf.shy.state.rendering, '${@STRUCT}.${@FN}' +
		' can only be called inside a .frame() call'
}

// Shy carries all of shy's internal state.
@[heap]
pub struct Shy {
pub:
	log    Log
	config Config
pub mut:
	paused   bool
	shutdown bool
mut:
	ready   bool
	running bool
	//
	state  State
	timer  time.StopWatch = time.new_stopwatch()
	alarms &Alarms        = unsafe { nil }
	//
	custom_data voidptr = unsafe { nil } // Expose a way for users to get and set custom data
	app         voidptr = unsafe { nil } // This is reserved for `shy.run[X](...)` to put the user "App" struct
	//
	// The "blackbox" api implementation specific struct
	// Can only be accessed via the unsafe api() function *outside* the module
	api API
}

@[inline; unsafe]
pub fn (s Shy) api() API {
	return s.api
}

@[inline]
pub fn (mut s Shy) init() ! {
	$if debug ? {
		s.log.set(.debug)
	}
	s.log.gdebug('${@STRUCT}.${@FN}', '')
	$if wasm32_emscripten {
		emscripten_init()!
	}
	$if !shy_no_determinism ? {
		s.log.gdebug('${@STRUCT}.${@FN}', 'enable determinism')
		rand.seed([u32(0x4b1d), 0xbaadf00d])
	}
	s.alarms = &Alarms{
		shy: s
	}
	s.alarms.init()!
	s.api.init(s)!
	s.health()!
	s.ready = true
	s.timer.start()
}

@[inline]
pub fn (mut s Shy) reset() ! {
	s.alarms.reset()!
	s.api.reset()!
	s.timer.restart()
}

@[inline]
pub fn (mut s Shy) shutdown() ! {
	s.ready = false
	s.alarms.paused = true // Pause so no alarms will fire during shutdown
	s.api.shutdown()!
	s.alarms.shutdown()!
	s.log.shutdown()!
	analyse.eprintln_report() // $if shy_analyse ?
}

// new returns a new, initialized, `Shy` struct allocated in heap memory.
pub fn new(config Config) !&Shy {
	mut s := &Shy{
		config: config
	}
	s.init()!
	return s
}

// run runs the application instance `T`.
@[manualfree]
pub fn run[T](mut ctx T, config Config) ! {
	mut shy_instance := new(config)!
	shy_instance.app = voidptr(ctx)
	ctx.shy = shy_instance

	shy_instance.log.gdebug('${@MOD}.${@FN}', 'calling `init/0` on user struct T')
	ctx.init()!

	shy_instance.api.main[T](mut ctx, mut shy_instance)!

	ctx.shutdown()!
	shy_instance.shutdown()!
	unsafe { shy_free(shy_instance) }
}

fn (s Shy) health() ! {
	s.api.health()!
}

// quit_request sends a request to quit and end execution.
// quit requests can be cancelled in some cases.
@[inline]
pub fn (mut s Shy) quit_request() {
	s.api.events.send_quit_event(false)
}

// quit sends out a quit event, ensuring all of `Shy`
// shutsdown cleanly
@[inline]
pub fn (mut s Shy) quit() {
	s.api.events.send_quit_event(true)
}

// window returns the `Window` instance with `id == window_id`
@[inline]
pub fn (s Shy) window(window_id u32) ?&Window {
	assert !isnil(s.api.wm), '${@STRUCT}.${@FN}: ${@STRUCT}.api.wm is null'
	return s.api.wm.find_window(window_id)
}

@[inline]
pub fn (s Shy) user_data() ?voidptr {
	if !isnil(s.custom_data) {
		return s.custom_data
	}
	return none
}

@[inline]
pub fn (mut s Shy) set_user_data(ptr voidptr) {
	s.custom_data = ptr
}

@[if !prod]
pub fn (s Shy) assert_api_init() {
	$if test {
		return
	}
	assert !s.running, '${@STRUCT}.running is true'
	assert !s.state.in_hot_code, '${@STRUCT} is in a hot code path'
	assert !s.shutdown, '${@STRUCT} is shutting down'
}

@[if !prod]
pub fn (s Shy) assert_api_shutdown() {
	$if test {
		return
	}
	assert !s.running, 'Shy.running is true'
	assert !s.state.in_hot_code, 'Shy is in a hot code path'
	assert s.shutdown, 'Shy is not set to shut down'
}

pub enum VetCategory {
	warn
	notice
}

pub enum VetArea {
	misc
	hot_code
}

fn version() string {
	mut v := '0.0.0'
	vmod_file := @VMOD_FILE
	if vmod_file.len > 0 {
		if vmod_file.contains('version:') {
			v = vmod_file.all_after('version:').all_before('\n').replace("'", '').replace('"',
				'').trim_space()
		}
	}
	return v
}

@[if shy_vet ?]
pub fn (s &Shy) vet_issue(c VetCategory, area VetArea, caller string, msg string) {
	mut prefix := caller + ' '
	prefix += match area {
		.misc { 'misc' }
		.hot_code { 'hot_code' }
	}
	match c {
		.warn {
			match area {
				.hot_code {
					if s.state.in_hot_code {
						s.log.gwarn('${vet_tag} ${prefix}', msg)
					}
				}
				else {
					s.log.gwarn('${vet_tag} ${prefix}', msg)
				}
			}
		}
		.notice {
			match area {
				.hot_code {
					if s.state.in_hot_code {
						s.log.gnotice('${vet_tag} ${prefix}', msg)
					}
				}
				else {
					s.log.gnotice('${vet_tag} ${prefix}', msg)
				}
			}
		}
	}
}
