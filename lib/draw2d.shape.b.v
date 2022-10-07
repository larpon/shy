// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module lib

import shy.vec { Vec2 }
import shy.mth
import shy.thirdparty.sgp

// DrawShape2D
pub struct DrawShape2D {
	ShyFrame
}

pub fn (mut d2d DrawShape2D) begin() {
	d2d.ShyFrame.begin()

	win := d2d.shy.api.wm.active_window()
	w, h := win.drawable_wh()
	// ratio := f32(w)/f32(h)

	// Begin recording draw commands for a frame buffer of size (width, height).
	sgp.begin(w, h)

	// Set frame buffer drawing region to (0,0,width,height).
	sgp.viewport(0, 0, w, h)
	// Set drawing coordinate space to (left=-ratio, right=ratio, top=1, bottom=-1).
	sgp.reset_project()
	// sgp.project(-ratio, ratio, 1.0, -1.0)
	// sgp.project(0, 0, w, h)
}

pub fn (mut d2d DrawShape2D) end() {
	d2d.ShyFrame.end()
	// Dispatch all draw commands to Sokol GFX.
	sgp.flush()
	// Finish a draw command queue, clearing it.
	sgp.end()
}

pub fn (d2d &DrawShape2D) rect(config DrawShape2DRect) DrawShape2DRect {
	return config
}

pub fn (d2d &DrawShape2D) line_segment(config DrawShape2DLineSegment) DrawShape2DLineSegment {
	return config
}

pub fn (d2d &DrawShape2D) circle(config DrawShape2DCircle) DrawShape2DCircle {
	return config
}

// DrawShape2DRect
[params]
pub struct DrawShape2DRect {
	Rect
pub mut:
	visible  bool  = true
	color    Color = colors.shy.red
	stroke   Stroke
	rotation f32
	scale    f32  = 1.0
	fills    Fill = .solid | .outline
	offset   Vec2<f32>
	origin   Anchor
}

/*
pub fn (mut r DrawShape2DRect) set(config DrawShape2DRect) {
	r.Rect = config.Rect
	r.color = config.color
	r.radius = config.radius
	r.scale = config.scale
	r.fills = config.fills
	r.offset = config.offset
}
*/

[inline]
pub fn (r DrawShape2DRect) origin_offset() (f32, f32) {
	p_x, p_y := r.origin.pos_wh(r.w, r.h)
	return -p_x, -p_y
}

