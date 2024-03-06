// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module lib

// TODO factor WindowEvent out?
pub type Event = DropBeginEvent
	| DropEndEvent
	| DropFileEvent
	| DropTextEvent
	| GamepadAddedEvent
	| GamepadAxisMotionEvent
	| GamepadButtonEvent
	| GamepadRemappedEvent
	| GamepadRemovedEvent
	| GamepadSensorUpdateEvent
	| GamepadTouchpadButtonEvent
	| GamepadTouchpadMotionEvent
	| KeyEvent
	| MouseButtonEvent
	| MouseMotionEvent
	| MouseWheelEvent
	| QuitEvent
	| RecordEvent
	| UnkownEvent
	| WindowCloseEvent
	| WindowEvent
	| WindowFocusEvent
	| WindowHiddenEvent
	| WindowMaximizedEvent
	| WindowMinimizedEvent
	| WindowMoveEvent
	| WindowResizeEvent
	| WindowShownEvent

fn (e Event) serialize_as_playback_string() string {
	return match e {
		DropBeginEvent, DropEndEvent, DropTextEvent, GamepadAddedEvent, GamepadAxisMotionEvent,
		GamepadButtonEvent, GamepadRemappedEvent, GamepadRemovedEvent, GamepadSensorUpdateEvent,
		GamepadTouchpadButtonEvent, GamepadTouchpadMotionEvent, DropFileEvent, KeyEvent,
		MouseButtonEvent, MouseMotionEvent, MouseWheelEvent, QuitEvent, RecordEvent, UnkownEvent,
		WindowEvent, WindowMinimizedEvent, WindowMaximizedEvent, WindowFocusEvent, WindowMoveEvent,
		WindowCloseEvent, WindowResizeEvent, WindowShownEvent, WindowHiddenEvent {
			e.serialize_as_playback_string()
		}
	}
}

pub enum EventStringSerializeFormat {
	playback
}

pub enum WindowFocusTarget {
	keyboard
	mouse
}

pub enum WindowFocusKind {
	gained
	lost
	offered
}

@[params]
pub struct EventSerializeConfig {
	format         EventStringSerializeFormat
	format_version int
}

fn (ip Input) serialize_event[T](e Event, config EventSerializeConfig) !T {
	mut t := T{}
	$if T.typ is string {
		mut s := ''
		match config.format {
			.playback {
				s += e.ShyEvent.serialize_as_playback_string()
				s += ',${e.frame},'
				s += '${e.type_name()},'.replace('shy.lib.', '') // e.g. shy.lib.KeyEvent
				s += e.serialize_as_playback_string()
				s = s.trim(',')
			}
		}
		t = s
	} $else $if T.typ is u32 {
		// TODO reserved for more compact format
		return error('${@STRUCT}.${@FN} TODO implement me :)') // TODO
	} $else {
		return error('${@STRUCT}.${@FN} serializing as "${T.name}" is not supported')
	}
	return t
}

