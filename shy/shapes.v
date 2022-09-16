// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module shy

pub enum Anchor {
	top_left
	top_center
	top_right
	center_left
	center
	center_right
	bottom_left
	bottom_center
	bottom_right
}

pub fn (a Anchor) pos_wh<T>(w T, h T) (T, T) {
	mut x, mut y := T(0), T(0)
	match a {
		.top_left {
			x = 0
			y = 0
		}
		.top_center {
			x = 0 + (w / 2)
			y = 0
		}
		.top_right {
			x = 0 + w
			y = 0
		}
		.center_left {
			x = 0
			y = 0 + (h / 2)
		}
		.center {
			x = 0 + (w / 2)
			y = 0 + (h / 2)
		}
		.center_right {
			x = 0 + w
			y = 0 + (h / 2)
		}
		.bottom_left {
			x = 0
			y = 0 + h
		}
		.bottom_center {
			x = 0 + (w / 2)
			y = 0 + h
		}
		.bottom_right {
			x = 0 + w
			y = 0 + h
		}
	}
	return x, y
}

pub fn (a Anchor) opposite() Anchor {
	return match a {
		.top_left {
			.bottom_right
		}
		.top_center {
			.bottom_center
		}
		.top_right {
			.bottom_left
		}
		.center_left {
			.center_right
		}
		.center {
			.center
		}
		.center_right {
			.center_left
		}
		.bottom_left {
			.top_right
		}
		.bottom_center {
			.top_center
		}
		.bottom_right {
			.top_left
		}
	}
}

pub fn (a Anchor) next() Anchor {
	return match a {
		.top_left {
			.top_center
		}
		.top_center {
			.top_right
		}
		.top_right {
			.center_left
		}
		.center_left {
			.center
		}
		.center {
			.center_right
		}
		.center_right {
			.bottom_left
		}
		.bottom_left {
			.bottom_center
		}
		.bottom_center {
			.bottom_right
		}
		.bottom_right {
			.top_left
		}
	}
}

pub fn (a Anchor) prev() Anchor {
	return match a {
		.top_left {
			.bottom_right
		}
		.top_center {
			.top_left
		}
		.top_right {
			.top_center
		}
		.center_left {
			.top_right
		}
		.center {
			.center_left
		}
		.center_right {
			.center
		}
		.bottom_left {
			.center_right
		}
		.bottom_center {
			.bottom_left
		}
		.bottom_right {
			.bottom_center
		}
	}
}

pub fn (a Anchor) pos_rect(r Rect) (f32, f32) {
	mut x, mut y := f32(0), f32(0)
	match a {
		.top_left {
			x = r.x
			y = r.y
		}
		.top_center {
			x = r.x + (r.w / 2)
			y = r.y
		}
		.top_right {
			x = r.x + r.w
			y = r.y
		}
		.center_left {
			x = r.x
			y = r.y + (r.h / 2)
		}
		.center {
			x = r.x + (r.w / 2)
			y = r.y + (r.h / 2)
		}
		.center_right {
			x = r.x + r.w
			y = r.y + (r.h / 2)
		}
		.bottom_left {
			x = r.x
			y = r.y + r.h
		}
		.bottom_center {
			x = r.x + (r.w / 2)
			y = r.y + r.h
		}
		.bottom_right {
			x = r.x + r.w
			y = r.y + r.h
		}
	}
	return x, y
}

pub struct Rect {
pub mut:
	x f32
	y f32
	w f32 = 100
	h f32 = 100
}
