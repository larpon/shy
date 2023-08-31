// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module lib

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
