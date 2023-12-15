// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module lib

import shy.analyse
import shy.vec { Vec2 }
import shy.mth
import math
import shy.wraps.sokol.gl

// DrawShape2D
pub struct DrawShape2D {
	ShyFrame
	factor f32 = 1.0
}

pub fn (mut d2d DrawShape2D) begin() {
	d2d.ShyFrame.begin()
}

pub fn (mut d2d DrawShape2D) end() {
	d2d.ShyFrame.end()
}

fn radius_to_segments(r f32) u16 {
	div := if r < 20 { u16(4) } else { u16(8) }

	// Logic:
	// if r < 20 {
	// 	div /= 2
	//}

	$if shy_debug_radius_to_segments ? {
		segments := u16(mth.ceil(math.tau * r / div))
		eprintln('Segments: ${segments} r: ${r}')
		return segments
	}
	return u16(mth.ceil(math.tau * r / div))
}

pub fn (d2d &DrawShape2D) triangle(config DrawShape2DTriangle) DrawShape2DTriangle {
	return DrawShape2DTriangle{
		...config
		factor: d2d.factor
	}
}

pub fn (d2d &DrawShape2D) rect(config DrawShape2DRect) DrawShape2DRect {
	return DrawShape2DRect{
		...config
		factor: d2d.factor
	}
}

pub fn (d2d &DrawShape2D) line_segment(config DrawShape2DLineSegment) DrawShape2DLineSegment {
	return DrawShape2DLineSegment{
		...config
		factor: d2d.factor
	}
}

pub fn (d2d &DrawShape2D) circle(config DrawShape2DUniformPolygon) DrawShape2DUniformPolygon {
	return DrawShape2DUniformPolygon{
		...config
		factor: d2d.factor
		// segments: d2d.radius_to_segments(config.radius)
	}
}

pub fn (d2d &DrawShape2D) uniform_poly(config DrawShape2DUniformPolygon) DrawShape2DUniformPolygon {
	segments := if config.segments <= 2 { u32(3) } else { config.segments }
	return DrawShape2DUniformPolygon{
		...config
		factor: d2d.factor
		segments: segments
	}
}

// DrawShape2DTriangle
@[params]
pub struct DrawShape2DTriangle {
	Triangle
	factor f32 = 1.0
pub mut:
	visible  bool  = true
	color    Color = colors.shy.red
	stroke   Stroke
	rotation f32
	scale    f32  = 1.0
	fills    Fill = .body | .stroke
	offset   Vec2[f32]
	origin   Anchor
}

@[inline]
pub fn (t &DrawShape2DTriangle) origin_offset() (f32, f32) {
	bb := t.bbox().mul_scalar(t.factor)
	p_x, p_y := t.origin.pos_wh(bb.width, bb.height)
	return -p_x, -p_y
}

@[inline]
pub fn (t &DrawShape2DTriangle) draw() {
	scale_factor := t.factor

	mut bb := t.Triangle.bbox().mul_scalar(scale_factor)

	x := bb.x
	y := bb.y
	x1 := (t.a.x * scale_factor - x)
	y1 := (t.a.y * scale_factor - y)
	x2 := (t.b.x * scale_factor - x)
	y2 := (t.b.y * scale_factor - y)
	x3 := (t.c.x * scale_factor - x)
	y3 := (t.c.y * scale_factor - y)
	offset := t.offset.mul_scalar(scale_factor)

	mut o_off_x, mut o_off_y := t.origin_offset()

	o_off_x = int(o_off_x)
	o_off_y = int(o_off_y)

	gl.push_matrix()
	gl.translate(o_off_x, o_off_y, 0)
	gl.translate(x + offset.x, y + offset.y, 0)

	if t.rotation != 0 {
		gl.translate(-o_off_x, -o_off_y, 0)
		gl.rotate(t.rotation, 0, 0, 1.0)
		gl.translate(o_off_x, o_off_y, 0)
	}

	if t.scale != 1 {
		gl.translate(-o_off_x, -o_off_y, 0)
		gl.scale(t.scale, t.scale, 1)
		gl.translate(o_off_x, o_off_y, 0)
	}

	if t.fills.has(.body) {
		color := t.color
		gl.c4b(color.r, color.g, color.b, color.a)

		gl.begin_triangles()
		gl.v2f(x1, y1)
		gl.v2f(x2, y2)
		gl.v2f(x3, y3)
		gl.end()

		analyse.count_and_sum[u64]('${@MOD}.${@STRUCT}.${@FN}@vertices2D', 3)
	}
	if t.fills.has(.stroke) {
		stroke_width := t.stroke.width * scale_factor
		color := t.stroke.color
		gl.c4b(color.r, color.g, color.b, color.a)
		if stroke_width <= 0 {
			// Do nothing
		} else if stroke_width > 1 {
			m12x, m12y := midpoint(x1, y1, x2, y2)
			m23x, m23y := midpoint(x2, y2, x3, y3)
			m31x, m31y := midpoint(x3, y3, x1, y1)
			t.draw_anchor(m12x, m12y, x2, y2, m23x, m23y)
			t.draw_anchor(m23x, m23y, x3, y3, m31x, m31y)
			t.draw_anchor(m31x, m31y, x1, y1, m12x, m12y)
		} else {
			gl.begin_line_strip()

			gl.v2f(x1, y1)
			gl.v2f(x2, y2)

			// gl.v2f(x2_, y2_)
			gl.v2f(x3, y3)

			// gl.v2f(x3_, y3_)
			gl.v2f(x1, y1)

			gl.end()

			analyse.count_and_sum[u64]('${@MOD}.${@STRUCT}.${@FN}@vertices2D', 4)
		}
	}
	gl.translate(-x, -y, 0)
	gl.pop_matrix()
}

