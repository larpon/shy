// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module lib

import shy.utils
import shy.ease
import shy.analyse
import mth

pub const infinite = -1

pub enum AnimatorKind {
	animator
	follow
}

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

@[heap]
pub struct Anims {
	ShyStruct
mut:
	// running bool
	paused  bool
	active  []&IAnimator     = []&IAnimator{cap: 1000} // Should match prealloc
	f32pool []&Animator[f32] = []&Animator[f32]{cap: 1000} // Should match prealloc
	// f64_pool    []&Animator<f64>
}

pub fn (mut a Anims) init() ! {
	// a.shy.assert_api_init() // TODO fix for multi-window
	// TODO make configurable
	prealloc := 1000
	unsafe { a.active.flags.set(.noslices | .noshrink) }
	// unsafe { a.bin.flags.set(.noslices | .noshrink) }
	unsafe { a.f32pool.flags.set(.noslices | .noshrink) }
	// unsafe { a.f64_pool.flags.set(.noslices | .noshrink) }
	for i := 0; i < prealloc; i++ {
		a.f32pool << a.p_new_animator[f32]()
		// a.f64_pool << a.p_new_animator<f64>()
	}
}

pub fn (mut a Anims) reset() ! {
	for i := 0; i < a.active.len; i++ {
		animator := a.active[i]
		animator.restart()
	}
}

pub fn (a &Anims) active() bool {
	// a.running &&
	return !a.paused && a.active.len > 0
}

@[manualfree]
pub fn (mut a Anims) shutdown() ! {
	a.shy.assert_api_shutdown()
	for anim in a.active {
		unsafe {
			if isnil(anim) {
				a.shy.log.gerror('${@MOD}.${@STRUCT}', 'TODO V memory bug ${a.active.len}')
				return
			}
			shy_free(anim)
		}
	}
	for anim in a.f32pool {
		unsafe {
			if isnil(anim) {
				a.shy.log.gerror('${@MOD}.${@STRUCT}', 'TODO V memory bug ${a.f32pool.len}')
				return
			}
			shy_free(anim)
		}
	}
}

pub fn (mut a Anims) update(dt f64) {
	if a.paused {
		return
	}
	analyse.max('${@MOD}.${@STRUCT}.max_in_use', a.active.len)
	for i := 0; i < a.active.len; i++ {
		animator := a.active[i]
		// NOTE(lmp) workaround weird crash/behavior with `-d shy_analyse` here?!?
		// Turns out the culprit was actually the garbage collector and SDL2, leave check for now
		if isnil(animator) {
			a.shy.log.gerror('${@MOD}.${@STRUCT}', 'TODO V memory bug ${a.active.len}')
			return
		}

		if animator.kind == .follow {
			animator.touch()
		}
		// for animator in a.active {
		if !animator.running && !animator.recycle {
			// TODO move to inactive pool - measure if this is even all worth it.
			// Doing this has some implications when the anim is restarted:
			// we need (maybe expensive?) logic to detect and transfer the animator back into
			// the active pool - maybe it's just more "efficient" to simply let the
			// animation live in the active pool. Hmm...
			// Let's try with a recycle flag:
			if animator is Animator[f32] {
				a.f32pool << animator
				a.active.delete(i)
			}
			continue
		}
		if animator.paused {
			continue
		}
		animator.step(dt)
	}
}

pub fn (mut s Shy) new_animator[T](config AnimatorConfig) &Animator[T] {
	mut win := s.active_window()
	assert !isnil(win), 'Window is not alive'
	assert !isnil(win.anims), 'Window has not initialized animation support'
	mut anims := win.anims
	return anims.new_animator[T](config)
}

pub fn (mut s Shy) new_follow_animator[T](config FollowAnimatorConfig) &FollowAnimator[T] {
	mut win := s.active_window()
	assert !isnil(win), 'Window is not alive'
	assert !isnil(win.anims), 'Window has not initialized animation support'
	mut anims := win.anims
	return anims.new_follow_animator[T](config)
}

