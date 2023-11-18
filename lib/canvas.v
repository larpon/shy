// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module lib

// Canvas represents properties of the actual backend pixel buffer.
// On high DPI aware systems the pixel buffer returned by the hardware
// abstraction layer (OpenGL, Metal, etc.) can be some factor larger
// than the actual *window* size. Example:
// You ask the system to open a window of size 600x480 pixels with an accelerated
// context. The system opens a window in 600x480 pixels - but the accelerated
// contexts's pixel buffer is *twice* as big: 1200x960 pixels. Then all the
// stupid chaos begins and everything looks smaller etc.
@[noinit]
pub struct Canvas {
pub:
	width    f32
	height   f32
	factor   f32 = 1.0
	factor_x f32 = 1.0
	factor_y f32 = 1.0
}

pub fn (c Canvas) wh() (int, int) {
	return int(c.width), int(c.height)
}

pub fn (c Canvas) size() Size {
	return Size{
		width: c.width
		height: c.height
	}
}

pub fn (c Canvas) rect() Rect {
	return Rect{
		x: 0
		y: 0
		width: c.width
		height: c.height
	}
}

pub fn (c Canvas) factor_xy() (f32, f32) {
	return c.factor_x, c.factor_y
}
