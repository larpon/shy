// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module lib

import time
import shy.log { Log }

pub const null = unsafe { nil }

pub const (
	half           = f32(0.5)
	quarter        = f32(0.25)
	three_quarters = f32(0.75)
	one            = f32(1.0)
)

const vet_tag = 'VET'

struct State {
mut:
	in_hot_code bool
	rendering   bool
}

// ShyStruct is meant to be used as an embed for all types that need to have access to
// all sub-systems of the Shy struct.
struct ShyStruct {
pub mut: // TODO error: field `App.shy` is not public - make this just "pub" to callers - and mut to internal system
	shy &Shy = lib.null
}

fn (s ShyStruct) init() ! {
	assert !isnil(s.shy), '${@STRUCT}.${@FN}' + 'shy is null'
}

fn (s ShyStruct) shutdown() ! {
	assert !isnil(s.shy), '${@STRUCT}.${@FN}' + 'shy is null'
}

struct ShyFrame {
	ShyStruct
}

[if !prod]
fn (mut sf ShyFrame) begin() {
	assert !isnil(sf.shy), '${@STRUCT}.${@FN}' + 'shy is null'
	assert sf.shy.state.rendering, '${@STRUCT}.${@FN}' +
		' can only be called inside a .frame() call'
}

[if !prod]
fn (mut sf ShyFrame) end() {
	assert !isnil(sf.shy), '${@STRUCT}.${@FN}' + 'shy is null'
	assert sf.shy.state.rendering, '${@STRUCT}.${@FN}' +
		' can only be called inside a .frame() call'
}

// Shy carries all of shy's internal state.
[heap]
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
	state State
	timer time.StopWatch = time.new_stopwatch()
	//
	app voidptr = unsafe { nil }
	// user_data voidptr = unsafe { nil }
	// The "blackbox" api implementation specific struct
	// Can only be accessed via the unsafe api() function *outside* the module
	api API
}

[inline; unsafe]
pub fn (s Shy) api() API {
	return s.api
}

[inline]
pub fn (mut s Shy) init() ! {
	$if debug ? {
		s.log.set(.debug)
	}
	s.log.gdebug('${@STRUCT}.${@FN}', '')
	s.api.init(s)!
	s.health()!
	s.ready = true
	s.timer.start()
}

[inline]
pub fn (mut s Shy) shutdown() ! {
	s.ready = false
	s.api.shutdown()!
	s.log.shutdown()!
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
[manualfree]
pub fn run<T>(mut ctx T, config Config) ! {
	mut shy_instance := new(config)!
	shy_instance.app = voidptr(ctx)
	// shy_instance.user_data = voidptr(ctx)
	ctx.shy = shy_instance
	ctx.init()!

	shy_instance.api.main<T>(mut ctx, mut shy_instance)!

	ctx.shutdown()!
	shy_instance.shutdown()!
	unsafe { free(shy_instance) }
}

fn (s Shy) health() ! {
	s.api.health()!
}

[if !prod]
pub fn (s Shy) assert_api_init() {
	assert !s.running, 'Shy.running is true'
	assert !s.state.in_hot_code, 'Shy is in a hot code path'
	assert !s.shutdown, 'Shy is shutting down'
}

[if !prod]
pub fn (s Shy) assert_api_shutdown() {
	assert !s.running, 'Shy.running is true'
	assert !s.state.in_hot_code, 'Shy is in a hot code path'
	assert s.shutdown, 'Shy is not set to shut down'
}

pub enum VetCategory {
	warn
}

pub enum VetArea {
	misc
	hot_code
}

[if shy_vet ?]
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
						s.log.gwarn('${lib.vet_tag} ' + prefix, msg)
					}
				}
				else {
					s.log.gwarn('${lib.vet_tag} ' + prefix, msg)
				}
			}
		}
	}
}