@[inline]
fn (t &DrawShape2DTriangle) draw_anchor(x1 f32, y1 f32, x2 f32, y2 f32, x3 f32, y3 f32) {
	draw_anchor_config := DrawAnchorConfig{
		...t.stroke
		width: t.stroke.width * t.factor
	}
	draw_anchor(x1, y1, x2, y2, x3, y3, draw_anchor_config)
}

// DrawShape2DRect
@[params]
pub struct DrawShape2DRect {
	Rect
	factor f32 = 1.0
pub mut:
	visible  bool  = true
	color    Color = colors.shy.red
	stroke   Stroke
	rotation f32
	radius   f32 // for rounded corners
	scale    f32  = 1.0
	fills    Fill = .body | .stroke
	offset   Vec2[f32]
	origin   Anchor
}

@[inline]
pub fn (r DrawShape2DRect) origin_offset() (f32, f32) {
	p_x, p_y := r.origin.pos_wh(r.width * r.factor, r.height * r.factor)
	return -p_x, -p_y
}

@[inline]
pub fn (r &DrawShape2DRect) draw() {
	// NOTE the int(...) casts and 0.5/1.0 values here is to ensure pixel-perfect results
	// this could/should maybe someday be switchable by a flag...?
	scale_factor := r.factor
	x := r.x * scale_factor
	y := r.y * scale_factor
	w := r.width * scale_factor
	h := r.height * scale_factor

	mut o_off_x, mut o_off_y := r.origin_offset()
	o_off_x = int(o_off_x)
	o_off_y = int(o_off_y)

	gl.push_matrix()
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

	if r.radius != 0 {
		r.draw_rounded(x, y, w, h)
	} else {
		r.draw_rectangle(x, y, w, h)
	}

	gl.translate(-x, -y, 0)
	gl.pop_matrix()
}

