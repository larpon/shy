// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
//
// All angles are in radians.
module lib

import math
// import mth
import shy.vec { Vec2 }

// basic primitives

// Rect represents the data structure of a rectangle
pub struct Rect {
pub mut:
	x      f32
	y      f32
	width  f32 = 100
	height f32 = 100
}

[inline]
pub fn (r &Rect) contains(x f32, y f32) bool {
	return x >= r.x && y >= r.y && x <= r.x + r.width && y <= r.y + r.height
}

[inline]
pub fn (mut r Rect) displace_from(origin Anchor) {
	r.x, r.y = origin.displace_rect(r)
}

[inline]
pub fn (r &Rect) displaced_from(origin Anchor) Rect {
	rx, ry := origin.displace_rect(r)
	return Rect{
		x: rx
		y: ry
		width: r.width
		height: r.height
	}
}

pub fn (r &Rect) mul_scalar(scalar f32) Rect {
	return Rect{
		x: r.x * scalar
		y: r.y * scalar
		width: r.width * scalar
		height: r.height * scalar
	}
}

pub struct Ray {
pub mut:
	origin Vec2[f32] // origin point
	angle  f32       // radians
}

// Line represents the data structure of a line segment.
// line segments can be converted to the `Ray` type,
// which represents an "infinite" line originating from a point.
pub struct Line {
pub mut:
	a Vec2[f32]
	b Vec2[f32] = Vec2[f32]{
		x: 100
		y: 100
	}
}

[inline]
pub fn (l &Line) length() f32 {
	return l.a.distance(l.b)
}

[inline]
pub fn (l &Line) manhattan_length() f32 {
	return l.a.manhattan_distance(l.b)
}

[inline]
pub fn (mut l Line) switch_a_b() {
	l.a, l.b = l.b, l.a
}

[inline]
pub fn (mut l Line) ensure_a_left_b_right() {
	if l.a.x > l.b.x {
		l.switch_a_b()
	}
}

[inline]
pub fn (l &Line) slope() f32 {
	return (l.b.y - l.a.y) / (l.b.x - l.a.x)
}

[inline]
pub fn (l &Line) slope_angle() f32 {
	return math.abs(f32(math.atan((l.b.y - l.a.y) / (l.b.x - l.a.x))))
}

[inline]
pub fn (mut l Line) grow_a(length f32) {
	len_a_b := l.length()
	c_x := l.b.x + (l.b.x - l.a.x) / len_a_b * length
	c_y := l.b.y + (l.b.y - l.a.y) / len_a_b * length
	l.a.x = c_x
	l.a.y = c_y
}

[inline]
pub fn (mut l Line) grow_b(length f32) {
	len_a_b := l.length()
	c_x := l.b.x + (l.b.x - l.a.x) / len_a_b * length
	c_y := l.b.y + (l.b.y - l.a.y) / len_a_b * length
	l.b.x = c_x
	l.b.y = c_y
}

[inline]
pub fn (l &Line) to_ray() Ray {
	return Ray{
		origin: l.a
		angle: l.slope_angle()
	}
}

[inline]
pub fn (l &Line) intersect_rect(r Rect) (u8, f32, f32, f32, f32) {
	x1 := l.a.x
	y1 := l.a.y
	x2 := l.b.x
	y2 := l.b.y

	rx := r.x
	ry := r.y
	rw := r.width
	rh := r.height

	// check if the line has hit any of the rectangle's sides
	// uses the Line/Line function below
	left, left_x, left_y := line_line_intersect(x1, y1, x2, y2, rx, ry, rx, ry + rh)
	right, right_x, right_y := line_line_intersect(x1, y1, x2, y2, rx + rw, ry, rx + rw,
		ry + rh)
	top, top_x, top_y := line_line_intersect(x1, y1, x2, y2, rx, ry, rx + rw, ry)
	bottom, bottom_x, bottom_y := line_line_intersect(x1, y1, x2, y2, rx, ry + rh, rx + rw,
		ry + rh)

	mut hits := [4]f32{}
	mut intersects_in_x_places := u8(0)
	// if ANY of the above are true, the line
	// has hit the rectangle
	if left || right || top || bottom {
		intersects_in_x_places++
		mut si := intersects_in_x_places - 1
		if top {
			hits[si] = top_x
			hits[si + 1] = top_y
			si = 2
		}
		if left {
			hits[si] = left_x
			hits[si + 1] = left_y
			if si == 2 {
				intersects_in_x_places++
				return intersects_in_x_places, hits[0], hits[1], hits[2], hits[3]
			}
			si = 2
		}
		if right {
			hits[si] = right_x
			hits[si + 1] = right_y
			if si == 2 {
				intersects_in_x_places++
				return intersects_in_x_places, hits[0], hits[1], hits[2], hits[3]
			}
			si = 2
		}
		if bottom {
			hits[si] = bottom_x
			hits[si + 1] = bottom_y
			if si == 2 {
				intersects_in_x_places++
				return intersects_in_x_places, hits[0], hits[1], hits[2], hits[3]
			}
			si = 2
		}
		return intersects_in_x_places, hits[0], hits[1], hits[2], hits[3]
	}
	return 0, 0, 0, 0, 0
}

