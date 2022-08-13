// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module shy

import shy.vec { Vec2 }
import shy.mth
import sgp
import sokol.sgl // Required for font rendering

pub struct Draw2D {
pub mut:
	render_text_first bool
mut:
	shy        &Shy       = shy.null
	font_context &FontContext = shy.null
}

fn (mut d2d Draw2D) init(shy &Shy) {
	d2d.shy = shy
}

fn (mut d2d Draw2D) shutdown() {
}

pub fn (mut d2d Draw2D) begin() {
	assert d2d.shy.state.in_frame_call, @STRUCT + '.' + @FN +
		' can only be called inside a .frame() call'

	win := d2d.shy.wm.active_window()
	w, h := win.drawable_size()
	// ratio := f32(w)/f32(h)

	// Begin recording draw commands for a frame buffer of size (width, height).
	sgp.begin(w, h)

	// Set frame buffer drawing region to (0,0,width,height).
	sgp.viewport(0, 0, w, h)
	// Set drawing coordinate space to (left=-ratio, right=ratio, top=1, bottom=-1).
	// sgp.project(-ratio, ratio, 1.0, -1.0)
	// sgp.project(0, 0, w, h)

	sgp.reset_project()
}

pub fn (mut d2d Draw2D) end() {
	assert d2d.shy.state.in_frame_call, @STRUCT + '.' + @FN +
		' can only be called inside a .frame() call'

	if !isnil(d2d.font_context) && d2d.render_text_first {
		d2d.end_text()
	}

	// Dispatch all draw commands to Sokol GFX.
	sgp.flush()
	// Finish a draw command queue, clearing it.
	sgp.end()

	if !isnil(d2d.font_context) && !d2d.render_text_first {
		d2d.end_text()
	}
}

fn (mut d2d Draw2D) begin_text() {
	win := d2d.shy.wm.active_window()
	w, h := win.drawable_size()

	sgl.defaults()

	fc := d2d.shy.api.font_system.get_context()
	sgl.set_context(fc.sgl)
	sgl.matrix_mode_projection()
	sgl.ortho(0.0, f32(w), f32(h), 0.0, -1.0, 1.0)

	//¤ FLOOD d2d.shy.log.gdebug(@STRUCT + '.' + 'draw', 'begin ${ptr_str(fc.fsc)}...')
	fc.begin()
	d2d.font_context = fc
}

fn (mut d2d Draw2D) end_text() {
	fc := d2d.font_context
	if !isnil(fc) {
		//¤ FLOOD d2d.shy.log.gdebug(@STRUCT + '.' + 'draw', 'end   ${ptr_str(fc.fsc)}...')
		fc.end()
		d2d.font_context = shy.null
	}
}

pub fn (mut d2d Draw2D) new_text() Draw2DText {
	if isnil(d2d.font_context) {
		d2d.begin_text()
	}
	return Draw2DText{
		fc: d2d.font_context
	}
}

pub fn (d2d &Draw2D) new_rect(config Draw2DRect) Draw2DRect {
	return config
}

pub fn (mut d2d Draw2D) text_at(text string, x int, y int) {
	mut t := d2d.new_text()
	t.x = x
	t.y = y
	t.text = text
	t.draw()
}

// Draw2DText
pub struct Draw2DText {
	Vec2<f32>
	fc &FontContext
pub mut:
	text   string
	font   string = shy.defaults.font.name
	colors [shy.color_target_size]Color = [rgb(0, 70, 255), rgb(255, 255, 255)]!
	// TODO clear up this mess, try using just shapes that can draw themselves instead
	size   f32  = 19.0
	scale  f32  = 1.0
	fills  Fill = .solid | .outline
	offset Vec2<f32>
}

[inline]
pub fn (t Draw2DText) draw() {
	//¤ FLOOD d2d.shy.log.gdebug(@STRUCT + '.' + 'draw', 'using ${ptr_str(fc.fsc)}...')
	fc := t.fc
	font_context := fc.fsc
	if isnil(font_context) {
		assert false, @STRUCT + '.' + @FN + ': no font context'
	}

	// color := sfons.rgba(255, 255, 255, 255)
	if t.font != shy.defaults.font.name {
		font_id := fc.fonts[t.font]
		font_context.set_font(font_id)
	}
	// font_context.set_color(color)
	font_context.set_size(t.size)
	font_context.draw_text(t.x, t.y, t.text)
}

// Draw2DRect
[params]
pub struct Draw2DRect {
	Rect
pub mut:
	// visible bool = true
	colors [shy.color_target_size]Color = [rgb(0, 70, 255), rgb(255, 255, 255)]!
	// TODO clear up this mess
	radius  f32     = 1.0
	scale   f32     = 1.0
	fills   Fill    = .solid | .outline
	cap     Cap     = .butt
	connect Connect = .bevel
	offset  Vec2<f32>
}

pub fn (mut r Draw2DRect) set(config Draw2DRect) {
	r.Rect = config.Rect
	//	r.y = config.Rect.y
	//	r.w = config.Rect.w
	//	r.h = config.Rect.h
	r.colors = config.colors
	r.radius = config.radius
	r.scale = config.scale
	r.fills = config.fills
	r.cap = config.cap
	r.connect = config.connect
	r.offset = config.offset
}

pub fn (r Draw2DRect) fill_color() Color {
	return r.colors[0]
}

pub fn (r Draw2DRect) outline_color() Color {
	return r.colors[1]
}

[inline]
fn (r Draw2DRect) draw_anchor(x1 f32, y1 f32, x2 f32, y2 f32, x3 f32, y3 f32) {
	// Original author Chris H.F. Tsang / CPOL License
	// https://www.codeproject.com/Articles/226569/Drawing-polylines-by-tessellation
	// http://artgrammer.blogspot.com/search/label/opengl

	//!c := r.colors.outline
	//!sgl.c4b(c.r, c.g, c.b, c.a)
	color := r.outline_color()
	if color.a < 255 {
		sgp.set_blend_mode(.blend)
	}
	c := color.as_f32()
	sgp.set_color(c.r, c.g, c.b, c.a)

	radius := r.radius
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

	if r.connect == .miter {
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
	} else if r.connect == .bevel {
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

[inline]
pub fn (r Draw2DRect) draw() {
	x := r.x
	y := r.y
	w := r.w
	h := r.h
	sx := x //* scale_factor
	sy := y //* scale_factor
	if r.fills.has(.solid) {
		color := r.fill_color()
		if color.a < 255 {
			sgp.set_blend_mode(.blend)
		}
		c := color.as_f32()

		sgp.set_color(c.r, c.g, c.b, c.a)
		sgp.draw_filled_rect(x, y, w, h)
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
			color := r.outline_color()
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

	sgp.flush()
}