@[inline]
fn (r DrawShape2DRect) draw_rectangle(x f32, y f32, width f32, height f32) {
	sx := f32(0.0)
	sy := f32(0.0)
	w := width
	h := height
	if r.fills.has(.body) {
		color := r.color
		gl.c4b(color.r, color.g, color.b, color.a)
		gl.begin_quads()
		gl.v2f(sx, sy)
		gl.v2f((sx + w), sy)
		gl.v2f((sx + w), (sy + h))
		gl.v2f(sx, (sy + h))
		gl.end()
		analyse.count_and_sum[u64]('${@MOD}.${@STRUCT}.${@FN}@vertices2D', 4)
	}
	if r.fills.has(.stroke) {
		scale_factor := r.factor
		mut stroke_width := r.stroke.width * scale_factor
		color := r.stroke.color
		gl.c4b(color.r, color.g, color.b, color.a)
		if stroke_width <= 0 {
			// Do nothing
		} else if stroke_width > 1 {
			// TODO fix anchor rendering overflows
			if stroke_width > width {
				stroke_width = width
				stroke_width_0_5 := stroke_width * 0.5

				// TODO this is only for .butt Cap
				// TODO this could probably be done in *one* block of begin/end calls

				// top left triangle
				gl.begin_triangles()
				gl.v2f(sx - stroke_width_0_5, sy)
				gl.v2f(sx, sy - stroke_width_0_5)
				gl.v2f(sx, sy)
				gl.end()
				// top border rect
				gl.begin_quads()
				gl.v2f(sx, sy - stroke_width_0_5)
				gl.v2f((sx + w), sy - stroke_width_0_5)
				gl.v2f((sx + w), sy)
				gl.v2f(sx, sy)
				gl.end()
				// top right triangle
				gl.begin_triangles()
				gl.v2f((sx + w), sy - stroke_width_0_5)
				gl.v2f((sx + w), sy)
				gl.v2f(sx + w + stroke_width_0_5, sy)
				gl.end()
				// right border rect
				gl.begin_quads()
				gl.v2f((sx + w), sy)
				gl.v2f((sx + w + stroke_width_0_5), sy)
				gl.v2f((sx + w + stroke_width_0_5), (sy + h))
				gl.v2f((sx + w), (sy + h))
				gl.end()
				// bottom right triangle
				gl.begin_triangles()
				gl.v2f((sx + w), (sy + h))
				gl.v2f((sx + w + stroke_width_0_5), (sy + h))
				gl.v2f(sx + w, sy + h + stroke_width_0_5)
				gl.end()
				// bottom border rect
				gl.begin_quads()
				gl.v2f(sx, sy + h)
				gl.v2f((sx + w), sy + h)
				gl.v2f((sx + w), sy + h + stroke_width_0_5)
				gl.v2f(sx, sy + h + stroke_width_0_5)
				gl.end()
				// bottom left triangle
				gl.begin_triangles()
				gl.v2f(sx - stroke_width_0_5, sy + h)
				gl.v2f(sx, sy + h)
				gl.v2f(sx, sy + h + stroke_width_0_5)
				gl.end()

				// left border rect
				gl.begin_quads()
				gl.v2f((sx - stroke_width_0_5), sy)
				gl.v2f(sx, sy)
				gl.v2f(sx, (sy + h))
				gl.v2f((sx - stroke_width_0_5), (sy + h))
				gl.end()

				// body
				gl.begin_quads()
				gl.v2f(sx, sy)
				gl.v2f((sx + w), sy)
				gl.v2f((sx + w), (sy + h))
				gl.v2f(sx, (sy + h))
				gl.end()

				analyse.count_and_sum[u64]('${@MOD}.${@STRUCT}.${@FN}@vertices2D', (4*3)+(5*4))
			} else {
				m12x, m12y := midpoint(sx, sy, sx + w, sy)
				m23x, m23y := midpoint(sx + w, sy, sx + w, sy + h)
				m34x, m34y := midpoint(sx + w, sy + h, sx, sy + h)
				m41x, m41y := midpoint(sx, sy + h, sx, sy)
				r.draw_anchor(m12x, m12y, sx + w, sy, m23x, m23y)
				r.draw_anchor(m23x, m23y, sx + w, sy + h, m34x, m34y)
				r.draw_anchor(m34x, m34y, sx, sy + h, m41x, m41y)
				r.draw_anchor(m41x, m41y, sx, sy, m12x, m12y)
			}
		} else {
			// NOTE pixel-perfect lines ... ouch
			// More on pixel-perfect here: https://stackoverflow.com/a/10041050/1904615
			// See also: tests/visual/pixel-perfect_rectangles.v
			gl.begin_line_strip()
			if r.rotation == 0 {
				gl.v2f(sx, sy)
				gl.v2f((sx + w), sy)
				//
				gl.v2f((sx + 0.5 + w - 1), sy + 0.5)
				gl.v2f((sx + 0.5 + w - 1), (sy + 0.5 + h - 1))
				//
				gl.v2f((sx + 0.5 + w - 1), (sy + 0.5 + h - 1))
				gl.v2f(sx + 0.5, (sy + 0.5 + h - 1.5))
				//
				gl.v2f(sx + 0.5, (sy + 0.5 + h - 1))
				gl.v2f(sx + 0.5, sy + 0.5)
				analyse.count_and_sum[u64]('${@MOD}.${@STRUCT}.${@FN}@vertices2D', 8)
			} else {
				gl.v2f(sx, sy)
				gl.v2f((sx + w), sy)
				//
				gl.v2f((sx + w), (sy + h))
				//
				gl.v2f(sx, (sy + h))
				//
				gl.v2f(sx, sy)
				analyse.count_and_sum[u64]('${@MOD}.${@STRUCT}.${@FN}@vertices2D', 5)
			}
			gl.end()
		}
	}
}

