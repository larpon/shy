// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module shy

import time
import shy.log { Log }

pub const null = unsafe { nil }

const vet_tag = 'VET'

//
pub enum ButtonState {
	up
	down
}

struct State {
mut:
	in_hot_code   bool
	in_frame_call bool
}

struct ShyStruct {
pub mut: // TODO error: field `App.shy` is not public - make this just "pub" to callers - and mut to internal system
	shy &Shy // = shy.null
}

fn (sb ShyStruct) init() ! {}

fn (sb ShyStruct) shutdown() ! {}

struct ShyFrame {
	ShyStruct
}

[if !prod]
fn (mut sf ShyFrame) begin() {
	assert sf.shy.state.in_frame_call, '${@STRUCT}.${@FN}' +
		' can only be called inside a .frame() call'
}

[if !prod]
fn (mut sf ShyFrame) end() {
	assert sf.shy.state.in_frame_call, '${@STRUCT}.${@FN}' +
		' can only be called inside a .frame() call'
}

// Shy carries all of shy's internal state.
[heap]
pub struct Shy {
	config Config
	timer  time.StopWatch = time.new_stopwatch(auto_start: true)
pub mut:
	paused   bool
	shutdown bool
mut:
	log     log.Log
	ready   bool
	running bool
	//
	state State
	// The "blackbox" api implementation specific struct
	api API
}

[inline]
pub fn (mut s Shy) init() ! {
	$if debug ? {
		s.log.set(.debug)
	}
	s.log.gdebug('${@STRUCT}.${@FN}', 'hi')
	s.api.init(s)!
	s.check_api()!
	s.ready = true
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
pub fn run<T>(mut ctx T, config Config) ! {
	mut shy_instance := new(config)!
	ctx.shy = shy_instance
	ctx.init()!

	main_loop<T>(mut ctx, mut shy_instance)!

	ctx.quit()
	shy_instance.shutdown()!
	unsafe { free(shy_instance) }
}

fn main_loop<T>(mut ctx T, mut s Shy) ! {
	s.log.gdebug(@MOD + '.' + @FN, 'entering main loop.\nConfig:\n$s.config')

	mut root := s.api.wm.root

	s.running = true
	s.state.in_hot_code = true
	for s.running {
		if !s.ready {
			s.log.gwarn('${@MOD}.${@FN}', 'not ready. Waiting 1 second...')
			time.sleep(1 * time.second)
			continue
		}

		// TODO re-write event processing for each window...
		// Process system events
		s.process_events<T>(mut ctx)

		s.state.in_frame_call = true
		root.render<T>(mut ctx)
		s.state.in_frame_call = false

		if s.shutdown {
			s.log.gdebug(@MOD + '.' + @FN, 'shutdown is $s.shutdown, leaving main loop...')
			break
		}
	}
	s.state.in_hot_code = false
}

// process_events processes all events and delegate them to T
fn (mut s Shy) process_events<T>(mut ctx T) {
	for {
		event := s.poll_event() or { break }
		ctx.event(event)
	}
}

fn (s Shy) check_api() ! {
	if isnil(s.api.wm) || isnil(s.api.gfx) || isnil(s.api.input) {
		return error('not all essential api systems where set')
	}
	if isnil(s.api.audio) {
		return error('not all audio api systems where set')
	}
	if isnil(s.api.gfx.draw) {
		return error('not all graphics api systems where set')
	}
	if isnil(s.api.input.mouse) || isnil(s.api.input.keyboard) {
		return error('not all input api systems where set')
	}
}

enum VetCategory {
	warn
}

enum VetArea {
	misc
	hot_code
}

[if shy_vet ?]
fn (s &Shy) vet_issue(c VetCategory, area VetArea, caller string, msg string) {
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
						s.log.gwarn('$shy.vet_tag ' + prefix, msg)
					}
				}
				else {
					s.log.gwarn('$shy.vet_tag ' + prefix, msg)
				}
			}
		}
	}
}
