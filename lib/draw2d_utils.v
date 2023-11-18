// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module lib

import shy.vec { Vec2 }
import math // TODO
import shy.mth

struct AnchorResult {
	t0   Vec2[f32]
	t0r  Vec2[f32]
	t2   Vec2[f32]
	t2r  Vec2[f32]
	vp   Vec2[f32]
	vpp  Vec2[f32]
	at   Vec2[f32]
	bt   Vec2[f32]
	flip bool
}

@[inline]
fn anchor(x1 f32, y1 f32, x2 f32, y2 f32, x3 f32, y3 f32, radius f32) AnchorResult {
	// Original author Chris H.F. Tsang / CPOL License
	// https://www.codeproject.com/Articles/226569/Drawing-polylines-by-tessellation
	// http://artgrammer.blogspot.com/search/label/opengl

	mut t0_x := x2 - x1
	mut t0_y := y2 - y1

	mut t2_x := x3 - x2
	mut t2_y := y3 - y2

	t0_x, t0_y = perpendicular(t0_x, t0_y)
	t2_x, t2_y = perpendicular(t2_x, t2_y)

	flip := signed_area(x1, y1, x2, y2, x3, y3) > 0
	if flip {
		t0_x = -t0_x
		t0_y = -t0_y

		t2_x = -t2_x
		t2_y = -t2_y
	}

	t0_x, t0_y = normalize(t0_x, t0_y)
	t2_x, t2_y = normalize(t2_x, t2_y)
	t0_x *= radius
	t0_y *= radius

	t2_x *= radius
	t2_y *= radius

	ip_x, ip_y, _ := intersect(t0_x + x1, t0_y + y1, t0_x + x2, t0_y + y2, t2_x + x3,
		t2_y + y3, t2_x + x2, t2_y + y2)

	vp_x := ip_x
	vp_y := ip_y

	vpp_x, vpp_y := rotate_point(x2, y2, vp_x, vp_y, 180 * mth.deg2rad)

	// ---

	t0_x += x1
	t0_y += y1

	at_x := t0_x - x1 + x2
	at_y := t0_y - y1 + y2

	t2_x += x3
	t2_y += y3

	bt_x := t2_x - x3 + x2
	bt_y := t2_y - y3 + y2

	t0r_x, t0r_y := rotate_point(x1, y1, t0_x, t0_y, 180 * mth.deg2rad)
	t2r_x, t2r_y := rotate_point(x3, y3, t2_x, t2_y, 180 * mth.deg2rad)

	// println('T0: $t0_x, $t0_y vP: $vp_x, $vp_y -vP: $vpp_x, $vpp_y')
	return AnchorResult{
		t0: Vec2[f32]{t0_x, t0_y}
		t0r: Vec2[f32]{t0r_x, t0r_y}
		t2: Vec2[f32]{t2_x, t2_y}
		t2r: Vec2[f32]{t2r_x, t2r_y}
		vp: Vec2[f32]{vp_x, vp_y}
		vpp: Vec2[f32]{vpp_x, vpp_y}
		at: Vec2[f32]{at_x, at_y}
		bt: Vec2[f32]{bt_x, bt_y}
		flip: flip
	}
}

@[inline]
fn line_segment_angle(x1 f32, y1 f32, x2 f32, y2 f32) f32 {
	return mth.pi + f32(math.atan2(y1 - y2, x1 - x2))
}

@[inline]
fn line_segment_length(x1 f32, y1 f32, x2 f32, y2 f32) f32 {
	return math.sqrtf(((y2 - y1) * (y2 - y1)) + ((x2 - x1) * (x2 - x1)))
}

@[inline]
fn rotate_point(cx f32, cy f32, px f32, py f32, angle_in_radians f32) (f32, f32) {
	s := math.sinf(angle_in_radians)
	c := math.cosf(angle_in_radians)
	mut npx := px
	mut npy := py
	// translate point back to origin:
	npx -= cx
	npy -= cy
	// rotate point
	xnew := npx * c - npy * s
	ynew := npx * s + npy * c
	// translate point back:
	npx = xnew + cx
	npy = ynew + cy
	return npx, npy
}

@[inline]
fn midpoint(x1 f32, y1 f32, x2 f32, y2 f32) (f32, f32) {
	return (x1 + x2) / 2, (y1 + y2) / 2
}

// perpendicular anti-clockwise 90 degrees
@[inline]
fn perpendicular(x f32, y f32) (f32, f32) {
	return -y, x
}