[inline]
pub fn (r DrawShape2DRect) draw() {
	x := r.x
	y := r.y
	w := r.w
	h := r.h
	sx := 0 // x //* scale_factor
	sy := 0 // y //* scale_factor

	sgp.push_transform()
	o_off_x, o_off_y := r.origin_offset()

	sgp.translate(o_off_x, o_off_y)
	sgp.translate(x + r.offset.x, y + r.offset.y)

	if r.rotation != 0 {
		sgp.rotate_at(r.rotation, -o_off_x, -o_off_y)
	}
	if r.scale != 1 {
		sgp.scale_at(r.scale, r.scale, -o_off_x, -o_off_y)
	}

	if r.fills.has(.solid) {
		color := r.color
		if color.a < 255 {
			sgp.set_blend_mode(.blend)
		}
		c := color.as_f32()

		sgp.set_color(c.r, c.g, c.b, c.a)
		sgp.draw_filled_rect(sx, sy, w, h)
	}
	if r.fills.has(.outline) {
		stroke_width := r.stroke.width
		if stroke_width > 1 {
			m12x, m12y := midpoint(sx, sy, sx + w, sy)
			m23x, m23y := midpoint(sx + w, sy, sx + w, sy + h)
			m34x, m34y := midpoint(sx + w, sy + h, sx, sy + h)
			m41x, m41y := midpoint(sx, sy + h, sx, sy)
			r.draw_anchor(m12x, m12y, sx + w, sy, m23x, m23y)
			r.draw_anchor(m23x, m23y, sx + w, sy + h, m34x, m34y)
			r.draw_anchor(m34x, m34y, sx, sy + h, m41x, m41y)
			r.draw_anchor(m41x, m41y, sx, sy, m12x, m12y)
		} else {
			color := r.stroke.color
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

	sgp.translate(-x, -y)
	sgp.pop_transform()

	sgp.flush()
}

[inline]
fn (r DrawShape2DRect) draw_anchor(x1 f32, y1 f32, x2 f32, y2 f32, x3 f32, y3 f32) {
	draw_anchor(r.stroke, x1, y1, x2, y2, x3, y3)
}

// DrawShape2DLineSegment

[params]
pub struct DrawShape2DLineSegment {
	Line
	Stroke
pub mut:
	visible  bool = true
	rotation f32
	scale    f32 = 1.0
	offset   Vec2<f32>
	origin   Anchor = .center_left //
}

[inline]
pub fn (l DrawShape2DLineSegment) origin_offset() (f32, f32) {
	// p_x, p_y := l.origin.pos_wh(l.a.x - l.b.x, l.a.y - l.b.y)
	// return -p_x, -p_y
	return 0, 0
}

[inline]
pub fn (l DrawShape2DLineSegment) draw() {
	if !l.visible {
		return
	}
	x1 := l.a.x
	y1 := l.a.y
	x2 := l.b.x
	y2 := l.b.y
	scale_factor := l.scale //* sgldraw.dpi_scale()
	stroke_width := l.Stroke.width

	color := l.color
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

	sgp.push_transform()
	o_off_x, o_off_y := l.origin_offset()

	sgp.translate(o_off_x, o_off_y)
	// sgp.translate(x + r.offset.x, y + r.offset.y + r.offset.y)

	if l.rotation != 0 {
		sgp.rotate_at(l.rotation, -o_off_x, -o_off_y)
	}
	if l.scale != 1 {
		sgp.scale_at(l.scale, l.scale, -o_off_x, -o_off_y)
	}

	if stroke_width > 1 {
		radius := stroke_width

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

		sgp.draw_filled_triangle(tl_x, tl_y, tr_x, tr_y, br_x, br_y)
		sgp.draw_filled_triangle(tl_x, tl_y, bl_x, bl_y, br_x, br_y)
	} else {
		sgp.draw_line(x1_, y1_, x2_, y2_)
	}

	// sgp.translate(-x, -y)
	sgp.pop_transform()
}

// DrawShape2DCircle
[params]
pub struct DrawShape2DCircle {
	Circle
pub mut:
	visible  bool = true
	segments u32 // a value of 0 to 2 here means "auto"
	color    Color
	stroke   Stroke
	rotation f32 // TODO decide if we should leave this here for consistency, segmented drawing allow for a visual difference when setting a rotation
	scale    f32  = 1.0
	fills    Fill = .solid | .outline
	offset   Vec2<f32>
	origin   Anchor = .center
}

[inline]
pub fn (c DrawShape2DCircle) origin_offset() (f32, f32) {
	bbox := c.bbox()
	p_x, p_y := c.origin.pos_wh(bbox.w, bbox.h)
	return -p_x, -p_y
}

[inline]
pub fn (c DrawShape2DCircle) draw() {
	r := c.bbox()

	x := r.x
	y := r.y
	// w := r.w
	// h := r.h
	// sx := 0 // x //* scale_factor
	// sy := 0 // y //* scale_factor

	sgp.push_transform()
	o_off_x, o_off_y := c.origin_offset()

	sgp.translate(o_off_x, o_off_y)
	sgp.translate(x + c.offset.x, y + c.offset.y)

	if c.rotation != 0 {
		sgp.rotate_at(c.rotation, -o_off_x, -o_off_y)
	}
	if c.scale != 1 {
		sgp.scale_at(c.scale, c.scale, -o_off_x, -o_off_y)
	}

	/*
	if r.fills.has(.solid) {
		color := r.colors.solid
		if color.a < 255 {
			sgp.set_blend_mode(.blend)
		}
		c := color.as_f32()

		sgp.set_color(c.r, c.g, c.b, c.a)
		sgp.draw_filled_rect(sx, sy, w, h)
	}
	if r.fills.has(.outline) {
		if r.radius > 1 {
			m12x, m12y := midpoint(sx, sy, sx + w, sy)
			m23x, m23y := midpoint(sx + w, sy, sx + w, sy + h)
			m34x, m34y := midpoint(sx + w, sy + h, sx, sy + h)
			m41x, m41y := midpoint(sx, sy + h, sx, sy)
			r.draw_anchor(m12x, m12y, sx + w, sy, m23x, m23y)
			r.draw_anchor(m23x, m23y, sx + w, sy + h, m34x, m34y)
			r.draw_anchor(m34x, m34y, sx, sy + h, m41x, m41y)
			r.draw_anchor(m41x, m41y, sx, sy, m12x, m12y)
		} else {
			color := r.colors.outline
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
	*/
	sgp.translate(-x, -y)
	sgp.pop_transform()

	sgp.flush()
}

[inline]
fn (c DrawShape2DCircle) draw_anchor(x1 f32, y1 f32, x2 f32, y2 f32, x3 f32, y3 f32) {
	draw_anchor(c.stroke, x1, y1, x2, y2, x3, y3)
}

// Utils

[inline]
fn draw_anchor(stroke Stroke, x1 f32, y1 f32, x2 f32, y2 f32, x3 f32, y3 f32) {
	// Original author Chris H.F. Tsang / CPOL License
	// https://www.codeproject.com/Articles/226569/Drawing-polylines-by-tessellation
	// http://artgrammer.blogspot.com/search/label/opengl

	color := stroke.color
	radius := stroke.width * 0.5
	connect := stroke.connect

	if color.a < 255 {
		sgp.set_blend_mode(.blend)
	}
	c := color.as_f32()
	sgp.set_color(c.r, c.g, c.b, c.a)

	if radius == 1 {
		sgp.draw_line(x1, y1, x2, y2)
		return
	}

	ar := anchor(x1, y1, x2, y2, x3, y3, radius)

	t0_x := ar.t0.x
	t0_y := ar.t0.y
	t0r_x := ar.t0r.x
	t0r_y := ar.t0r.y
	t2_x := ar.t2.x
	t2_y := ar.t2.y
	t2r_x := ar.t2r.x
	t2r_y := ar.t2r.y
	vp_x := ar.vp.x
	vp_y := ar.vp.y
	vpp_x := ar.vpp.x
	vpp_y := ar.vpp.y
	at_x := ar.at.x
	at_y := ar.at.y
	bt_x := ar.bt.x
	bt_y := ar.bt.y
	flip := ar.flip

	if connect == .miter {
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
	} else if connect == .bevel {
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
