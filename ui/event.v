// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module ui

import shy.lib as shy

pub type OnEventFn = fn (node &Node, event Event) bool

pub type OnPointerEventFn = fn (node &Node, event PointerEvent) bool

pub enum ButtonState {
	up
	down
}

pub struct UIEvent {
pub:
	timestamp u64
}

pub struct PointerEvent {
pub:
	event Event
	x     int // X coordinate, relative to window
	y     int // Y coordinate, relative to window
}

pub type Event = KeyEvent
	| MouseButtonEvent
	| MouseMotionEvent
	| MouseWheelEvent
	| QuitEvent
	| UnkownEvent
	| WindowResizeEvent

pub struct UnkownEvent {
	UIEvent
}

pub struct KeyEvent {
	UIEvent
pub:
	state    ButtonState
	key_code KeyCode
}

pub struct WindowResizeEvent {
	UIEvent
	shy.Size
pub:
	previous shy.Size
}

pub enum MouseButton {
	left
	right
	middle
	x1
	x2
}

@[flag]
pub enum MouseButtons {
	left
	right
	middle
	x1
	x2
}

pub enum MousePositionType {
	global
	window
}

pub enum MouseWheelDirection {
	normal
	flipped
}

//
pub struct MouseMotionEvent {
	UIEvent
pub:
	buttons MouseButtons // The current button state
	x       int          // X coordinate, relative to window
	y       int          // Y coordinate, relative to window
	rel_x   int          // The relative motion in the X direction
	rel_y   int          // The relative motion in the Y direction
}

pub struct MouseButtonEvent {
	UIEvent
pub:
	button MouseButton // The mouse button index
	state  ButtonState
	clicks u8  // 1 for single-click, 2 for double-click, etc.
	x      int // X coordinate, relative to window
	y      int // Y coordinate, relative to window
}

pub struct MouseWheelEvent {
	UIEvent
pub:
	x         int                 // X coordinate, relative to window
	y         int                 // Y coordinate, relative to window
	scroll_x  int                 // The amount scrolled horizontally, positive to the right and negative to the left
	scroll_y  int                 // The amount scrolled vertically, positive away from the user and negative toward the user
	direction MouseWheelDirection // When .flipped the values in .x and .y will be opposite. Multiply by -1 to change them back
}

//
pub struct QuitEvent {
	UIEvent
pub:
	request bool // Indicates if it's only a *request* to quit
}

// fn (u &UI) convert_shy_to_ui_event(shy_event shy.Event) !Event {
pub fn shy_to_ui_event(shy_event shy.Event) !Event {
	mut ui_event := Event(UnkownEvent{
		timestamp: shy_event.timestamp
	})

	match shy_event {
		shy.QuitEvent {
			ui_event = QuitEvent{
				timestamp: shy_event.timestamp
			}
		}
		shy.KeyEvent {
			// shy_key_code := map_sdl_to_shy_keycode(sdl_event.key.keysym.sym)
			ui_event = KeyEvent{
				timestamp: shy_event.timestamp
				// state: .up
				key_code: shy_event.key_code
			}
		}
		shy.MouseMotionEvent {
			ui_event = MouseMotionEvent{
				timestamp: shy_event.timestamp
				// buttons: buttons TODO
				x: shy_event.x
				y: shy_event.y
				rel_x: shy_event.rel_x
				rel_y: shy_event.rel_y
			}
		}
		shy.MouseButtonEvent {
			// if !is_multi_mice {
			// mut state := ButtonState.down
			// state = if sdl_event.button.state == u8(sdl.pressed) { .down } else { .up }
			// button := map_sdl_button_to_shy_mouse_button(sdl_event.button.button)
			ui_event = MouseButtonEvent{
				timestamp: shy_event.timestamp
				// button: button
				// state: state
				clicks: shy_event.clicks
				x: shy_event.x
				y: shy_event.y
			}
			// }
		}
		shy.MouseWheelEvent {
			// if !is_multi_mice {

			// 			mut dir := MouseWheelDirection.normal
			// 			dir = if sdl_event.wheel.direction == u32(sdl.MouseWheelDirection.normal) {
			// 				.normal
			// 			} else {
			// 				.flipped
			// 			}
			ui_event = MouseWheelEvent{
				timestamp: shy_event.timestamp
				x: shy_event.x
				y: shy_event.y
				scroll_x: shy_event.scroll_x
				scroll_y: shy_event.scroll_y
				// direction: dir
			}
			// }
		}
		else {
			ui_event = UnkownEvent{
				timestamp: shy_event.timestamp
			}
		}
	}
	return ui_event
}
