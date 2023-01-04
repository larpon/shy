// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module lib

type TimerEventFn = fn (TimerEvent)

type TimerFn = fn ()

pub enum TimerEvent {
	begin
	end
}

pub enum TimerLoop {
	once
	loop
}

[heap]
pub struct Timers {
	ShyStruct
mut:
	// running bool
	paused bool
	active []&Timer = []&Timer{cap: 1000} // Should match prealloc
	pool   []&Timer = []&Timer{cap: 1000} // Should match prealloc
}

pub fn (mut t Timers) init() ! {
	// t.shy.assert_api_init() // TODO fix for multi-window
	// TODO make configurable
	prealloc := 1000
	unsafe { t.active.flags.set(.noslices | .noshrink) }
	unsafe { t.pool.flags.set(.noslices | .noshrink) }
	// unsafe { t.f64_pool.flags.set(.noslices | .noshrink) }
	for i := 0; i < prealloc; i++ {
		t.pool << t.p_new_timer()
		// t.f64_pool << t.p_new_timer<f64>()
	}
}

pub fn (t &Timers) has_work() bool {
	// t.running &&
	return !t.paused && t.active.len > 0
}

[manualfree]
pub fn (mut t Timers) shutdown() ! {
	t.shy.assert_api_shutdown()
	for timer in t.active {
		unsafe {
			free(timer)
		}
	}
	for timer in t.pool {
		unsafe {
			free(timer)
		}
	}
}

pub fn (mut t Timers) update(dt f64) {
	if t.paused {
		return
	}
	for i := 0; i < t.active.len; i++ {
		mut timer := t.active[i]
		// timer.touch()
		if timer.paused {
			continue
		}
		if !timer.running {
			// TODO see if this is all worth it
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
// NOTE the timer system is not accurate.
pub fn (mut s Shy) once(callback TimerFn, delay u64) {
	s.vet_issue(.warn, .hot_code, '${@STRUCT}.${@FN}', 'Starting a timer in the frame call (usually called 60 times per second) is usually a bad idea')

	s.new_timer(
		duration: delay
		callback: callback
	).run()
}

// once executes `callback` `loops` times, when `delay` milliseconds has passed.
// NOTE the timer system is not accurate.
pub fn (mut s Shy) every(callback TimerFn, delay u64, loops i64) {
	s.vet_issue(.warn, .hot_code, '${@STRUCT}.${@FN}', 'Starting a timer in the frame call (usually called 60 times per second) is usually a bad idea')

	s.new_timer(
		loop: .loop
		loops: loops
		duration: delay
		callback: callback
	).run()
}

fn (mut t Timers) p_new_timer(config TimerConfig) &Timer {
	t.shy.vet_issue(.warn, .hot_code, '${@STRUCT}.${@FN}', 'memory fragmentation happens when allocating in hot code paths. It is, in general, better to pre-load data.')
	mut timer := &Timer{
		shy: t.shy
	}
	timer.config_update(config)
	return timer
}

pub fn (mut t Timers) new_timer(config TimerConfig) &Timer {
	mut timer := &Timer(0) // unsafe { nil }
	if t.pool.len > 0 {
		timer = t.pool.pop()
		timer.config_update(config)
	} else {
		timer = t.p_new_timer(config)
	}
	t.active << timer
	return timer
}

[params]
pub struct TimerConfig {
pub mut:
	running     bool = true
	paused      bool
	loop        TimerLoop
	loops       i64 // -1 = infinite, 0/1 = once, > 1 = X loops
	on_event_fn TimerEventFn
	callback    TimerFn
	duration    u64 = 1000
}

[noinit]
pub struct Timer {
	ShyStruct
pub mut:
	running     bool
	paused      bool
	loop        TimerLoop
	loops       i64 // shy.infinite = infinite, 0/1 = once, > 1 = X loops
	on_event_fn TimerEventFn
	callback    TimerFn
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
	if !isnil(t.on_event_fn) {
		t.on_event_fn(event)
	}
	if event == .end {
		t.callback()
	}
}

pub fn (mut t Timer) reset() {
	t.running = false
	t.elapsed = 0
}

fn (mut t Timer) ended() {
	t.fire_event_fn(.end)
	match t.loop {
		.once {
			t.reset()
		}
		.loop {
			if t.loops > 0 {
				t.loops--
				t.restart()
			} else if t.loops == infinite {
				t.restart()
			} else {
				t.reset()
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
