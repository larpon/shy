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

pub struct Rect {
pub mut:
	x f32
	y f32
	w f32 = 100
	h f32 = 100
}
