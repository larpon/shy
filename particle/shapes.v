// Copyright(C) 2020 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license file distributed with this software package

module particle

import shy.vec

type Shape = Ellipse | Point | Rect

pub struct Point {
pub mut:
	position vec.Vec2[f64]
}

pub struct Rect {
pub mut:
	position vec.Vec2[f64]
	size     vec.Vec2[f64]
}

pub struct Ellipse {
pub mut:
	position vec.Vec2[f64]
	radius   f32
}
