// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module lib

// TODO factor WindowEvent out
pub type Event = DropBeginEvent
	| DropEndEvent
	| DropFileEvent
	| DropTextEvent
	| KeyEvent
	| MouseButtonEvent
	| MouseMotionEvent
	| MouseWheelEvent
	| QuitEvent
	| UnkownEvent
	| WindowEvent
	| WindowResizeEvent

pub struct ShyEvent {
pub:
	timestamp u64 // Value of Shy.ticks()
	window    &Window
}

pub struct UnkownEvent {
	ShyEvent
}

pub struct KeyEvent {
	ShyEvent
pub:
	which    u8 // The keyboard id, NOTE SDL doesn't really support multiple keyboards. Long story
	state    ButtonState
	key_code KeyCode
}

//
pub struct WindowEvent {
	ShyEvent
pub:
	kind WindowEventKind
}

pub enum WindowEventKind {
	@none // Never used
	shown // Window has been shown
	hidden // Window has been hidden
	exposed // Window has been exposed and should be redrawn
	moved // Window has been moved to data1, data2
	// resized // Window has been resized
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

pub struct WindowResizeEvent {
	ShyEvent
	Size
pub:
	previous Size
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

pub struct DropBeginEvent {
	ShyEvent
}

pub struct DropEndEvent {
	ShyEvent
}

pub struct DropFileEvent {
	ShyEvent
pub:
	path string // the path to the file or directory being dropped
}

pub struct DropTextEvent {
	ShyEvent
pub:
	text string // the text being dropped
}

//
pub struct QuitEvent {
	ShyEvent
pub:
	request bool // Indicates if it's only a *request* to quit
}
