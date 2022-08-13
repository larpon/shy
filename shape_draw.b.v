// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module solid

import solid.mth
import sgp

pub fn (s &Solid) shape_draw() ShapeDraw {
	return ShapeDraw{
		solid: s
	}
}

pub struct ShapeDraw {
pub mut:
	solid  &Solid
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
				arc_angle = arc_angle + 2.0 * mth.pi
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
