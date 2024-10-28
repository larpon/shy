// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module lib

import sdl

pub fn (mut m Mouse) init() ! {
	m.shy.log.gdebug('${@STRUCT}.${@FN}', '${m.id} hi')

	// m.position(.window) doesn't work since SDL need mouse movement
	// before being able to generate *window local* mouse events
	win := m.shy.api.wm.root()
	w_x, w_y := win.position()
	w_w, w_h := win.wh()
	mgx, mgy := m.position(.global)
	if mgx > w_x && mgx < w_x + w_w && mgy > w_y && mgy < w_y + w_h {
		m.x = mgx - w_x
		m.y = mgy - w_y
	}
	// NOTE: pure function `on_mouse_event` used instead of closure (m.on_event) for better support on platforms that does not support closures
	m.shy.api.events.on_event(on_mouse_event)
}

pub fn (mut m Mouse) show() {
	sdl.show_cursor(sdl.enable)
}

pub fn (mut m Mouse) hide() {
	sdl.show_cursor(sdl.disable)
}

// xy returns the mouse coordinate relative to `position_type`.
pub fn (m Mouse) position(position_type MousePositionType) (int, int) {
	// TODO add one that maps from window to gl drawable size?
	match position_type {
		.global {
			mut mx, mut my := 0, 0
			sdl.get_global_mouse_state(&mx, &my)
			// println('global sdl: $mx,$my mouse: $m.x,$m.y')
			return mx, my
		}
		.window {
			mut mx, mut my := 0, 0
			sdl.get_mouse_state(&mx, &my)
			return mx, my
		}
	}
}

fn on_mouse_event(s &Shy, e Event) bool {
	if e !is MouseMotionEvent && e !is MouseButtonEvent && e !is MouseWheelEvent {
		return false
	}
	mut api := unsafe { s.api() }
	match e {
		MouseMotionEvent, MouseButtonEvent, MouseWheelEvent {
			if mut m := api.input.mouse(u8(e.which)) {
				return m.on_event(e)
			}
			return false
		}
		else {
			return false
		}
	}
	return false
}

fn (mut m Mouse) on_event(e Event) bool {
	if e !is MouseMotionEvent && e !is MouseButtonEvent && e !is MouseWheelEvent {
		return false
	}
	match e {
		MouseMotionEvent {
			if e.which == m.id {
				// eprintln('Setting mouse ${m.id} x,y from ${m.x},${m.y} to ${e.x},${e.y}')
				m.x = e.x
				m.y = e.y
				for handler in m.on_motion {
					assert !isnil(handler)
					// If `handler` returns true, it means
					// a listener has accepted/handled the event
					if handler(m.shy, e) {
						return true
					}
				}
			}
			return false
		}
		MouseButtonEvent {
			if e.which == m.id {
				p_state := m.is_button_down(e.button)
				m.set_button_state(e.button, e.state)
				state := m.is_button_down(e.button)

				// A press/button down
				if e.state == .down {
					for handler in m.on_button_down {
						assert !isnil(handler)
						// If `handler` returns true, it means
						// a listener has accepted/handled the event
						if handler(m.shy, e) {
							return true
						}
					}
				}

				// A release/button up
				if e.state == .up {
					for handler in m.on_button_up {
						assert !isnil(handler)
						// If `handler` returns true, it means
						// a listener has accepted/handled the event
						if handler(m.shy, e) {
							return true
						}
					}
				}

				// A click is when the samme button was previously down
				if p_state && !state {
					for handler in m.on_button_click {
						assert !isnil(handler)
						if handler(m.shy, e) {
							return true
						}
					}
				}
			}
			return false
		}
		else {
			return false
		}
	}
	return false
}
