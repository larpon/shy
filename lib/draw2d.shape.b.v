// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module lib

import shy.vec { Vec2 }
import shy.mth
import math
import shy.wraps.sokol.gl

// DrawShape2D
pub struct DrawShape2D {
	ShyFrame
}

pub fn (mut d2d DrawShape2D) begin() {
	d2d.ShyFrame.begin()

	win := d2d.shy.api.wm.active_window()
	w, h := win.drawable_wh()
	// ratio := f32(w)/f32(h)

	// unsafe { d2d.shy.api.draw.layer++ }
	// gl.set_context(gl.default_context)
	// gl.layer(d2d.shy.api.draw.layer)

	gl.defaults()

	// gl.set_context(s_gl_context)
	gl.matrix_mode_projection()
	gl.ortho(0.0, f32(w), f32(h), 0.0, -1.0, 1.0)
}

pub fn (mut d2d DrawShape2D) end() {
	d2d.ShyFrame.end()
	// gl.draw_layer(d2d.shy.api.draw.layer)
}

fn radius_to_segments(r f32) u32 {
	div := if r < 20 { u32(4) } else { u32(8) }
	/*
	// Logic:
	if r < 20 {
		div /= 2
	}
	*/
	$if shy_debug_radius_to_segments ? {
		segments := u32(mth.ceil(math.tau * r / div))
		eprintln('Segments: ${segments} r: ${r}')
		return segments
	}
	return u32(mth.ceil(math.tau * r / div))
}

pub fn (d2d &DrawShape2D) rect(config DrawShape2DRect) DrawShape2DRect {
	return config
}

pub fn (d2d &DrawShape2D) line_segment(config DrawShape2DLineSegment) DrawShape2DLineSegment {
	return config
}

pub fn (d2d &DrawShape2D) circle(config DrawShape2DUniformPolygon) DrawShape2DUniformPolygon {
	return config
	/*
	return DrawShape2DUniformPolygon{
		...config
		segments: d2d.radius_to_segments(config.radius)
	}
	*/
}

pub fn (d2d &DrawShape2D) uniform_poly(config DrawShape2DUniformPolygon) DrawShape2DUniformPolygon {
	segments := if config.segments <= 2 { u32(3) } else { config.segments }
	return DrawShape2DUniformPolygon{
		...config
		segments: segments
	}
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
	fills    Fill = .body | .outline
	offset   Vec2[f32]
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

	gl.push_matrix()
	o_off_x, o_off_y := r.origin_offset()

	gl.translate(o_off_x, o_off_y, 0)
	gl.translate(x + r.offset.x, y + r.offset.y, 0)

	if r.rotation != 0 {
		gl.translate(-o_off_x, -o_off_y, 0)
		gl.rotate(r.rotation, 0, 0, 1.0)
		gl.translate(o_off_x, o_off_y, 0)
	}
	if r.scale != 1 {
		gl.translate(-o_off_x, -o_off_y, 0)
		gl.scale(r.scale, r.scale, 1)
		gl.translate(o_off_x, o_off_y, 0)
	}

	if r.fills.has(.body) {
		color := r.color
		gl.c4b(color.r, color.g, color.b, color.a)
		gl.begin_quads()
		gl.v2f(sx, sy)
		gl.v2f((sx + w), sy)
		gl.v2f((sx + w), (sy + h))
		gl.v2f(sx, (sy + h))
		gl.end()
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
			gl.c4b(color.r, color.g, color.b, color.a)
			gl.begin_line_strip()
			gl.v2f(sx, sy)
			gl.v2f((sx + w), sy)
			gl.v2f((sx + w), (sy + h))
			gl.v2f(sx, (sy + h))
			gl.v2f(sx, sy) // TODO render error, lines should meet
			gl.end()
		}
	}

	gl.translate(-f32(x), -f32(y), 0)
	gl.pop_matrix()
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
	offset   Vec2[f32]
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
	gl.c4b(color.r, color.g, color.b, color.a)

	x1_ := x1 * scale_factor
	y1_ := y1 * scale_factor
	dx := x1 - x1_
	dy := y1 - y1_
	x2_ := x2 - dx
	y2_ := y2 - dy

	gl.push_matrix()
	o_off_x, o_off_y := l.origin_offset()

	gl.translate(o_off_x, o_off_y, 0)
	// gl.translate(x + r.offset.x, y + r.offset.y + r.offset.y, 0)

	if l.rotation != 0 {
		gl.translate(-o_off_x, -o_off_y, 0)
		gl.rotate(l.rotation * mth.deg2rad, 0, 0, 1.0)
		gl.translate(o_off_x, o_off_y, 0)
	}
	if l.scale != 1 {
		gl.translate(-o_off_x, -o_off_y, 0)
		gl.scale(l.scale, l.scale, 1)
		gl.translate(o_off_x, o_off_y, 0)
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

		gl.begin_quads()
		gl.v2f(tl_x, tl_y)
		gl.v2f(tr_x, tr_y)
		gl.v2f(br_x, br_y)
		gl.v2f(bl_x, bl_y)
		gl.end()
	} else {
		gl.begin_line_strip()
		gl.v2f(x1_, y1_)
		gl.v2f(x2_, y2_)
		gl.end()
	}

	// gl.translate(-f32(x), -f32(y), 0)
	gl.pop_matrix()
	// gl.draw()
}