@[inline]
fn (r DrawShape2DRect) draw_rounded(x f32, y f32, width f32, height f32) {
	w := width
	h := height
	scale_factor := r.factor
	mut radius := r.radius * scale_factor

	assert radius > 0, '${@LOCATION}, rectangle radius should be > 0' // TODO(lmp) decide if undefined behaviour is ok here, if it should be checked in higher level API layers? hmm...

	if w >= h && radius > h / 2 {
		radius = h / 2
	} else if radius > w / 2 {
		radius = w / 2
	}
	sx := f32(0.0)
	sy := f32(0.0)

	// TODO this does not work???: segments := radius_to_segments(radius)
	segments := u16(31 * scale_factor)

	// circle center coordinates
	ltx := sx + radius
	lty := sy + radius
	rtx := sx + w - radius
	rty := lty
	rbx := rtx
	rby := sy + h - radius
	lbx := ltx
	lby := rby

	mut rad := f32(0)
	mut dx := f32(0)
	mut dy := f32(0)

	// NOTE the separate begin/end drawing is to prevent transparent color overlap
	if r.fills.has(.body) {
		color := r.color
		gl.c4b(color.r, color.g, color.b, color.a)

		// TODO(lmp) the 0 .. X range should change on small radii

		// left top quarter
		gl.begin_triangle_strip()
		for i in 0 .. segments {
			rad = f32(math.radians(i * 3))
			dx = radius * math.cosf(rad)
			dy = radius * math.sinf(rad)
			gl.v2f(ltx - dx, lty - dy)
			gl.v2f(ltx, lty)
		}
		gl.end()

		// right top quarter
		gl.begin_triangle_strip()
		for i in 0 .. segments {
			rad = f32(math.radians(i * 3))
			dx = radius * math.cosf(rad)
			dy = radius * math.sinf(rad)
			gl.v2f(rtx + dx, rty - dy)
			gl.v2f(rtx, rty)
		}
		gl.end()

		// right bottom quarter
		gl.begin_triangle_strip()
		for i in 0 .. segments {
			rad = f32(math.radians(i * 3))
			dx = radius * math.cosf(rad)
			dy = radius * math.sinf(rad)
			gl.v2f(rbx + dx, rby + dy)
			gl.v2f(rbx, rby)
		}
		gl.end()

		// left bottom quarter
		gl.begin_triangle_strip()
		for i in 0 .. segments {
			rad = f32(math.radians(i * 3))
			dx = radius * math.cosf(rad)
			dy = radius * math.sinf(rad)
			gl.v2f(lbx - dx, lby + dy)
			gl.v2f(lbx, lby)
		}
		gl.end()

		// top rectangle
		gl.begin_quads()
		gl.v2f(ltx, sy)
		gl.v2f(rtx, sy)
		gl.v2f(rtx, rty)
		gl.v2f(ltx, lty)
		gl.end()
		// middle rectangle
		gl.begin_quads()
		gl.v2f(sx, lty)
		gl.v2f(rtx + radius, rty)
		gl.v2f(rbx + radius, rby)
		gl.v2f(sx, lby)
		gl.end()
		// bottom rectangle
		gl.begin_quads()
		gl.v2f(lbx, lby)
		gl.v2f(rbx, rby)
		gl.v2f(rbx, rby + radius)
		gl.v2f(lbx, rby + radius)
		gl.end()

		analyse.count_and_sum[u64]('${@MOD}.${@STRUCT}.${@FN}@vertices2D', (4 * (2 * 30)) + 3 * 4)
	}
	if r.fills.has(.stroke) {
		mut stroke_width := r.stroke.width * scale_factor
		if stroke_width > radius * 2 {
			stroke_width = radius * 2
		}
		// TODO still a lot of edgecases
		color := r.stroke.color
		gl.c4b(color.r, color.g, color.b, color.a)
		if stroke_width <= 0 {
			// Do nothing
		} else if stroke_width > 1 {
			// Draws rounded stroke on top of rounded rectangle
			start_radians := mth.deg_180_in_rad
			end_radians := mth.deg_270_in_rad
			stroke_width_0_5 := stroke_width * 0.5
			mut radius_minus_stroke_width_0_5 := radius - stroke_width_0_5

			if radius_minus_stroke_width_0_5 < 0 {
				stroke_width_remainder := radius_minus_stroke_width_0_5 + stroke_width
				// top left arc
				gl.begin_triangle_strip()
				plot_circle_sector(ltx, lty, stroke_width_remainder, start_radians, end_radians,
					segments)
				gl.end()

				// top right arc
				gl.begin_triangle_strip()
				plot_circle_sector(rtx, rty, stroke_width_remainder, start_radians - mth.deg_90_in_rad,
					end_radians - mth.deg_90_in_rad, segments)
				gl.end()

				// bottom right arc
				gl.begin_triangle_strip()
				plot_circle_sector(rbx, rby, stroke_width_remainder, start_radians - mth.deg_180_in_rad,
					end_radians - mth.deg_180_in_rad, segments)
				gl.end()

				// bottom left arc
				gl.begin_triangle_strip()
				plot_circle_sector(lbx, rby, stroke_width_remainder, start_radians - mth.deg_270_in_rad,
					end_radians - mth.deg_270_in_rad, segments)
				gl.end()

				// top border rectangle
				gl.begin_quads()
				gl.v2f(ltx, sy - stroke_width_0_5)
				gl.v2f(rtx, sy - stroke_width_0_5)
				gl.v2f(rtx, sy + stroke_width_0_5)
				gl.v2f(ltx, sy + stroke_width_0_5)
				gl.end()

				patch_height := lty - (rty + radius_minus_stroke_width_0_5)
				// right border top patch
				gl.begin_quads()
				gl.v2f(rbx, rty)
				gl.v2f(sx + w + stroke_width_0_5, rty)
				gl.v2f(sx + w + stroke_width_0_5, rty + patch_height)
				gl.v2f(rbx, rty + patch_height)
				gl.end()

				// right border rectangle
				gl.begin_quads()
				gl.v2f(sx + w - stroke_width_0_5, rty - radius_minus_stroke_width_0_5)
				gl.v2f(sx + w + stroke_width_0_5, rty - radius_minus_stroke_width_0_5)
				gl.v2f(sx + w + stroke_width_0_5, rby + radius_minus_stroke_width_0_5)
				gl.v2f(sx + w - stroke_width_0_5, rbx + radius_minus_stroke_width_0_5)
				gl.end()

				// right border bottom patch
				gl.begin_quads()
				gl.v2f(rbx, lby + radius_minus_stroke_width_0_5)
				gl.v2f(sx + w + stroke_width_0_5, lby + radius_minus_stroke_width_0_5)
				gl.v2f(sx + w + stroke_width_0_5, rby)
				gl.v2f(rbx, rby)
				gl.end()

				// bottom border rectangle
				gl.begin_quads()
				gl.v2f(lbx, sy + h - stroke_width_0_5)
				gl.v2f(rbx, sy + h - stroke_width_0_5)
				gl.v2f(rbx, sy + h + stroke_width_0_5)
				gl.v2f(lbx, sy + h + stroke_width_0_5)
				gl.end()

				// left border top patch
				gl.begin_quads()
				gl.v2f(ltx - stroke_width_remainder, lty)
				gl.v2f(ltx, lty)
				gl.v2f(ltx, lty + patch_height)
				gl.v2f(ltx - stroke_width_remainder, lty + patch_height)
				gl.end()

				// left border rectangle
				gl.begin_quads()
				gl.v2f(sx - stroke_width_0_5, lty - radius_minus_stroke_width_0_5)
				gl.v2f(sx + stroke_width_0_5, lty - radius_minus_stroke_width_0_5)
				gl.v2f(sx + stroke_width_0_5, lby + radius_minus_stroke_width_0_5)
				gl.v2f(sx - stroke_width_0_5, lby + radius_minus_stroke_width_0_5)
				gl.end()

				// left border bottom patch
				gl.begin_quads()
				gl.v2f(ltx - stroke_width_remainder, lby + radius_minus_stroke_width_0_5)
				gl.v2f(ltx, lby + radius_minus_stroke_width_0_5)
				gl.v2f(ltx, rby)
				gl.v2f(ltx - stroke_width_remainder, rby)
				gl.end()

				analyse.count_and_sum[u64]('${@MOD}.${@STRUCT}.${@FN}@vertices2D', (8 * 4))
			} else {
				// top left arc
				gl.begin_triangle_strip()
				plot_arc_line_thick(ltx, lty, radius_minus_stroke_width_0_5, stroke_width,
					start_radians, end_radians, segments)
				gl.end()

				// top right arc
				gl.begin_triangle_strip()
				plot_arc_line_thick(rtx, rty, radius_minus_stroke_width_0_5, stroke_width,
					start_radians - mth.deg_90_in_rad, end_radians - mth.deg_90_in_rad,
					segments)
				gl.end()

				// bottom right arc
				gl.begin_triangle_strip()
				plot_arc_line_thick(rbx, rby, radius_minus_stroke_width_0_5, stroke_width,
					start_radians - mth.deg_180_in_rad, end_radians - mth.deg_180_in_rad,
					segments)
				gl.end()

				// bottom left arc
				gl.begin_triangle_strip()
				plot_arc_line_thick(lbx, rby, radius_minus_stroke_width_0_5, stroke_width,
					start_radians - mth.deg_270_in_rad, end_radians - mth.deg_270_in_rad,
					segments)
				gl.end()

				// top border rectangle
				gl.begin_quads()
				gl.v2f(ltx, sy - stroke_width_0_5)
				gl.v2f(rtx, sy - stroke_width_0_5)
				gl.v2f(rtx, sy + stroke_width_0_5)
				gl.v2f(ltx, sy + stroke_width_0_5)
				gl.end()

				// right border rectangle
				gl.begin_quads()
				gl.v2f(sx + w - stroke_width_0_5, rty)
				gl.v2f(sx + w + stroke_width_0_5, rty)
				gl.v2f(sx + w + stroke_width_0_5, rby)
				gl.v2f(sx + w - stroke_width_0_5, rbx)
				gl.end()

				// bottom border rectangle
				gl.begin_quads()
				gl.v2f(lbx, sy + h - stroke_width_0_5)
				gl.v2f(rbx, sy + h - stroke_width_0_5)
				gl.v2f(rbx, sy + h + stroke_width_0_5)
				gl.v2f(lbx, sy + h + stroke_width_0_5)
				gl.end()

				// left border rectangle
				gl.begin_quads()
				gl.v2f(sx - stroke_width_0_5, lty)
				gl.v2f(sx + stroke_width_0_5, lty)
				gl.v2f(sx + stroke_width_0_5, lby)
				gl.v2f(sx - stroke_width_0_5, lby)
				gl.end()

				analyse.count_and_sum[u64]('${@MOD}.${@STRUCT}.${@FN}@vertices2D', 4 * 4)
			}
		} else {
			// left top quarter
			gl.begin_line_strip()
			for i in 0 .. segments {
				rad = f32(math.radians(i * 3))
				dx = radius * math.cosf(rad)
				dy = radius * math.sinf(rad)
				gl.v2f(ltx - dx, lty - dy)
			}
			gl.end()

			// right top quarter
			gl.begin_line_strip()
			for i in 0 .. segments {
				rad = f32(math.radians(i * 3))
				dx = radius * math.cosf(rad)
				dy = radius * math.sinf(rad)
				gl.v2f(rtx + dx, rty - dy)
			}
			gl.end()

			// right bottom quarter
			gl.begin_line_strip()
			for i in 0 .. segments {
				rad = f32(math.radians(i * 3))
				dx = radius * math.cosf(rad)
				dy = radius * math.sinf(rad)
				gl.v2f(rbx + dx, rby + dy)
			}
			gl.end()

			// left bottom quarter
			gl.begin_line_strip()
			for i in 0 .. segments {
				rad = f32(math.radians(i * 3))
				dx = radius * math.cosf(rad)
				dy = radius * math.sinf(rad)
				gl.v2f(lbx - dx, lby + dy)
			}
			gl.end()

			gl.begin_lines()
			// top
			gl.v2f(ltx, sy)
			gl.v2f(rtx, sy)
			// right
			gl.v2f(rtx + radius, rty)
			gl.v2f(rtx + radius, rby)
			// bottom
			// Note: test on native windows, macos, and linux if you need to change the offset literal here,
			// with `v run vlib/gg/testdata/draw_rounded_rect_empty.vv` . Using 1 here, looks good on windows,
			// and on linux with LIBGL_ALWAYS_SOFTWARE=true, but misaligned on native macos and linux.
			gl.v2f(lbx, lby + radius - 0.5)
			gl.v2f(rbx, rby + radius - 0.5)
			// left
			gl.v2f(sx, lty)
			gl.v2f(sx, lby)
			gl.end()

			analyse.count_and_sum[u64]('${@MOD}.${@STRUCT}.${@FN}@vertices2D', (4 * (1 * 30)) + 8)
		}
	}
}

