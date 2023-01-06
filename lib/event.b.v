// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module lib

import analyse

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
	queue []Event
}

pub fn (mut e Events) init() ! {
	unsafe {
		e.queue.free()
		free(e.queue)
	}
	e.queue = []Event{len: 0, cap: 10000, init: lib.empty_event}
	unsafe { e.queue.flags.set(.noslices | .noshrink | .nogrow) }
}

pub fn (mut e Events) shutdown() ! {
	e.queue.clear()
}

// poll polls the event queue for the next event.
pub fn (mut e Events) poll() ?Event {
	mut input := unsafe { e.shy.api().input() }
	if event := input.poll_event() {
		e.push(event) or { panic(err) }
	}
	return e.pop()
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

// push pushes an event to the event queue.
pub fn (mut e Events) push(ev Event) ! {
	if ev is UnkownEvent {
		return error('${@STRUCT}.${@FN}: pushing unknown events is not allowed')
	}
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