// DrawShape2DUniformPolygon
[params]
pub struct DrawShape2DUniformPolygon {
	Circle
pub mut:
	visible  bool = true
	segments u32 // a value of 0 to 2 here will default to 3, use DrawShape2D.radius_to_segments() for automatic calculation
	color    Color
	stroke   Stroke
	rotation f32 // TODO decide if we should leave this here for consistency, segmented drawing allow for a visual difference when setting a rotation
	scale    f32  = 1.0
	fills    Fill = .body | .outline
	offset   Vec2[f32]
	origin   Anchor = .center
}

[inline]
pub fn (up &DrawShape2DUniformPolygon) origin_offset() (f32, f32) {
	bbox := up.bbox()
	p_x, p_y := up.origin.pos_wh(bbox.w, bbox.h)
	return -p_x, -p_y
}

[inline]
pub fn (up &DrawShape2DUniformPolygon) draw() {
	r := up.bbox()
	// A sane default is to let uniform polygons (e.g. circles)
	// draw from their origin, we compensate for that here
	x := up.x + r.w * 0.5
	y := up.y + r.h * 0.5
	radius := up.radius
	mut segments := up.segments
	if segments <= 2 {
		// segments = 3
		segments = radius_to_segments(radius)
	}
	sx := 0 // x //* scale_factor
	sy := 0 // y //* scale_factor
	o_off_x, o_off_y := up.origin_offset()

	gl.push_matrix()

	gl.translate(o_off_x, o_off_y, 0)
	gl.translate(x + up.offset.x, y + up.offset.y, 0)

	if up.rotation != 0 {
		gl.translate(-o_off_x, -o_off_y, 0)
		gl.rotate(up.rotation * mth.deg2rad, 0, 0, 1.0)
		gl.translate(o_off_x, o_off_y, 0)
	}
	if up.scale != 1 {
		gl.translate(-o_off_x, -o_off_y, 0)
		gl.scale(up.scale, up.scale, 1)
		gl.translate(o_off_x, o_off_y, 0)
	}

	mut theta := f32(0)
	mut xx := f32(0)
	mut yy := f32(0)

	if up.fills.has(.body) {
		color := up.color

		gl.c4b(color.r, color.g, color.b, color.a)

		theta = 2.0 * f32(mth.pi)
		mut px := radius * math.cosf(theta) + sx
		mut py := radius * math.sinf(theta) + sy
		gl.begin_triangles()
		for i in 1 .. segments + 1 {
			theta = 2.0 * f32(mth.pi) * f32(i) / f32(segments)
			xx = radius * math.cosf(theta)
			yy = radius * math.sinf(theta)

			gl.v2f(px, py)
			gl.v2f(xx + sx, yy + sy)
			gl.v2f(sx, sy)

			px = xx + sx
			py = yy + sy
		}
		gl.end()
	}
	if up.fills.has(.outline) {
		if up.stroke.width > 1 {
			for i := 0; i < segments; i++ {
				theta = 2.0 * f32(mth.pi) * f32(i) / f32(segments)
				x1 := sx + (radius * math.cosf(theta))
				y1 := sy + (radius * math.sinf(theta))
				theta = 2.0 * f32(mth.pi) * f32(i + 1) / f32(segments)
				x2 := sx + (radius * math.cosf(theta))
				y2 := sy + (radius * math.sinf(theta))
				theta = 2.0 * f32(mth.pi) * f32(i + 2) / f32(segments)
				x3 := sx + (radius * math.cosf(theta))
				y3 := sy + (radius * math.sinf(theta))

				m12x, m12y := midpoint(x1, y1, x2, y2)
				m23x, m23y := midpoint(x2, y2, x3, y3)

				up.draw_anchor(m12x, m12y, x2, y2, m23x, m23y)
			}
		} else {
			color := up.stroke.color
			gl.c4b(color.r, color.g, color.b, color.a)

			theta = 2.0 * f32(mth.pi)
			mut px := radius * math.cosf(theta) + sx
			mut py := radius * math.sinf(theta) + sy
			gl.begin_line_strip()
			for i in 1 .. segments + 1 {
				theta = 2.0 * f32(mth.pi) * f32(i) / f32(segments)
				xx = radius * math.cosf(theta)
				yy = radius * math.sinf(theta)

				gl.v2f(px, py)
				gl.v2f(xx, yy)

				px = xx + sx
				py = yy + sy
			}
			gl.end()
		}
	}

	gl.translate(-f32(x), -f32(y), 0)
	gl.pop_matrix()
}