// deserialize_event_from_string deserialize a string serialized by
// TODO this way of storing and replaying recorded events is *slow* and memory
// intensive - it can all be made much smarter, but for now it is good enough
fn (ip Input) deserialize_event_from_string(serialized_string string, format EventStringSerializeFormat) Event {
	split := serialized_string.split(',')
	if split.len < 4 {
		return empty_event
	}
	offset := 3
	event_type := split[2]
	timestamp := split[1].u64()
	window_id := ip.shy.window(split[0].u32()) or {
		ip.shy.log.gcritical('${@STRUCT}.${@FN}', 'no window with id ${split[0]}. Error: ${err.msg()}')
		return empty_event
	}.id

	return match event_type {
		'DropBeginEvent' {
			DropBeginEvent{
				timestamp: timestamp
				window_id: window_id
			}
		}
		'DropEndEvent' {
			DropEndEvent{
				timestamp: timestamp
				window_id: window_id
			}
		}
		'DropTextEvent' {
			DropTextEvent{
				timestamp: timestamp
				window_id: window_id
				text: split[offset]
			}
		}
		'DropFileEvent' {
			DropFileEvent{
				timestamp: timestamp
				window_id: window_id
				path: split[offset]
			}
		}
		'KeyEvent' {
			KeyEvent{
				timestamp: timestamp
				window_id: window_id
				which: split[offset].u8()
				state: ButtonState.from_string(split[offset + 1]) or { ButtonState.up }
				key_code: keycode_from_string(split[offset + 2])
			}
		}
		'MouseButtonEvent' {
			MouseButtonEvent{
				timestamp: timestamp
				window_id: window_id
				which: split[offset].u8()
				button: MouseButton.from_string(split[offset + 3]) or { MouseButton.unknown }
				state: ButtonState.from_string(split[offset + 4]) or { ButtonState.up }
				clicks: split[offset + 5].u8()
				x: split[offset + 1].int()
				y: split[offset + 2].int()
			}
		}
		'MouseMotionEvent' {
			MouseMotionEvent{
				timestamp: timestamp
				window_id: window_id
				which: split[offset].u8()
				// buttons: MouseButtons.from_string(split[offset+3]) or { MouseButtons.unknown } // TODO
				x: split[offset + 1].int()
				y: split[offset + 2].int()
				rel_x: split[offset + 3].int()
				rel_y: split[offset + 4].int()
			}
		}
		'MouseWheelEvent' {
			MouseWheelEvent{
				timestamp: timestamp
				window_id: window_id
				which: split[offset].u8()
				x: split[offset + 1].int()
				y: split[offset + 2].int()
				scroll_x: split[offset + 3].int()
				scroll_y: split[offset + 4].int()
				direction: MouseWheelDirection.from_string(split[offset + 5]) or {
					MouseWheelDirection.normal
				}
			}
		}
		'QuitEvent' {
			QuitEvent{
				timestamp: timestamp
				window_id: window_id
				request: split[offset].bool()
			}
		}
		'RecordEvent' {
			RecordEvent{
				timestamp: timestamp
				window_id: window_id
			}
		}
		'WindowEvent' {
			ip.shy.log.gcritical('${@STRUCT}.${@FN}', 'event ${event_type} not implemented')
			empty_event
		}
		'WindowMoveEvent' {
			ip.shy.log.gcritical('${@STRUCT}.${@FN}', 'event ${event_type} not implemented')
			empty_event
		}
		'WindowResizeEvent' {
			ip.shy.log.gcritical('${@STRUCT}.${@FN}', 'event ${event_type} not implemented')
			empty_event
		}
		'WindowShownEvent' {
			ip.shy.log.gcritical('${@STRUCT}.${@FN}', 'event ${event_type} not implemented')
			empty_event
		}
		'WindowHiddenEvent' {
			ip.shy.log.gcritical('${@STRUCT}.${@FN}', 'event ${event_type} not implemented')
			empty_event
		}
		'WindowFocusEvent' {
			ip.shy.log.gcritical('${@STRUCT}.${@FN}', 'event ${event_type} not implemented')
			empty_event
		}
		'WindowCloseEvent' {
			ip.shy.log.gcritical('${@STRUCT}.${@FN}', 'event ${event_type} not implemented')
			empty_event
		}
		'UnkownEvent' {
			empty_event
		}
		else {
			ip.shy.log.gcritical('${@STRUCT}.${@FN}', 'event ${event_type} not implemented')
			empty_event
		}
	}
}

pub struct ShyEvent {
pub:
	timestamp u64 @[required] // Value of Shy.ticks()
	window_id u32 @[required] // The id of the window, 0 = root window, -1 = no window
}

fn (se ShyEvent) serialize_as_playback_string() string {
	return '${se.window_id},${se.timestamp}'
}

pub struct UnkownEvent {
	ShyEvent
}

fn (e UnkownEvent) serialize_as_playback_string() string {
	return ''
}

pub struct KeyEvent {
	ShyEvent
pub:
	which    u8 // The keyboard id, NOTE SDL doesn't really support multiple keyboards. Long story
	state    ButtonState
	key_code KeyCode
}