@[inline]
fn (r DrawShape2DRect) draw_anchor(x1 f32, y1 f32, x2 f32, y2 f32, x3 f32, y3 f32) {
	draw_anchor_config := DrawAnchorConfig{
		...r.stroke
		width: r.stroke.width * r.factor
	}
	draw_anchor(x1, y1, x2, y2, x3, y3, draw_anchor_config)
}

// DrawShape2DLineSegment

@[params]
pub struct DrawShape2DLineSegment {
	Line
	Stroke
	factor f32 = 1.0
pub mut:
	visible  bool = true
	rotation f32
	scale    f32 = 1.0
	offset   Vec2[f32]
	origin   Anchor = .center_left //
}

@[inline]
pub fn (l DrawShape2DLineSegment) origin_offset() (f32, f32) {
	// p_x, p_y := l.origin.pos_wh(l.a.x - l.b.x, l.a.y - l.b.y)
	// return -p_x, -p_y
	return 0, 0
}

@[inline]
pub fn (l DrawShape2DLineSegment) draw() {
	if !l.visible {
		return
	}
	x1 := l.a.x * l.factor
	y1 := l.a.y * l.factor
	x2 := l.b.x * l.factor
	y2 := l.b.y * l.factor
	stroke_width := l.Stroke.width * l.factor

	color := l.color
	gl.c4b(color.r, color.g, color.b, color.a)

	x1_ := x1
	y1_ := y1
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
		gl.rotate(l.rotation, 0, 0, 1.0)
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
		analyse.count_and_sum[u64]('${@MOD}.${@STRUCT}.${@FN}@vertices2D', 4)
	} else {
		gl.begin_line_strip()
		gl.v2f(x1_, y1_)
		gl.v2f(x2_, y2_)
		gl.end()
		analyse.count_and_sum[u64]('${@MOD}.${@STRUCT}.${@FN}@vertices2D', 2)
	}

	// gl.translate(-f32(x), -f32(y), 0)
	gl.pop_matrix()
	// gl.draw()
}