@[inline]
fn signed_area(x1 f32, y1 f32, x2 f32, y2 f32, x3 f32, y3 f32) f32 {
	return (x2 - x1) * (y3 - y1) - (x3 - x1) * (y2 - y1)
}

@[inline]
fn normalize(x f32, y f32) (f32, f32) {
	w := math.sqrtf(x * x + y * y)
	return x / w, y / w
}

// x1, y1, x2, y2 = line 1
// x3, y3, x4, y4 = line 2
// output: (output point x,y, intersection type)
@[inline]
fn intersect(x1 f32, y1 f32, x2 f32, y2 f32, x3 f32, y3 f32, x4 f32, y4 f32) (f32, f32, int) {
	// Determine the intersection point of two line steps
	// http://paulbourke.net/geometry/lineline2d/
	mut mua, mut mub := f32(0), f32(0)
	mut denom, mut numera, mut numerb := f32(0), f32(0), f32(0)
	eps := f32(0.000000000001)

	denom = (y4 - y3) * (x2 - x1) - (x4 - x3) * (y2 - y1)
	numera = (x4 - x3) * (y1 - y3) - (y4 - y3) * (x1 - x3)
	numerb = (x2 - x1) * (y1 - y3) - (y2 - y1) * (x1 - x3)

	if (-eps < numera && numera < eps) && (-eps < numerb && numerb < eps)
		&& (-eps < denom && denom < eps) {
		return (x1 + x2) * 0.5, (y1 + y2) * 0.5, 2 // meaning the lines coincide
	}

	if -eps < denom && denom < eps {
		return 0, 0, 0 // meaning lines are parallel
	}

	mua = numera / denom
	mub = numerb / denom
	px := x1 + mua * (x2 - x1)
	py := y1 + mua * (y2 - y1)
	out1 := mua < 0 || mua > 1
	out2 := mub < 0 || mub > 1

	if int(out1) & int(out2) == 0 {
		return px, py, 5 // the intersection lies outside both steps
	} else if out1 {
		return px, py, 3 // the intersection lies outside segment 1
	} else if out2 {
		return px, py, 4 // the intersection lies outside segment 2
	} else {
		return px, py, 1 // the intersection lies inside both steps
	}
}

fn gen_arc_points(start_angle f32, end_angle f32, radius f32, steps u32) []f32 {
	mut arc_points := []f32{len: int(steps) * 2}
	mut angle := start_angle
	arc_length := end_angle - start_angle
	for i := 0; i <= steps; i++ {
		x := math.sinf(angle) * radius
		y := math.cosf(angle) * radius

		arc_points << x
		arc_points << y

		angle += arc_length / steps
	}
	return arc_points
}

// From sgldraw/plot/plot.v
/*
[inline]
pub fn arc(x f32, y f32, radius f32, start_angle_in_rad f32, angle_in_rad f32, steps u32, fill Fill) {
	theta := f32(angle_in_rad / f32(steps))
	tan_factor := math.tanf(theta)
	rad_factor := math.cosf(theta)
	mut x1 := f32(radius * math.cosf(start_angle_in_rad))
	mut y1 := f32(radius * math.sinf(start_angle_in_rad))
	for i := 0; i < steps + 1; i++ {
		sgl.v2f(x1 + x, y1 + y)
		if fill == .body {
			sgl.v2f(x, y)
		}
		tx := -y1
		ty := x1
		x1 += tx * tan_factor
		y1 += ty * tan_factor
		x1 *= rad_factor
		y1 *= rad_factor
	}
}

[inline]
pub fn arc_line(x f32, y f32, radius f32, width f32, start_angle_in_rad f32, angle_in_rad f32, steps u32) {
	mut theta := f32(0)
	for i := 0; i < steps; i++ {
		theta = start_angle_in_rad + angle_in_rad * f32(i) / f32(steps)
		mut x1 := (radius + width) * math.cosf(theta)
		mut y1 := (radius + width) * math.sinf(theta)
		mut x2 := (radius - width) * math.cosf(theta)
		mut y2 := (radius - width) * math.sinf(theta)
		sgl.v2f(x + x1, y + y1)
		sgl.v2f(x + x2, y + y2)
		theta = start_angle_in_rad + angle_in_rad * f32(i + 1) / f32(steps)
		mut nx1 := (radius + width) * math.cosf(theta)
		mut ny1 := (radius + width) * math.sinf(theta)
		mut nx2 := (radius - width) * math.cosf(theta)
		mut ny2 := (radius - width) * math.sinf(theta)
		sgl.v2f(x + nx1, y + ny1)
		sgl.v2f(x + nx2, y + ny2)
	}
}
*/