fn (e KeyEvent) serialize_as_playback_string() string {
	return '${e.which},${e.state},${e.key_code}'
}

//
pub struct WindowEvent {
	ShyEvent
pub:
	kind WindowEventKind
}

fn (e WindowEvent) serialize_as_playback_string() string {
	return '${e.kind}'
}

pub enum WindowEventKind {
	@none // Never used
	// shown // Window has been shown
	// hidden // Window has been hidden
	exposed // Window has been exposed and should be redrawn
	// moved // Window has been moved to data1, data2
	// resized // Window has been resized
	// size_changed // The window size has changed, either as a result of an API call or through the system or user changing the window size.
	// minimized // Window has been minimized
	// maximized // Window has been maximized
	restored // Window has been restored to normal size and position
	// enter // Window has gained mouse focus
	// leave // Window has lost mouse focus
	// focus_gained // Window has gained keyboard focus
	// focus_lost // Window has lost keyboard focus
	// close // The window manager requests that the window be closed
	// take_focus // Window is being offered a focus
	hit_test // Window had a hit test.
}

pub struct WindowResizeEvent {
	ShyEvent
	Size
pub:
	previous Size
}

fn (e WindowResizeEvent) serialize_as_playback_string() string {
	return '${e.Size.width},${e.Size.height},${e.previous.width},${e.previous.height}'
}

pub struct WindowMoveEvent {
	ShyEvent
pub:
	x int
	y int
}

fn (e WindowMoveEvent) serialize_as_playback_string() string {
	return '${e.x},${e.y}'
}

pub struct WindowCloseEvent {
	ShyEvent
}

fn (e WindowCloseEvent) serialize_as_playback_string() string {
	return ''
}

pub struct WindowShownEvent {
	ShyEvent
}

fn (e WindowShownEvent) serialize_as_playback_string() string {
	return ''
}

pub struct WindowHiddenEvent {
	ShyEvent
}

fn (e WindowHiddenEvent) serialize_as_playback_string() string {
	return ''
}

pub struct WindowFocusEvent {
	ShyEvent
pub:
	target WindowFocusTarget
	kind   WindowFocusKind
}

fn (e WindowFocusEvent) serialize_as_playback_string() string {
	return '${e.target},${e.kind}'
}

pub struct WindowMinimizedEvent {
	ShyEvent
}

fn (e WindowMinimizedEvent) serialize_as_playback_string() string {
	return ''
}

pub struct WindowMaximizedEvent {
	ShyEvent
}

fn (e WindowMaximizedEvent) serialize_as_playback_string() string {
	return ''
}

//
pub struct MouseMotionEvent {
	ShyEvent
pub:
	which   u16 // The mouse id
	buttons MouseButtons // The current button state
	x       int // X coordinate, relative to window
	y       int // Y coordinate, relative to window
	rel_x   int // The relative motion in the X direction
	rel_y   int // The relative motion in the Y direction
}

fn (e MouseMotionEvent) serialize_as_playback_string() string {
	return '${e.which},${e.x},${e.y},${e.rel_x},${e.rel_y}'
}

pub struct MouseButtonEvent {
	ShyEvent
pub:
	which  u16 // The mouse id
	button MouseButton // The mouse button index
	state  ButtonState
	clicks u8  // 1 for single-click, 2 for double-click, etc.
	x      int // X coordinate, relative to window
	y      int // Y coordinate, relative to window
}

fn (e MouseButtonEvent) serialize_as_playback_string() string {
	return '${e.which},${e.x},${e.y},${e.button},${e.state},${e.clicks}'
}

pub struct MouseWheelEvent {
	ShyEvent
pub:
	which     u16 // The mouse id
	x         int // X coordinate, relative to window
	y         int // Y coordinate, relative to window
	scroll_x  int // The amount scrolled horizontally, positive to the right and negative to the left
	scroll_y  int // The amount scrolled vertically, positive away from the user and negative toward the user
	direction MouseWheelDirection // When .flipped the values in .x and .y will be opposite. Multiply by -1 to change them back
}

