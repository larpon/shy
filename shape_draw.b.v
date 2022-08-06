// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module solid

import math
import sgp

pub fn (s Solid) shape_draw() ShapeDraw {
	return ShapeDraw{
		// solid: &s
	}
}

pub struct ShapeDraw {
pub mut:
	// solid &Solid
	colors [solid.color_target_size]Color = [rgb(0, 0, 0), rgb(255, 255, 255)]!
	// TODO clear up this mess, try using just shapes that can draw themselves instead
	radius   f32     = 1.0
	scale    f32     = 1.0
	fill     Fill    = .solid | .outline
	cap      Cap     = .butt
	connect  Connect = .bevel
	offset_x f32     = 0.0
	offset_y f32     = 0.0
}

pub fn (sd ShapeDraw) fill_color() Color {
	return sd.colors[0]
}

pub fn (sd ShapeDraw) outline_color() Color {
	return sd.colors[1]
}

pub fn (sd ShapeDraw) rectangle(x f32, y f32, w f32, h f32) {
	sx := x //* scale_factor
	sy := y //* scale_factor
	if sd.fill.has(.solid) {
		color := sd.fill_color()
		if color.a < 255 {
			sgp.set_blend_mode(.blend)
		}
		c := color.as_f32()

		sgp.set_color(c.r, c.g, c.b, c.a)
		sgp.draw_filled_rect(x, y, w, h)
	}
	if sd.fill.has(.outline) {
		if sd.radius > 1 {
			m12x, m12y := midpoint(sx, sy, sx + w, sy)
			m23x, m23y := midpoint(sx + w, sy, sx + w, sy + h)
			m34x, m34y := midpoint(sx + w, sy + h, sx, sy + h)
			m41x, m41y := midpoint(sx, sy + h, sx, sy)
			sd.anchor(m12x, m12y, sx + w, sy, m23x, m23y)
			sd.anchor(m23x, m23y, sx + w, sy + h, m34x, m34y)
			sd.anchor(m34x, m34y, sx, sy + h, m41x, m41y)
			sd.anchor(m41x, m41y, sx, sy, m12x, m12y)
		} else {
			color := sd.outline_color()
			if color.a < 255 {
				sgp.set_blend_mode(.blend)
			}
			c := color.as_f32()

			sgp.set_color(c.r, c.g, c.b, c.a)

			sgp.draw_line(sx, sy, (sx + w), sy)
			sgp.draw_line((sx + w), sy, (sx + w), (sy + h))
			sgp.draw_line((sx + w), (sy + h), sx, (sy + h))
			sgp.draw_line(sx, (sy + h), sx, sy)
		}
	}
}

[inline]
pub fn (sd ShapeDraw) line(x1 f32, y1 f32, x2 f32, y2 f32) {
	scale_factor := sd.scale //* sgldraw.dpi_scale()

	color := sd.outline_color()
	if color.a < 255 {
		sgp.set_blend_mode(.blend)
	}
	c := color.as_f32()

	sgp.set_color(c.r, c.g, c.b, c.a)

	x1_ := x1 * scale_factor
	y1_ := y1 * scale_factor
	dx := x1 - x1_
	dy := y1 - y1_
	x2_ := x2 - dx
	y2_ := y2 - dy
	/*
	if scale_factor != 1 {
		push_matrix()
		translate(x1_, y1_, 0)
		scale(scale_factor, scale_factor, 1.0)
		translate(-x1_, -y1_, 0)
	}*/
	if sd.radius > 1 {
		radius := sd.radius

		mut tl_x := x1_ - x2_
		mut tl_y := y1_ - y2_
		tl_x, tl_y = perpendicular(tl_x, tl_y)
		tl_x, tl_y = normalize(tl_x, tl_y)
		tl_x *= radius
		tl_y *= radius
		tl_x += x1_
		tl_y += y1_

		tr_x := tl_x - x1_ + x2_
		tr_y := tl_y - y1_ + y2_

		mut bl_x := x2_ - x1_
		mut bl_y := y2_ - y1_
		bl_x, bl_y = perpendicular(bl_x, bl_y)
		bl_x, bl_y = normalize(bl_x, bl_y)
		bl_x *= radius
		bl_y *= radius
		bl_x += x1_
		bl_y += y1_

		br_x := bl_x - x1_ + x2_
		br_y := bl_y - y1_ + y2_

		// sgl.begin_quads()
		// sgl.v2f(tl_x, tl_y)
		// sgl.v2f(tr_x, tr_y)
		// sgl.v2f(br_x, br_y)
		// sgl.v2f(bl_x, bl_y)
		// sgl.end()
		sgp.draw_filled_triangle(tl_x, tl_y, tr_x, tr_y, br_x, br_y)
		sgp.draw_filled_triangle(tl_x, tl_y, bl_x, bl_y, br_x, br_y)
	} else {
		// sgl.begin_line_strip()
		// sgl.v2f(x1_, y1_)
		// sgl.v2f(x2_, y2_)
		// sgl.end()
		sgp.draw_line(x1_, y1_, x2_, y2_)
	}
	// if scale_factor != 1 {
	//	pop_matrix()
	//}
}