// DrawShape2DUniformPolygon
@[params]
pub struct DrawShape2DUniformPolygon {
	Circle
	factor f32 = 1.0
pub mut:
	visible  bool = true
	segments u32 // a value of 0 to 2 here will default to 3, use DrawShape2D.radius_to_segments() for automatic calculation
	color    Color
	stroke   Stroke
	rotation f32 // TODO decide if we should leave this here for consistency, segmented drawing allow for a visual difference when setting a rotation
	scale    f32  = 1.0
	fills    Fill = .body | .stroke
	offset   Vec2[f32]
	origin   Anchor = .center
}

@[inline]
pub fn (up &DrawShape2DUniformPolygon) bbox() Rect {
	return up.Circle.bbox().mul_scalar(up.factor)
}

@[inline]
pub fn (up &DrawShape2DUniformPolygon) origin_offset() (f32, f32) {
	bbox := up.bbox()
	p_x, p_y := up.origin.pos_wh(bbox.width, bbox.height)
	return -p_x, -p_y
}

@[inline]
pub fn (up &DrawShape2DUniformPolygon) draw() {
	r := up.bbox()
	// A sane default is to let uniform polygons (e.g. circles)
	// draw from their origin, we compensate for that here
	x := up.x * up.factor + r.width * 0.5
	y := up.y * up.factor + r.height * 0.5
	offset := up.offset.mul_scalar(up.factor)
	radius := up.radius * up.factor
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
	gl.translate(x + offset.x, y + offset.y, 0)

	if up.rotation != 0 {
		gl.translate(-o_off_x, -o_off_y, 0)
		gl.rotate(up.rotation, 0, 0, 1.0)
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
			analyse.count_and_sum[u64]('${@MOD}.${@STRUCT}.${@FN}@vertices2D', 3)
			px = xx + sx
			py = yy + sy
		}
		gl.end()
	}
	if up.fills.has(.stroke) {
		if up.stroke.width * up.factor > 1 {
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
				analyse.count_and_sum[u64]('${@MOD}.${@STRUCT}.${@FN}@vertices2D', 2)

				px = xx + sx
				py = yy + sy
			}
			gl.end()
		}
	}

	gl.translate(-f32(x), -f32(y), 0)
	gl.pop_matrix()
}

