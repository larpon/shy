// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module lib

import analyse

pub type OnEventFn = fn (event Event) bool

pub enum ButtonState {
	up
	down
}

const empty_event = Event(UnkownEvent{
	window: null
})

pub struct Events {
	ShyStruct
mut:
	queue     []Event
	on_events []OnEventFn
}

pub fn (mut e Events) init() ! {
	unsafe {
		e.queue.free()
		// free(e.queue) // TODO fail when using `-gc none`
	}
	e.queue = []Event{len: 0, cap: 10000, init: lib.empty_event}
	unsafe { e.queue.flags.set(.noslices | .noshrink | .nogrow) }
}

pub fn (mut e Events) shutdown() ! {
	e.queue.clear()
}

// listen registers the `listener` event handler.
pub fn (mut e Events) on_event(listener OnEventFn) {
	analyse.count('${@STRUCT}.${@FN}', 1)
	e.on_events << listener
}

// poll polls the event queue for the next event.
pub fn (mut e Events) poll() ?Event {
	mut input := unsafe { e.shy.api().input() }
	if event := input.poll_event() {
		e.send(event) or { panic(err) }
	}

	if event := e.pop() {
		for on_event in e.on_events {
			assert !isnil(on_event)
			// If `on_event` returns true, it means
			// a listener has accepted the event in which case we
			// do not propagate the event to the rest of the system.
			if on_event(event) {
				return none
			}
		}
		return event
	}
	return none
}

// pop pops the next event from the event queue.
fn (mut e Events) pop() ?Event {
	if e.queue.len > 0 {
		ev := e.queue[0]
		e.queue.delete(0)
		return ev
	}
	return none
}

// send pushes an event to the event queue.
pub fn (mut e Events) send(ev Event) ! {
	if ev is UnkownEvent {
		return error('${@STRUCT}.${@FN}: sending unknown events is not allowed')
	}
	analyse.max('${@STRUCT}.max_in_queue', e.queue.len + 1)
	if e.queue.len < e.queue.cap {
		analyse.count('${@STRUCT}.${@FN}', 1)
		e.queue << ev
		return
	}
	return error('${@STRUCT}.${@FN}: event queue is full')
}

// import sdl
// import manymouse as mm

// TODO quit_requested
// fn (mut s Shy) quit_requested() bool {
// 	return sdl.quit_requested()
// }