fn (mut a Anims) p_new_animator[T](config AnimatorConfig) &Animator[T] {
	a.shy.vet_issue(.warn, .hot_code, '${@STRUCT}.${@FN}', 'memory fragmentation happens when allocating in hot code paths. It is, in general, better to pre-load data.')
	$if shy_analyse ? {
		t := T{}
		analyse.count('${@MOD}.${@STRUCT}.${@FN}[${typeof(t).name}]', 1)
	}
	mut animator := &Animator[T]{
		shy: a.shy
		// BUG: ...config <- doesn't work for generics
	}
	animator.config_update(config)
	return animator
}

fn (mut a Anims) p_new_follow_animator[T](config FollowAnimatorConfig) &FollowAnimator[T] {
	a.shy.vet_issue(.warn, .hot_code, '${@STRUCT}.${@FN}', 'memory fragmentation happens when allocating in hot code paths. It is, in general, better to pre-load data.')
	$if shy_analyse ? {
		t := T{}
		analyse.count('${@MOD}.${@STRUCT}.${@FN}[${typeof(t).name}]', 1)
	}
	mut animator := &FollowAnimator[T]{
		shy: a.shy
		// BUG: ...config <- doesn't work for generics
	}
	// animator.reset()
	animator.config_update(config)
	return animator
}

pub fn (mut a Anims) new_animator[T](config AnimatorConfig) &Animator[T] {
	mut animator := &Animator[T](unsafe { nil }) // unsafe { nil }
	$if T.typ is f32 {
		if a.f32pool.len > 0 {
			animator = a.f32pool.pop()
			animator.reset()
			animator.config_update(config)
		} else {
			animator = a.p_new_animator[T](config)
		}
	} $else {
		animator = a.p_new_animator[T](config)
	}
	// animator = a.p_new_animator<T>(config)
	a.active << animator
	return animator
}

pub fn (mut a Anims) new_follow_animator[T](config FollowAnimatorConfig) &FollowAnimator[T] {
	mut animator := &FollowAnimator[T](unsafe { nil }) // unsafe { nil }
	/*
	$if T.typ is f32 {
		if a.f32pool.len > 0 {
			animator = a.f32pool.pop()
			animator.config_update(config)
		} else {
			animator = a.p_new_animator<T>(config)
		}
	} $else {
		animator = a.p_new_animator<T>(config)
	}*/
	animator = a.p_new_follow_animator[T](config)
	a.active << animator
	return animator
}

// IAnimator is what the Anims system can control
interface IAnimator {
	kind    AnimatorKind
	running bool
	paused  bool // run()
	recycle bool
	step(f64)
	touch()
	restart()
	reset()
}

@[params]
pub struct AnimatorConfig {
pub mut:
	running     bool
	paused      bool
	recycle     bool
	ease        ease.Ease
	loop        AnimLoop
	loops       i64 // -1 = infinite, 0/1 = once, > 1 = X loops
	user        voidptr
	on_event_fn ?AnimEventFn
	duration    i64 = 1000
}

@[noinit]
pub struct Animator[T] {
	ShyStruct
	kind AnimatorKind = .animator
pub mut:
	running     bool
	paused      bool
	recycle     bool
	ease        ease.Ease
	loop        AnimLoop
	loops       i64 // shy.infinite = infinite, 0/1 = once, > 1 = X loops
	user        voidptr
	on_event_fn ?AnimEventFn
	duration    i64 = 1000
	prev_value  T
mut:
	from    T
	to      T
	value   T
	t       f64 // time, a value between 0 and 1
	elapsed f64
}

fn (mut a Animator[T]) config_update(config AnimatorConfig) {
	a.running = config.running
	a.paused = config.paused
	a.recycle = config.recycle
	a.ease = config.ease
	a.loop = config.loop
	a.loops = config.loops
	a.duration = config.duration
	a.user = config.user
	a.on_event_fn = config.on_event_fn
}

pub fn (mut a Animator[T]) init(from T, to T, duration_ms i64) {
	a.value = from
	a.from = from
	a.to = to
	a.duration = duration_ms
	a.prev_value = from
}

pub fn (a &Animator[T]) restart() {
	unsafe {
		a.reset()
		a.run()
	}
}

pub fn (a &Animator[T]) run() {
	unsafe {
		a.running = true
	}
	a.fire_event_fn(.begin)
}

fn (a &Animator[T]) fire_event_fn(event AnimEvent) {
	if on_event_fn := a.on_event_fn {
		on_event_fn(a.user, event)
	}
}