// Utility functions for sgldraw.ng an anchor point

[inline]
fn (sd ShapeDraw) anchor(x1 f32, y1 f32, x2 f32, y2 f32, x3 f32, y3 f32) {
	// Original author Chris H.F. Tsang / CPOL License
	// https://www.codeproject.com/Articles/226569/Drawing-polylines-by-tessellation
	// http://artgrammer.blogspot.com/search/label/opengl

	//!c := sd.colors.outline
	//!sgl.c4b(c.r, c.g, c.b, c.a)
	color := sd.outline_color()
	if color.a < 255 {
		sgp.set_blend_mode(.blend)
	}
	c := color.as_f32()
	sgp.set_color(c.r, c.g, c.b, c.a)

	radius := sd.radius
	if radius == 1 {
		sgp.draw_line(x1, y1, x2, y2)
		return
	}

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

	vpp_x, vpp_y := rotate_point(x2, y2, vp_x, vp_y, 180 * solid.deg2rad)

	// ---

	t0_x += x1
	t0_y += y1

	at_x := t0_x - x1 + x2
	at_y := t0_y - y1 + y2

	t2_x += x3
	t2_y += y3

	bt_x := t2_x - x3 + x2
	bt_y := t2_y - y3 + y2

	t0r_x, t0r_y := rotate_point(x1, y1, t0_x, t0_y, 180 * solid.deg2rad)
	t2r_x, t2r_y := rotate_point(x3, y3, t2_x, t2_y, 180 * solid.deg2rad)

	// println('T0: $t0_x, $t0_y vP: $vp_x, $vp_y -vP: $vpp_x, $vpp_y')

	if sd.connect == .miter {
		// sgl.begin_triangles()
		// sgl.v2f(t0_x, t0_y)
		// sgl.v2f(vp_x, vp_y)
		// sgl.v2f(vpp_x, vpp_y)
		sgp.draw_filled_triangle(t0_x, t0_y, vp_x, vp_y, vpp_x, vpp_y)

		// sgl.v2f(vpp_x, vpp_y)
		// sgl.v2f(t0r_x, t0r_y)
		// sgl.v2f(t0_x, t0_y)
		sgp.draw_filled_triangle(vpp_x, vpp_y, t0r_x, t0r_y, t0_x, t0_y)

		// sgl.v2f(vp_x, vp_y)
		// sgl.v2f(vpp_x, vpp_y)
		// sgl.v2f(t2_x, t2_y)
		sgp.draw_filled_triangle(vp_x, vp_y, vpp_x, vpp_y, t2_x, t2_y)

		// sgl.v2f(vpp_x, vpp_y)
		// sgl.v2f(t2r_x, t2r_y)
		// sgl.v2f(t2_x, t2_y)
		// sgl.end()
		sgp.draw_filled_triangle(vpp_x, vpp_y, t2r_x, t2r_y, t2_x, t2_y)
	} else if sd.connect == .bevel {
		// sgl.begin_triangles()
		// sgl.v2f(t0_x, t0_y)
		// sgl.v2f(at_x, at_y)
		// sgl.v2f(vpp_x, vpp_y)
		sgp.draw_filled_triangle(t0_x, t0_y, at_x, at_y, vpp_x, vpp_y)

		// sgl.v2f(vpp_x, vpp_y)
		// sgl.v2f(t0r_x, t0r_y)
		// sgl.v2f(t0_x, t0_y)
		sgp.draw_filled_triangle(vpp_x, vpp_y, t0r_x, t0r_y, t0_x, t0_y)

		// sgl.v2f(at_x, at_y)
		// sgl.v2f(bt_x, bt_y)
		// sgl.v2f(vpp_x, vpp_y)
		sgp.draw_filled_triangle(at_x, at_y, bt_x, bt_y, vpp_x, vpp_y)

		// sgl.v2f(vpp_x, vpp_y)
		// sgl.v2f(bt_x, bt_y)
		// sgl.v2f(t2_x, t2_y)
		sgp.draw_filled_triangle(vpp_x, vpp_y, bt_x, bt_y, t2_x, t2_y)

		// sgl.v2f(vpp_x, vpp_y)
		// sgl.v2f(t2_x, t2_y)
		// sgl.v2f(t2r_x, t2r_y)
		// sgl.end()
		sgp.draw_filled_triangle(vpp_x, vpp_y, t2_x, t2_y, t2r_x, t2r_y)

		/*
		// NOTE Adding this will also end up in .miter
		// sgl.v2f(at_x, at_y)
		// sgl.v2f(vp_x, vp_y)
		// sgl.v2f(bt_x, bt_y)
		sgp.draw_filled_triangle(at_x, at_y, vp_x, vp_y, bt_x, bt_y)
		*/
	} else {
		// .round
		// arc / rounded corners
		mut start_angle := line_segment_angle(vpp_x, vpp_y, at_x, at_y)
		mut arc_angle := line_segment_angle(vpp_x, vpp_y, bt_x, bt_y)
		arc_angle -= start_angle

		if arc_angle < 0 {
			if flip {
				arc_angle = arc_angle + 2.0 * solid.pi
			}
		}

		/*
		TODO port this

		sgl.begin_triangle_strip()
		plot.arc(vpp_x, vpp_y, line_segment_length(vpp_x, vpp_y, at_x, at_y), start_angle,
			arc_angle, u32(18), .solid)
		sgl.end()

		sgl.begin_triangles()

		sgl.v2f(t0_x, t0_y)
		sgl.v2f(at_x, at_y)
		sgl.v2f(vpp_x, vpp_y)

		sgl.v2f(vpp_x, vpp_y)
		sgl.v2f(t0r_x, t0r_y)
		sgl.v2f(t0_x, t0_y)

		// TODO arc_points
		// sgl.v2f(at_x, at_y)
		// sgl.v2f(bt_x, bt_y)
		// sgl.v2f(vpp_x, vpp_y)

		sgl.v2f(vpp_x, vpp_y)
		sgl.v2f(bt_x, bt_y)
		sgl.v2f(t2_x, t2_y)

		sgl.v2f(vpp_x, vpp_y)
		sgl.v2f(t2_x, t2_y)
		sgl.v2f(t2r_x, t2r_y)

		sgl.end()*/
	}

	// Expected base lines
	/*
	sgl.c4b(0, 255, 0, 90)
	line(x1, y1, x2, y2)
	line(x2, y2, x3, y3)
	*/
}