[inline]
fn (up &DrawShape2DUniformPolygon) draw_anchor(x1 f32, y1 f32, x2 f32, y2 f32, x3 f32, y3 f32) {
	draw_anchor(up.stroke, x1, y1, x2, y2, x3, y3)
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

	gl.c4b(color.r, color.g, color.b, color.a)

	if radius == 1 {
		gl.begin_line_strip()
		gl.v2f(x1, y1)
		gl.v2f(x2, y2)
		gl.end()
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
		gl.begin_triangles()
		gl.v2f(t0_x, t0_y)
		gl.v2f(vp_x, vp_y)
		gl.v2f(vpp_x, vpp_y)

		gl.v2f(vpp_x, vpp_y)
		gl.v2f(t0r_x, t0r_y)
		gl.v2f(t0_x, t0_y)

		gl.v2f(vp_x, vp_y)
		gl.v2f(vpp_x, vpp_y)
		gl.v2f(t2_x, t2_y)

		gl.v2f(vpp_x, vpp_y)
		gl.v2f(t2r_x, t2r_y)
		gl.v2f(t2_x, t2_y)
		gl.end()
	} else if connect == .bevel {
		gl.begin_triangles()
		gl.v2f(t0_x, t0_y)
		gl.v2f(at_x, at_y)
		gl.v2f(vpp_x, vpp_y)

		gl.v2f(vpp_x, vpp_y)
		gl.v2f(t0r_x, t0r_y)
		gl.v2f(t0_x, t0_y)

		gl.v2f(at_x, at_y)
		gl.v2f(bt_x, bt_y)
		gl.v2f(vpp_x, vpp_y)

		gl.v2f(vpp_x, vpp_y)
		gl.v2f(bt_x, bt_y)
		gl.v2f(t2_x, t2_y)

		gl.v2f(vpp_x, vpp_y)
		gl.v2f(t2_x, t2_y)
		gl.v2f(t2r_x, t2r_y)
		gl.end()

		/*
		// NOTE Adding this will also end up in .miter
		// gl.v2f(at_x, at_y)
		// gl.v2f(vp_x, vp_y)
		// gl.v2f(bt_x, bt_y)
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

		gl.begin_triangle_strip()
		plot.arc(vpp_x, vpp_y, line_segment_length(vpp_x, vpp_y, at_x, at_y), start_angle,
			arc_angle, u32(18), .body)
		gl.end()

		gl.begin_triangles()

		gl.v2f(t0_x, t0_y)
		gl.v2f(at_x, at_y)
		gl.v2f(vpp_x, vpp_y)

		gl.v2f(vpp_x, vpp_y)
		gl.v2f(t0r_x, t0r_y)
		gl.v2f(t0_x, t0_y)

		// TODO arc_points
		// sgl.v2f(at_x, at_y)
		// sgl.v2f(bt_x, bt_y)
		// sgl.v2f(vpp_x, vpp_y)

		gl.v2f(vpp_x, vpp_y)
		gl.v2f(bt_x, bt_y)
		gl.v2f(t2_x, t2_y)

		gl.v2f(vpp_x, vpp_y)
		gl.v2f(t2_x, t2_y)
		gl.v2f(t2r_x, t2r_y)

		gl.end()*/
	}

	// DEBUG: Expected base lines
	/*
	gl.c4b(0, 255, 0, 90)
	line(x1, y1, x2, y2)
	line(x2, y2, x3, y3)
	*/
}