@[inline]
fn (up &DrawShape2DUniformPolygon) draw_anchor(x1 f32, y1 f32, x2 f32, y2 f32, x3 f32, y3 f32) {
	draw_anchor_config := DrawAnchorConfig{
		...up.stroke
		width: up.stroke.width * up.factor
	}
	draw_anchor(x1, y1, x2, y2, x3, y3, draw_anchor_config)
}

// Utils

@[params]
struct DrawAnchorConfig {
	width   f32     = 1.0
	connect Connect = .bevel // Beav(el)is and Butt(head) - uuuh - huh huh
	cap     Cap     = .butt
	color   Color   = colors.shy.white
}

@[inline]
fn draw_anchor(x1 f32, y1 f32, x2 f32, y2 f32, x3 f32, y3 f32, config DrawAnchorConfig) {
	// Original author Chris H.F. Tsang / CPOL License
	// https://www.codeproject.com/Articles/226569/Drawing-polylines-by-tessellation
	// http://artgrammer.blogspot.com/search/label/opengl
	color := config.color
	radius := config.width * 0.5
	connect := config.connect
	x1_ := x1
	y1_ := y1
	x2_ := x2
	y2_ := y2
	x3_ := x3
	y3_ := y3

	gl.c4b(color.r, color.g, color.b, color.a)

	if radius == 1 {
		gl.begin_line_strip()
		gl.v2f(x1_, y1_)
		gl.v2f(x2_, y2_)
		analyse.count_and_sum[u64]('${@MOD}.${@FN}@vertices2D', 2)
		gl.end()
		return
	}

	ar := anchor(x1_, y1_, x2_, y2_, x3_, y3_, radius)

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
		analyse.count_and_sum[u64]('${@MOD}.${@FN}@vertices2D', 12)
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

		analyse.count_and_sum[u64]('${@MOD}.${@FN}@vertices2D', 15)
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

// From sgldraw/plot/plot.v
/*
@[inline]
pub fn plot_arc(x f32, y f32, radius f32, start_angle_in_rad f32, angle_in_rad f32, steps u32, fill Fill) {
	theta := f32(angle_in_rad / f32(steps))
	tan_factor := math.tanf(theta)
	rad_factor := math.cosf(theta)
	mut x1 := f32(radius * math.cosf(start_angle_in_rad))
	mut y1 := f32(radius * math.sinf(start_angle_in_rad))
	for i := 0; i < steps + 1; i++ {
		gl.v2f(x1 + x, y1 + y)
		if fill == .body {
			gl.v2f(x, y)
		}
		tx := -y1
		ty := x1
		x1 += tx * tan_factor
		y1 += ty * tan_factor
		x1 *= rad_factor
		y1 *= rad_factor
	}
}

*/

/*
@[inline]
pub fn plot_arc_line(x f32, y f32, radius f32, width f32, start_angle_in_rad f32, angle_in_rad f32, steps u32) {
	mut theta := f32(0)
	for i := 0; i < steps; i++ {
		theta = start_angle_in_rad + angle_in_rad * f32(i) / f32(steps)
		mut x1 := (radius + width) * math.cosf(theta)
		mut y1 := (radius + width) * math.sinf(theta)
		mut x2 := (radius - width) * math.cosf(theta)
		mut y2 := (radius - width) * math.sinf(theta)
		gl.v2f(x + x1, y + y1)
		gl.v2f(x + x2, y + y2)
		theta = start_angle_in_rad + angle_in_rad * f32(i + 1) / f32(steps)
		mut nx1 := (radius + width) * math.cosf(theta)
		mut ny1 := (radius + width) * math.sinf(theta)
		mut nx2 := (radius - width) * math.cosf(theta)
		mut ny2 := (radius - width) * math.sinf(theta)
		gl.v2f(x + nx1, y + ny1)
		gl.v2f(x + nx2, y + ny2)
	}
}
*/

// plot_arc_line_thick plots a filled arc.
// `x`,`y` defines the central point of the arc (center of the circle that the arc is part of).
// `radius` defines the radius of the arc (length from the center point where the arc is drawn).
// `thickness` defines how wide the arc is drawn.
// `start_angle_in_rad` is the angle in radians at which the arc starts.
// `end_angle_in_rad` is the angle in radians at which the arc ends.
// `segments` affects how smooth/round the arc is.
pub fn plot_arc_line_thick(x f32, y f32, radius f32, thickness f32, start_angle_in_rad f32, end_angle_in_rad f32, segments u16) {
	start_angle := start_angle_in_rad
	end_angle := end_angle_in_rad
	outer_radius := radius + thickness
	if outer_radius < 0 {
		return
	}

	nx := x // * scale
	ny := y // * scale
	theta := f32(end_angle - start_angle) / f32(segments)
	tan_factor := math.tanf(theta)
	rad_factor := math.cosf(theta)
	mut ix := math.sinf(start_angle) // * scale
	mut iy := math.cosf(start_angle) // * scale
	mut ox := outer_radius * ix
	mut oy := outer_radius * iy
	ix *= radius
	iy *= radius

	gl.v2f(nx + ix, ny + iy)
	gl.v2f(nx + ox, ny + oy)
	for i := 0; i < segments; i++ {
		ix, iy = ix + iy * tan_factor, iy - ix * tan_factor
		ix *= rad_factor
		iy *= rad_factor
		gl.v2f(nx + ix, ny + iy)
		ox, oy = ox + oy * tan_factor, oy - ox * tan_factor
		ox *= rad_factor
		oy *= rad_factor
		gl.v2f(nx + ox, ny + oy)
	}
	analyse.count_and_sum[u64]('${@MOD}.${@STRUCT}.${@FN}@vertices2D', 2 + (2 * segments))
}

// plot_circle_sector plots the triangle vertices of a solid filled circle slice/pie slice.
// `x`,`y` defines the end point of the slice (center of the circle that the slice is part of).
// `radius` defines the radius ("length") of the slice.
// `start_angle_in_rad` is the angle in radians at which the slice starts.
// `end_angle_in_rad` is the angle in radians at which the slice ends.
// `segments` affects how smooth/round the slice is.
pub fn plot_circle_sector(x f32, y f32, radius f32, start_angle_in_rad f32, end_angle_in_rad f32, segments u16) {
	start_angle := start_angle_in_rad
	end_angle := end_angle_in_rad
	if segments <= 0 || radius < 0 {
		return
	}
	if start_angle == end_angle {
		// plot_slice_empty(x, y, radius, start_angle, end_angle, 1)
		return
	}

	nx := x // * scale
	ny := y // * scale
	theta := f32(end_angle - start_angle) / f32(segments)
	tan_factor := math.tanf(theta)
	rad_factor := math.cosf(theta)
	mut xx := radius * math.sinf(start_angle) // * scale
	mut yy := radius * math.cosf(start_angle) // * scale

	gl.v2f(xx + nx, yy + ny)
	for i := 0; i < segments; i++ {
		xx, yy = xx + yy * tan_factor, yy - xx * tan_factor
		xx *= rad_factor
		yy *= rad_factor
		gl.v2f(xx + nx, yy + ny)
		// if i % 1 == 0 {
		gl.v2f(nx, ny)
		//}
	}
	analyse.count_and_sum[u64]('${@MOD}.${@STRUCT}.${@FN}@vertices2D', 1 + (2 * segments))
}
