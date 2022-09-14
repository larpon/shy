// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module shy

import shy.utils
import shy.ease

pub const infinite = -1

type AnimEventFn = fn (voidptr, AnimEvent)

pub enum AnimEvent {
	begin
	end
}

pub enum AnimLoop {
	once
	loop
	pingpong
}

[heap]
pub struct Anims {
	ShyStruct
mut:
	running bool
	paused  bool
	active  []&IAnimator
}

pub fn (mut a Anims) init() ! {}

pub fn (mut a Anims) shutdown() ! {
	for anim in a.active {
		unsafe {
			free(anim)
		}
	}
}

pub fn (a &Anims) update(dt f64) {
	if a.paused {
		return
	}
	for animator in a.active {
		if !animator.running {
			continue // TODO move to inactive queue?
		}
		if animator.paused {
			continue
		}
		animator.step(dt)
	}
}

pub fn (mut s Shy) new_animator<T>(config AnimatorConfig) &Animator<T> {
	s.vet_issue(.warn, .hot_code, '${@STRUCT}.${@FN}', 'memory fragmentation happens when allocating in hot code paths. It is, in general, better to pre-load data.')
	mut win := s.active_window()
	assert !isnil(win), 'Window is not alive'
	assert !isnil(win.anims), 'Window has not initialized animation support'
	mut anims := win.anims
	return anims.new_animator<T>(config)
}

pub fn (mut a Anims) new_animator<T>(config AnimatorConfig) &Animator<T> {
	mut animator := &Animator<T>{
		// TODO BUG ...config <- doesn't work
	}
	animator.running = config.running
	animator.paused = config.paused
	animator.ease = config.ease
	animator.loop = config.loop
	animator.loops = config.loops
	animator.duration = config.duration
	animator.user = config.user
	animator.on_event_fn = config.on_event_fn
	a.active << animator
	return animator
}

interface IAnimator {
	running bool
	paused bool
	run()
	step(f64)
}

[params]
pub struct AnimatorConfig {
pub mut:
	running     bool
	paused      bool
	ease        ease.Ease
	loop        AnimLoop
	loops       i64 // -1 = infinite, 0/1 = once, > 1 = X loops
	user        voidptr
	on_event_fn AnimEventFn
	duration    i64 = 1000
}

pub struct Animator<T> {
pub mut:
	running     bool
	paused      bool
	ease        ease.Ease
	loop        AnimLoop
	loops       i64 // -1 = infinite, 0/1 = once, > 1 = X loops
	user        voidptr
	on_event_fn AnimEventFn
	duration    i64 = 1000
mut:
	from       T
	to         T
	value      T
	prev_value T
	t          f64 // time, a value between 0 and 1
	elapsed    f64
}

pub fn (mut a Animator<T>) init(from T, to T, duration i64) {
	a.value = from
	a.from = from
	a.to = to
	a.duration = duration
}

pub fn (a &Animator<T>) restart() {
	unsafe {
		a.reset()
		a.run()
	}
}

pub fn (a &Animator<T>) run() {
	unsafe {
		a.running = true
	}
	a.fire_event_fn(.begin)
}

fn (a &Animator<T>) fire_event_fn(event AnimEvent) {
	if !isnil(a.on_event_fn) {
		a.on_event_fn(a.user, event)
	}
}

pub fn (a &Animator<T>) value() T {
	return a.value
}

pub fn (a &Animator<T>) t() f64 {
	return a.t
}

pub fn (mut a Animator<T>) reset() {
	a.running = false
	a.elapsed = 0
	a.value = a.from
	a.t = 0
	// a.pvalue = a.value
}

fn (mut a Animator<T>) ended() {
	a.fire_event_fn(.end)
	match a.loop {
		.once {
			a.reset()
		}
		.loop {
			if a.loops > 0 {
				a.loops--
				a.restart()
			} else if a.loops < 0 {
				a.restart()
			} else {
				a.reset()
			}
		}
		.pingpong {
			if a.loops > 0 {
				a.from, a.to = a.to, a.from
				a.loops--
				a.restart()
			} else if a.loops < 0 {
				a.from, a.to = a.to, a.from
				a.restart()
			} else {
				a.reset()
			}
		}
	}
}

fn (ima &Animator<T>) step(dt f64) {
	mut a := unsafe { ima } // TODO BUG workaround mutable generic interfaces
	a.elapsed += dt * 1000
	if a.elapsed >= a.duration {
		a.ended()
		return
	}
	t := a.elapsed / f64(a.duration)
	a.t = a.ease.ease(t)
	// a.t = ease.parametric(a.t)
	// a.t = ease.in_curve(a.t)
	// a.t = ease.out_curve(a.t)
	a.value = utils.remap(a.t, 0, 1.0, a.from, a.to)
	a.prev_value = a.value
}