[inline]
fn line_segment_angle(x1 f32, y1 f32, x2 f32, y2 f32) f32 {
	return solid.pi + f32(math.atan2(y1 - y2, x1 - x2))
}

[inline]
fn line_segment_length(x1 f32, y1 f32, x2 f32, y2 f32) f32 {
	return math.sqrtf(((y2 - y1) * (y2 - y1)) + ((x2 - x1) * (x2 - x1)))
}

[inline]
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

[inline]
fn midpoint(x1 f32, y1 f32, x2 f32, y2 f32) (f32, f32) {
	return (x1 + x2) / 2, (y1 + y2) / 2
}

// perpendicular anti-clockwise 90 degrees
[inline]
fn perpendicular(x f32, y f32) (f32, f32) {
	return -y, x
}

[inline]
fn signed_area(x1 f32, y1 f32, x2 f32, y2 f32, x3 f32, y3 f32) f32 {
	return (x2 - x1) * (y3 - y1) - (x3 - x1) * (y2 - y1)
}

[inline]
fn normalize(x f32, y f32) (f32, f32) {
	w := math.sqrtf(x * x + y * y)
	return x / w, y / w
}

// x1, y1, x2, y2 = line 1
// x3, y3, x4, y4 = line 2
// output: (output point x,y, intersection type)
[inline]
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
		if fill == .solid {
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
