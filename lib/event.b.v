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
	timestamp: 0
	window: null
})

pub enum EventsState {
	normal
	record
	play
}

pub struct Events {
	ShyStruct
pub mut:
	state EventsState
mut:
	queue      []Event
	on_events  []OnEventFn
	recorded   []Event
	play_queue []Event
	play_next  Event
}

pub fn (mut e Events) init() ! {
	unsafe {
		e.queue.free()
		// free(e.queue) // TODO fail when using `-gc none`
	}
	e.queue = []Event{len: 0, cap: 10000, init: lib.empty_event}
	unsafe { e.queue.flags.set(.noslices | .noshrink | .nogrow) }
	analyse.max('${@MOD}.${@STRUCT}.queue.cap', e.queue.cap)
}

pub fn (mut e Events) shutdown() ! {
	e.queue.clear()
}

// listen registers the `listener` event handler.
pub fn (mut e Events) on_event(listener OnEventFn) {
	analyse.count('${@MOD}.${@STRUCT}.${@FN}()', 1)
	e.on_events << listener
}

// poll polls the event queue for the next event.
pub fn (mut e Events) poll() ?Event {
	mut input := unsafe { e.shy.api().input() }

	if e.state == .play {
		mut win := e.shy.wm().active_window()
		if e.play_queue.len == 0 {
			e.shy.log.ginfo('${@STRUCT}.${@FN}', 'nothing to play back, resetting and returning to normal')
			// e.send_record_event() ???
			// e.shy.reset() or { panic(err)}
			e.state = .normal
			win.unstep()
		} else {
			ts := e.play_next.timestamp
			now := e.shy.ticks()
			if now < ts {
				ur := win.state.update_rate
				dt := ts - now
				mut steps := u16(dt / ur)
				// win.step(1, f32(dt))
				// win.step(u16(dt/ur), f32(dt))
				// win.step(1, f32(win.state.update_rate))
				// println('now: ${now}, ts: ${ts}, steps: ${steps}')
				if steps == 0 {
					steps = 1
				}
				win.step(steps, f32(ur))
				return none
			}
			if now >= ts {
				if now != ts {
					e.shy.log.gwarn('${@STRUCT}.${@FN}', 'play back of event at ${now} > ${ts} was not exact (~${now - ts}ms late)')
				}
				e.send(e.play_next) or { panic(err) }
				if e.play_queue.len > 0 {
					e.play_next = e.play_queue.pop()
				}
			}
		}
	} else if event := input.poll_event() {
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

// record starts recording events to a recording buffer.
pub fn (mut e Events) record() {
	e.shy.log.ginfo('${@STRUCT}.${@FN}', '')
	e.send_record_event()
	e.shy.reset() or { panic(err) }
	e.play_queue.clear()
	e.recorded.clear()
	e.state = .record
}

// play_back starts play back of the current recording queue.
pub fn (mut e Events) play_back() {
	e.shy.reset() or { panic(err) }
	e.send_record_event() // TODO add record event type to event like: .record_begin, .record_end, .play_back_begin, .play_back_end
	e.play_queue = e.recorded.reverse()
	e.play_queue.drop(1) // delete the event that triggered this ??
	e.shy.log.ginfo('${@STRUCT}.${@FN}', 'starting play back of ${e.play_queue.len} events')
	e.state = .play
	e.play_next = e.play_queue.pop()
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
	analyse.count('${@MOD}.${@STRUCT}.${@FN}()', 1)
	$if shy_analyse ? {
		if ev is KeyEvent {
			// Count key events for all states (up/down)
			analyse.count[u64]('${@MOD}.${@STRUCT}.${@FN}(${typeof(ev).name}(${ev.state}))',
				1)
		} else if ev is UnkownEvent {
			analyse.count[u64]('${@MOD}.${@STRUCT}.${@FN}(${typeof(ev).name})', 1)
		} else {
			analyse.count[u64]('${@MOD}.${@STRUCT}.${@FN}(${typeof(ev).name})', 1)
		}
	}
	if ev is UnkownEvent {
		return error('${@STRUCT}.${@FN}: sending unknown events is not allowed')
	}
	analyse.max('${@MOD}.${@STRUCT}.queue.len', e.queue.len + 1)
	if e.state == .record {
		e.recorded << ev
	}
	if e.queue.len < e.queue.cap {
		analyse.count('${@MOD}.${@STRUCT}.queue <<', 1)
		e.queue << ev
		return
	}
	return error('${@STRUCT}.${@FN}: event queue is full')
}

// recorded returns a copy of the recording queue
pub fn (e Events) recorded() []Event {
	return e.recorded.clone()
}

// Internal nice-to-have functions for easier sending

// send_quit_event sends a QuitEvent
fn (mut e Events) send_quit_event(force_quit bool) {
	e.send(QuitEvent{
		timestamp: e.shy.ticks()
		window: e.shy.wm().active_window()
		request: !force_quit
	}) or { panic('${@STRUCT}.${@FN}: send failed: ${err}') }
}

// send_reset_event sends a QuitEvent
fn (mut e Events) send_record_event() {
	e.send(RecordEvent{
		timestamp: e.shy.ticks()
		window: e.shy.wm().active_window()
	}) or { panic('${@STRUCT}.${@FN}: send failed: ${err}') }
}

// import sdl
// import manymouse as mm

// TODO quit_requested
// fn (mut s Shy) quit_requested() bool {
// 	return sdl.quit_requested()
// }
