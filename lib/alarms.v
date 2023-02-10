// Copyright(C) 2023 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module lib

import shy.analyse

type AlarmID = u32
type AlarmFn = fn (voidptr, AlarmEvent)

type AlarmCheckFn = fn (voidptr) bool

pub enum AlarmEvent {
	begin
	end
}

[heap; noinit]
pub struct Alarms {
	ShyStruct
mut:
	// running bool
	paused bool
	ids    u32
	active []&Alarm = []&Alarm{cap: 2000} // Should match prealloc
	pool   []&Alarm = []&Alarm{cap: 2000} // Should match prealloc
}

fn (mut a Alarms) init() ! {
	// TODO make configurable
	prealloc := 2000
	unsafe { a.active.flags.set(.noslices | .noshrink) }
	unsafe { a.pool.flags.set(.noslices | .noshrink) }
	// unsafe { a.f64_pool.flags.set(.noslices | .noshrink) }
	for i := 0; i < prealloc; i++ {
		a.pool << a.p_new_alarm()
	}
	analyse.max('${@MOD}.${@STRUCT}.pool.len', a.pool.len)
}

pub fn (a &Alarms) is_active() bool {
	// a.running &&
	return !a.paused && a.active.len > 0
}

pub fn (a &Alarms) pause(alarm_id AlarmID, pause bool) {
	for i := 0; i < a.active.len; i++ {
		mut alarm := a.active[i]
		if alarm.id == alarm_id {
			unsafe {
				alarm.paused = pause
			}
		}
	}
}

pub fn (a &Alarms) cancel(alarm_id AlarmID) {
	for i := 0; i < a.active.len; i++ {
		mut alarm := a.active[i]
		if alarm.id == alarm_id {
			unsafe {
				alarm.running = false
				a.pool << alarm
				a.active.delete(i)
				analyse.max('${@MOD}.${@STRUCT}.pool.len', a.pool.len)
			}
		}
	}
}

[manualfree]
fn (mut a Alarms) shutdown() ! {
	for alarm in a.active {
		unsafe {
			free(alarm)
		}
	}
	for alarm in a.pool {
		unsafe {
			free(alarm)
		}
	}
}

pub fn (mut a Alarms) update() {
	if a.paused {
		return
	}
	for i := 0; i < a.active.len; i++ {
		mut alarm := a.active[i]
		if alarm.paused {
			continue
		}
		if !alarm.running {
			// TODO see if this is all worth it
			a.pool << alarm
			a.active.delete(i)
			analyse.max('${@MOD}.${@STRUCT}.pool.len', a.pool.len)
			continue
		}
		alarm.step()
	}
}

fn (s &Shy) make_alarm(config AlarmConfig) AlarmID {
	assert !isnil(s.alarms), 'Shy has not initialized alarm support'
	mut alarms := s.alarms
	return AlarmID(alarms.new_alarm(config).id)
}

fn (s &Shy) pause_alarm(alarm_id AlarmID, pause bool) {
	assert !isnil(s.alarms), 'Shy has not initialized alarm support'
	if alarm_id <= 0 {
		return
	}
	mut alarms := s.alarms
	alarms.pause(alarm_id, pause)
}

fn (s &Shy) cancel_alarm(alarm_id AlarmID) {
	assert !isnil(s.alarms), 'Shy has not initialized alarm support'
	if alarm_id <= 0 {
		return
	}
	mut alarms := s.alarms
	alarms.cancel(alarm_id)
}

fn (mut a Alarms) p_new_alarm(config AlarmConfig) &Alarm {
	a.shy.vet_issue(.warn, .hot_code, '${@STRUCT}.${@FN}', 'memory fragmentation happens when allocating in hot code paths. It is, in general, better to pre-load data.')
	analyse.count('${@MOD}.${@STRUCT}.${@FN}()', 1)
	mut alarm := &Alarm{
		shy: a.shy
	}
	alarm.reset()
	alarm.config_update(config)
	return alarm
}

fn (mut a Alarms) new_alarm(config AlarmConfig) &Alarm {
	mut alarm := &Alarm(0) // unsafe { nil }
	if isnil(config.check) {
		panic('${@STRUCT}.${@FN}: The check function *must* be provided')
	}
	if a.pool.len > 0 {
		alarm = a.pool.pop()
		alarm.reset()
		alarm.config_update(config)
	} else {
		alarm = a.p_new_alarm(config)
	}
	a.ids++
	alarm.id = a.ids
	a.active << alarm
	analyse.max('${@MOD}.${@STRUCT}.active.len', a.active.len)
	return alarm
}

[params]
pub struct AlarmConfig {
pub mut:
	running   bool = true
	paused    bool
	callback  AlarmFn
	check     AlarmCheckFn // [required] TODO BUG
	user_data voidptr
}

[noinit]
pub struct Alarm {
	ShyStruct
mut:
	id AlarmID
pub mut:
	running   bool
	paused    bool
	callback  AlarmFn
	check     AlarmCheckFn
	user_data voidptr
}

fn (mut a Alarm) config_update(config AlarmConfig) {
	a.running = config.running
	a.paused = config.paused
	a.callback = config.callback
	a.check = config.check
	a.user_data = config.user_data
}

pub fn (a &Alarm) restart() {
	unsafe {
		a.reset()
		a.run()
	}
}

pub fn (a &Alarm) run() {
	unsafe {
		a.running = true
	}
	a.fire_event_fn(.begin)
}

fn (a &Alarm) fire_event_fn(event AlarmEvent) {
	if !isnil(a.callback) {
		a.callback(a.user_data, event)
	}
}

pub fn (mut a Alarm) reset() {
	a.running = false
}

fn (mut a Alarm) ended() {
	a.fire_event_fn(.end)
	a.running = false
}

fn (mut a Alarm) step() {
	if a.check(a.user_data) {
		a.ended()
		return
	}
}