[inline]
pub fn (l &Line) hit_rect(r Rect) bool {
	// From https://www.jeffreythompson.org/collision-detection/line-rect.php

	x1 := l.a.x
	y1 := l.a.y
	x2 := l.b.x
	y2 := l.b.y

	rx := r.x
	ry := r.y
	rw := r.width
	rh := r.height

	// check if the line has hit any of the rectangle's sides
	// uses the Line/Line function below
	left := line_hit_line(x1, y1, x2, y2, rx, ry, rx, ry + rh)
	right := line_hit_line(x1, y1, x2, y2, rx + rw, ry, rx + rw, ry + rh)
	top := line_hit_line(x1, y1, x2, y2, rx, ry, rx + rw, ry)
	bottom := line_hit_line(x1, y1, x2, y2, rx, ry + rh, rx + rw, ry + rh)

	// if ANY of the above are true, the line
	// has hit the rectangle
	if left || right || top || bottom {
		return true
	}
	return false
}

[inline]
pub fn (l1 &Line) hit_line(l2 Line) bool {
	x1 := l1.a.x
	y1 := l1.a.y
	x2 := l1.b.x
	y2 := l1.b.y

	x3 := l2.a.x
	y3 := l2.a.y
	x4 := l2.b.x
	y4 := l2.b.y

	return line_hit_line(x1, y1, x2, y2, x3, y3, x4, y4)
}

[inline]
pub fn line_hit_line(x1 f32, y1 f32, x2 f32, y2 f32, x3 f32, y3 f32, x4 f32, y4 f32) bool {
	// From https://www.jeffreythompson.org/collision-detection/line-rect.php
	// calculate the direction of the lines
	u_a := ((x4 - x3) * (y1 - y3) - (y4 - y3) * (x1 - x3)) / ((y4 - y3) * (x2 - x1) - (x4 - x3) * (y2 - y1))
	u_b := ((x2 - x1) * (y1 - y3) - (y2 - y1) * (x1 - x3)) / ((y4 - y3) * (x2 - x1) - (x4 - x3) * (y2 - y1))

	// if u_a and u_b are between 0-1, lines are colliding
	if u_a >= 0 && u_a <= 1 && u_b >= 0 && u_b <= 1 {
		// intersection_x := x1 + (u_a * (x2-x1))
		// intersection_y := y1 + (u_a * (y2-y1))
		return true
	}
	return false
}

[inline]
pub fn line_line_intersect(x1 f32, y1 f32, x2 f32, y2 f32, x3 f32, y3 f32, x4 f32, y4 f32) (bool, f32, f32) {
	// From https://www.jeffreythompson.org/collision-detection/line-rect.php
	// calculate the direction of the lines
	u_a := ((x4 - x3) * (y1 - y3) - (y4 - y3) * (x1 - x3)) / ((y4 - y3) * (x2 - x1) - (x4 - x3) * (y2 - y1))
	u_b := ((x2 - x1) * (y1 - y3) - (y2 - y1) * (x1 - x3)) / ((y4 - y3) * (x2 - x1) - (x4 - x3) * (y2 - y1))

	// if u_a and u_b are between 0-1, lines are colliding
	if u_a >= 0 && u_a <= 1 && u_b >= 0 && u_b <= 1 {
		intersection_x := x1 + (u_a * (x2 - x1))
		intersection_y := y1 + (u_a * (y2 - y1))
		return true, intersection_x, intersection_y
	}
	return false, 0, 0
}

// Circle represents the data structure of a circle with origin at `x`,`y`.
pub struct Circle {
pub mut:
	x      f32
	y      f32
	radius f32 = 50
}

[inline]
pub fn (c &Circle) bbox() Rect {
	return Rect{
		x: c.x - (c.radius * 0.5)
		y: c.y - (c.radius * 0.5)
		width: c.radius * 2
		height: c.radius * 2
	}
}

pub struct Size {
pub mut:
	width  f32 = 100
	height f32 = 100
}

pub fn (s &Size) to_rect() Rect {
	return Rect{
		x: 0
		y: 0
		width: s.width
		height: s.height
	}
}

pub fn (s Size) mul_scalar(scalar f32) Size {
	return Size{
		width: s.width * scalar
		height: s.height * scalar
	}
}

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

pub fn (a Anchor) pos_wh[T](w T, h T) (T, T) {
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
			x = r.x + (r.width / 2)
			y = r.y
		}
		.top_right {
			x = r.x + r.width
			y = r.y
		}
		.center_left {
			x = r.x
			y = r.y + (r.height / 2)
		}
		.center {
			x = r.x + (r.width / 2)
			y = r.y + (r.height / 2)
		}
		.center_right {
			x = r.x + r.width
			y = r.y + (r.height / 2)
		}
		.bottom_left {
			x = r.x
			y = r.y + r.height
		}
		.bottom_center {
			x = r.x + (r.width / 2)
			y = r.y + r.height
		}
		.bottom_right {
			x = r.x + r.width
			y = r.y + r.height
		}
	}
	return x, y
}

pub fn (a Anchor) displace_rect(r Rect) (f32, f32) {
	mut x, mut y := f32(0), f32(0)
	match a {
		.top_left {
			x = r.x
			y = r.y
		}
		.top_center {
			x = r.x - (r.width / 2)
			y = r.y
		}
		.top_right {
			x = r.x - r.width
			y = r.y
		}
		.center_left {
			x = r.x
			y = r.y - (r.height / 2)
		}
		.center {
			x = r.x - (r.width / 2)
			y = r.y - (r.height / 2)
		}
		.center_right {
			x = r.x - r.width
			y = r.y - (r.height / 2)
		}
		.bottom_left {
			x = r.x
			y = r.y - r.height
		}
		.bottom_center {
			x = r.x - (r.width / 2)
			y = r.y - r.height
		}
		.bottom_right {
			x = r.x - r.width
			y = r.y - r.height
		}
	}
	return x, y
}
