// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module shy

pub type Event = KeyEvent
	| MouseButtonEvent
	| MouseMotionEvent
	| MouseWheelEvent
	| QuitEvent
	| UnkownEvent
	| WindowEvent

pub struct UnkownEvent {
pub:
	timestamp u64 // Value of Shy.ticks()
}

pub struct KeyEvent {
pub:
	timestamp u64
	which     u16 // The keyboard id
	state     ButtonState
	key_code  KeyCode
}

//
pub struct WindowEvent {
pub:
	timestamp u64
	kind      WindowEventKind
	window    &Window
}

pub enum WindowEventKind {
	@none // Never used
	shown // Window has been shown
	hidden // Window has been hidden
	exposed // Window has been exposed and should be redrawn
	moved // Window has been moved to data1, data2
	resized // Window has been resized
	// size_changed // The window size has changed, either as a result of an API call or through the system or user changing the window size.
	minimized // Window has been minimized
	maximized // Window has been maximized
	restored // Window has been restored to normal size and position
	enter // Window has gained mouse focus
	leave // Window has lost mouse focus
	focus_gained // Window has gained keyboard focus
	focus_lost // Window has lost keyboard focus
	close // The window manager requests that the window be closed
	take_focus // Window is being offered a focus
	hit_test // Window had a hit test.
}

//
pub struct MouseMotionEvent {
pub:
	timestamp u64
	window_id u32 // The window with mouse focus, if any
	which     u16 // The mouse id
	buttons   MouseButtons // The current button state
	x         int // X coordinate, relative to window
	y         int // Y coordinate, relative to window
	rel_x     int // The relative motion in the X direction
	rel_y     int // The relative motion in the Y direction
}

pub struct MouseButtonEvent {
pub:
	timestamp u64
	window_id u32 // The window with mouse focus, if any
	which     u16 // The mouse id
	button    MouseButton // The mouse button index
	state     ButtonState
	clicks    u8  // 1 for single-click, 2 for double-click, etc.
	x         int // X coordinate, relative to window
	y         int // Y coordinate, relative to window
}

pub struct MouseWheelEvent {
pub:
	timestamp u64
	window_id u32 // The window with mouse focus, if any
	which     u16 // The mouse id
	x         int // The amount scrolled horizontally, positive to the right and negative to the left
	y         int // The amount scrolled vertically, positive away from the user and negative toward the user
	direction MouseWheelDirection // When .flipped the values in .x and .y will be opposite. Multiply by -1 to change them back
}

//
pub struct QuitEvent {
pub:
	timestamp u64
	request   bool // Indicates if it's only a "nice" request to quit
}