pub fn (a &Animator[T]) value() T {
	return a.value
}

pub fn (a &Animator[T]) t() f64 {
	return a.t
}

pub fn (ima Animator[T]) reset() {
	mut a := unsafe { ima } // BUG: workaround mutable generic interfaces
	a.running = false
	a.elapsed = 0
	a.value = a.from
	a.t = 0
	a.prev_value = a.value
}

fn (mut a Animator[T]) ended() {
	a.fire_event_fn(.end)
	match a.loop {
		.once {
			a.running = false
			a.value = a.to
			// a.reset()
		}
		.loop {
			if a.loops > 0 {
				a.loops--
				a.restart()
			} else if a.loops == lib.infinite {
				a.restart()
			} else {
				a.running = false
				a.value = a.to
				// a.reset()
			}
		}
		.pingpong {
			if a.loops > 0 {
				a.from, a.to = a.to, a.from
				a.loops--
				a.restart()
			} else if a.loops == lib.infinite {
				a.from, a.to = a.to, a.from
				a.restart()
			} else {
				a.running = false
				a.value = a.to
				// a.reset()
			}
		}
	}
}

fn (a &Animator[T]) touch() {}

fn (ima &Animator[T]) step(dt f64) {
	mut a := unsafe { ima } // BUG: workaround mutable generic interfaces
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
	value := utils.remap(a.t, 0, 1.0, a.from, a.to)
	lerp_value := utils.lerp(value, a.prev_value, dt)
	// println('v: $value pv: $a.prev_value lv: $lerp_value')
	a.value = T(lerp_value)
	a.prev_value = a.value
}

@[params]
pub struct FollowAnimatorConfig {
pub mut:
	running bool
	paused  bool
	recycle bool
	// ease        ease.Ease
	multiply    f32 = 1.0
	user        voidptr
	on_event_fn ?AnimEventFn
}

pub struct FollowAnimator[T] {
	ShyStruct
	kind AnimatorKind = .follow
pub mut:
	running bool
	paused  bool
	recycle bool
	// ease        ease.Ease
	multiply    f32 = 1.0
	user        voidptr
	on_event_fn ?AnimEventFn
	prev_value  T
mut:
	target T
	value  T
}

fn (fa FollowAnimator[T]) touch() {
	mut a := unsafe { fa } // BUG: workaround mutable generic interfaces
	should_run := mth.round_to_even(utils.manhattan_distance(a.value, 0, a.target, 0)) != 0
	if should_run {
		a.running = should_run
		if a.running {
			a.fire_event_fn(.begin)
		}
	}
}

fn (fa FollowAnimator[T]) restart() {
	fa.reset()
}

fn (fa FollowAnimator[T]) reset() {
	mut a := unsafe { fa } // BUG: workaround mutable generic interfaces
	a.value = a.target
}

fn (mut a FollowAnimator[T]) config_update(config FollowAnimatorConfig) {
	a.running = config.running
	a.paused = config.paused
	a.recycle = config.recycle
	a.multiply = config.multiply

	// a.ease = config.ease
	// a.loop = config.loop
	// a.loops = config.loops
	// a.duration = config.duration
	a.user = config.user
	a.on_event_fn = config.on_event_fn
}

fn (a &FollowAnimator[T]) fire_event_fn(event AnimEvent) {
	if on_event_fn := a.on_event_fn {
		on_event_fn(a.user, event)
	}
}

pub fn (a &FollowAnimator[T]) value() T {
	return a.value
}

fn (fa &FollowAnimator[T]) step(dt f64) {
	mut a := unsafe { fa } // BUG: workaround mutable generic interfaces

	value := a.value + ((a.target - a.value) * 0.1 * (dt * (dt * 1000)) * a.multiply)
	// value := utils.remap(a.t, 0, 1.0, a.from, a.to)
	lerp_value := utils.lerp(value, a.prev_value, dt)
	a.value = T(lerp_value)

	// round_to_even() ?? (Banker's round)
	p_running := a.running
	a.running = mth.round_to_even(utils.manhattan_distance(a.value, 0, a.target, 0)) != 0
	if a.running != p_running {
		if a.running {
			a.fire_event_fn(.begin)
		} else {
			a.fire_event_fn(.end)
		}
	}
	a.prev_value = a.value
}