fn (e MouseWheelEvent) serialize_as_playback_string() string {
	return '${e.which},${e.x},${e.y},${e.scroll_x},${e.scroll_y},${e.direction}'
}

pub const gamepad_axis_motion_min = -32768
pub const gamepad_axis_motion_max = 32767

pub struct GamepadAxisMotionEvent {
	ShyEvent
pub:
	which i32 // id of Gamepad instance
	axis  GamepadAxis
	value int
}

fn (e GamepadAxisMotionEvent) serialize_as_playback_string() string {
	return '${e.which},${e.axis},${e.value}'
}

pub struct GamepadButtonEvent {
	ShyEvent
pub:
	which  i32 // id of Gamepad instance
	button GamepadButton
	state  ButtonState
}

fn (e GamepadButtonEvent) serialize_as_playback_string() string {
	return '${e.which},${e.button},${e.state}'
}

pub struct GamepadAddedEvent {
	ShyEvent
pub:
	which i32 // id of Gamepad instance
}

fn (e GamepadAddedEvent) serialize_as_playback_string() string {
	return '${e.which}'
}

pub struct GamepadRemovedEvent {
	ShyEvent
pub:
	which i32 // id of Gamepad instance
}

fn (e GamepadRemovedEvent) serialize_as_playback_string() string {
	return '${e.which}'
}

pub struct GamepadRemappedEvent {
	ShyEvent
pub:
	which i32 // id of Gamepad instance
}

fn (e GamepadRemappedEvent) serialize_as_playback_string() string {
	return '${e.which}'
}

pub struct GamepadTouchpadButtonEvent {
	ShyEvent
pub:
	which    i32 // id of Gamepad instance
	touchpad int
	finger   int
	x        f32
	y        f32
	pressure f32
	state    ButtonState
}

fn (e GamepadTouchpadButtonEvent) serialize_as_playback_string() string {
	return '${e.which},${e.touchpad},${e.finger},${e.x},${e.y},${e.pressure},${e.state}'
}

pub struct GamepadTouchpadMotionEvent {
	ShyEvent
pub:
	which    i32 // id of Gamepad instance
	touchpad int
	finger   int
	x        f32
	y        f32
	pressure f32
}

fn (e GamepadTouchpadMotionEvent) serialize_as_playback_string() string {
	return '${e.which},${e.touchpad},${e.finger},${e.x},${e.y},${e.pressure}'
}

pub struct GamepadSensorUpdateEvent {
	ShyEvent
pub:
	which        i32 // id of Gamepad instance
	sensor       GamepadSensorType
	finger       int
	data         [3]f32
	timestamp_us u64
}

fn (e GamepadSensorUpdateEvent) serialize_as_playback_string() string {
	return '${e.which},${e.sensor},${e.finger},${e.data[0]},${e.data[1]},${e.data[2]},${e.timestamp_us}'
}

pub struct DropBeginEvent {
	ShyEvent
}

fn (e DropBeginEvent) serialize_as_playback_string() string {
	return 'TODO'
}

pub struct DropEndEvent {
	ShyEvent
}

fn (e DropEndEvent) serialize_as_playback_string() string {
	return 'TODO'
}

pub struct DropFileEvent {
	ShyEvent
pub:
	path string // the path to the file or directory being dropped
}

fn (e DropFileEvent) serialize_as_playback_string() string {
	return '"${e.path}"'
}

pub struct DropTextEvent {
	ShyEvent
pub:
	text string // the text being dropped
}

fn (e DropTextEvent) serialize_as_playback_string() string {
	return '"${e.text}"'
}

// RecordEvent
pub struct RecordEvent {
	ShyEvent
}

fn (e RecordEvent) serialize_as_playback_string() string {
	return ''
}

//
pub struct QuitEvent {
	ShyEvent
pub:
	request bool // Indicates if it's only a *request* to quit
}

fn (e QuitEvent) serialize_as_playback_string() string {
	return '${e.request}'
}
