// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module lib

import shy.analyse

pub const preallocate_timers = int($d('shy:timers:prealloc', 10))

type TimerEventFn = fn (TimerEvent)

pub type TimerFn = fn (&Timer)

pub enum TimerEvent {
	begin
	end
}

pub enum TimerLoop {
	once
	loop
}

@[heap]
pub struct Timers {
	ShyStruct
mut:
	ids u32
	// running bool
	paused bool
	active []&Timer = []&Timer{cap: preallocate_timers} // Should match prealloc
	pool   []&Timer = []&Timer{cap: preallocate_timers} // Should match prealloc
}

pub fn (mut t Timers) init() ! {
	// t.shy.assert_api_init() // TODO: fix for multi-window
	prealloc := preallocate_timers
	unsafe { t.active.flags.set(.noslices | .noshrink) }
	unsafe { t.pool.flags.set(.noslices | .noshrink) }
	// unsafe { t.f64_pool.flags.set(.noslices | .noshrink) }
	for i := 0; i < prealloc; i++ {
		t.pool << t.p_new_timer()
		analyse.count('${@MOD}.${@STRUCT}.preallocate', 1)
		// t.f64_pool << t.p_new_timer<f64>()
	}
}

pub fn (mut t Timers) reset() ! {
	for i := 0; i < t.active.len; i++ {
		mut timer := t.active[i]
		timer.restart()
	}
}

pub fn (t &Timers) active() bool {
	// t.running &&
	return !t.paused && t.active.len > 0
}

@[manualfree]
pub fn (mut t Timers) shutdown() ! {
	t.shy.assert_api_shutdown()
	for timer in t.active {
		unsafe {
			shy_free(timer)
		}
	}
	for timer in t.pool {
		unsafe {
			shy_free(timer)
		}
	}
}

pub fn (mut t Timers) update(dt f64) {
	if t.paused {
		return
	}
	analyse.max('${@MOD}.${@STRUCT}.max_in_use', t.active.len)
	for i := 0; i < t.active.len; i++ {
		mut timer := t.active[i]
		// timer.touch()
		if timer.paused {
			continue
		}
		if !timer.running {
			// TODO: see if this is all worth it
			t.pool << timer
			t.active.delete(i)
			continue
		}
		timer.step(dt)
	}
}

pub fn (mut s Shy) new_timer(config TimerConfig) &Timer {
	mut win := s.active_window()
	assert !isnil(win), 'Window is not alive'
	assert !isnil(win.timers), 'Window has not initialized timer support'
	mut timers := win.timers
	return timers.new_timer(config)
}

// once executes `callback` when `delay` milliseconds has passed.
// NOTE: the timer system is not accurate.
pub fn (mut s Shy) once(callback TimerFn, delay u64) {
	s.vet_issue(.warn, .hot_code, '${@STRUCT}.${@FN}', 'Starting a timer in the frame call (usually called 60 times per second) is usually a bad idea')
	analyse.count('${@MOD}.${@STRUCT}.${@FN}', 1)

	s.new_timer(
		duration: delay
		callback: callback
	).run()
}

// once executes `callback` `loops` times, when `delay` milliseconds has passed.
// NOTE: the timer system depends on the refresh rate, so it is not accurate.
pub fn (mut s Shy) every(callback TimerFn, delay u64, loops i64) {
	s.vet_issue(.warn, .hot_code, '${@STRUCT}.${@FN}', 'Starting a timer in the frame call (usually called 60 times per second) is usually a bad idea')
	analyse.count('${@MOD}.${@STRUCT}.${@FN}', 1)

	s.new_timer(
		loop:     .loop
		loops:    loops
		duration: delay
		callback: callback
	).run()
}

fn (mut t Timers) p_new_timer(config TimerConfig) &Timer {
	t.shy.vet_issue(.warn, .hot_code, '${@STRUCT}.${@FN}', 'memory fragmentation happens when allocating in hot code paths. It is, in general, better to pre-load data.')
	analyse.count('${@MOD}.${@STRUCT}.${@FN}', 1)
	t.ids++
	mut timer := &Timer{
		shy: t.shy
		id:  t.ids
	}
	timer.reset()
	timer.config_update(config)
	return timer
}

pub fn (mut t Timers) new_timer(config TimerConfig) &Timer {
	mut timer := &Timer(unsafe { nil }) // unsafe { nil }
	if t.pool.len > 0 {
		timer = t.pool.pop()
		timer.reset()
		timer.config_update(config)
		t.ids++
		timer.id = t.ids
	} else {
		timer = t.p_new_timer(config)
	}
	t.active << timer
	return timer
}

@[params]
pub struct TimerConfig {
pub mut:
	running     bool = true
	paused      bool
	loop        TimerLoop
	loops       i64 // -1 = infinite, 0/1 = once, > 1 = X loops
	on_event_fn ?TimerEventFn
	callback    ?TimerFn
	duration    u64 = 1000
}

@[noinit]
pub struct Timer {
	ShyStruct
pub mut:
	id u32 // TODO: should be module mut but public read-only
	//
	running     bool
	paused      bool
	loop        TimerLoop
	loops       i64 // shy.infinite = infinite, 0/1 = once, > 1 = X loops
	on_event_fn ?TimerEventFn
	callback    ?TimerFn
	duration    u64 = 1000
mut:
	elapsed f64
}

fn (mut t Timer) config_update(config TimerConfig) {
	t.running = config.running
	t.paused = config.paused
	t.loop = config.loop
	t.loops = config.loops
	t.duration = config.duration
	t.on_event_fn = config.on_event_fn
	t.callback = config.callback
}

pub fn (t &Timer) restart() {
	unsafe {
		t.reset()
		t.run()
	}
}

pub fn (t &Timer) run() {
	unsafe {
		t.running = true
	}
	t.fire_event_fn(.begin)
}

fn (t &Timer) fire_event_fn(event TimerEvent) {
	if on_event_fn := t.on_event_fn {
		on_event_fn(event)
	}
	if event == .end {
		if callback := t.callback {
			callback(t)
		}
	}
}

pub fn (t &Timer) reset() {
	unsafe {
		t.running = false
		t.elapsed = 0
	}
}

fn (mut t Timer) ended() {
	t.fire_event_fn(.end)
	match t.loop {
		.once {
			// t.reset()
			t.running = false
		}
		.loop {
			if t.loops > 0 {
				t.loops--
				t.restart()
				// vfmt off
			} else if t.loops == lib.infinite {
				// vfmt on
				t.restart()
			} else {
				// t.reset()
				t.running = false
			}
		}
	}
}

fn (mut t Timer) step(dt f64) {
	t.elapsed += dt * 1000
	if t.elapsed >= t.duration {
		t.ended()
		return
	}
}
