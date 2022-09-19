// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module shy

import shy.vec { Vec2 }
import shy.mth
import sgp
// Required for font rendering
import sokol.sgl
import sokol.sfons

// DrawText
pub struct DrawText {
	ShyFrame
mut:
	font_context &FontContext = null
}

pub fn (mut dt DrawText) begin() {
	dt.ShyFrame.begin()
	win := dt.shy.active_window()
	w, h := win.drawable_size()

	sgl.defaults()

	mut fonts := unsafe { win.fonts }
	fc := fonts.get_context()
	sgl.set_context(fc.sgl)

	sgl.matrix_mode_projection()
	sgl.ortho(0.0, f32(w), f32(h), 0.0, -1.0, 1.0)

	//¤ FLOOD dt.shy.log.gdebug('${@STRUCT}.${@FN}', 'begin ${ptr_str(fc.fsc)}...')
	dt.font_context = fc
	assert !isnil(fc), 'FontContext is null'
	fc.begin()
}

pub fn (mut dt DrawText) end() {
	dt.ShyFrame.end()
	fc := dt.font_context
	assert !isnil(fc), 'FontContext is null'
	if !isnil(fc) {
		//¤ FLOOD d2d.shy.log.gdebug('${@STRUCT}.${@FN}', 'end   ${ptr_str(fc.fsc)}...')
		fc.end()
		dt.font_context = null
	}
	sgl.draw()
}

pub fn (mut dt DrawText) text_2d() Draw2DText {
	assert !isnil(dt.font_context), 'DrawText.font_context is null'
	return Draw2DText{
		fc: dt.font_context
	}
}

// pub type TextAlign = fontstash.Align

[flag]
pub enum TextAlign {
	// Horizontal align
	left // Default
	center
	right
	// Vertical align
	top
	middle
	bottom
	baseline // Default
}

pub fn (ta TextAlign) str_clean() string {
	return ta.str().all_after('{').all_before('}').trim_space()
}

pub fn (ta TextAlign) next() TextAlign {
	if ta.has(.top) {
		if ta.has(.left) {
			return .top | .center
		} else if ta.has(.center) {
			return .top | .right
		} else {
			return .middle | .left
		}
	} else if ta.has(.middle) {
		if ta.has(.left) {
			return .middle | .center
		} else if ta.has(.center) {
			return .middle | .right
		} else {
			return .baseline | .left
		}
	} else if ta.has(.baseline) {
		if ta.has(.left) {
			return .baseline | .center
		} else if ta.has(.center) {
			return .baseline | .right
		} else {
			return .bottom | .left
		}
	} else if ta.has(.bottom) {
		if ta.has(.left) {
			return .bottom | .center
		} else if ta.has(.center) {
			return .bottom | .right
		} else {
			return .top | .left
		}
	}
	return .top | .left
}

pub struct Draw2DText {
	vec.Vec2<f32>
	fc &FontContext
mut:
	cur_align TextAlign = .baseline | .left // According to fontstash source code
pub mut:
	text     string
	rotation f32
	font     string = defaults.font.name
	color    Color  = colors.shy.white
	origin   Anchor
	align    TextAlign = .baseline | .left // TODO V BUG shy.defaults.font.align
	size     f32       = defaults.font.size
	scale    f32       = 1.0
	fills    Fill      = .solid | .outline
	offset   vec.Vec2<f32>
}

[inline]
pub fn (t Draw2DText) draw() {
	// http://www.freetype.org/freetype2/docs/tutorial/metrics.png

	//¤ FLOOD d2d.shy.log.gdebug('${@STRUCT}.${@FN}', 'using ${ptr_str(fc.fsc)}...')
	fc := t.fc
	font_context := fc.fsc

	assert !isnil(font_context), '${@STRUCT}.${@FN}' + ': no font context'

	/*
	font_context.set_alignment(.left | .baseline)
	font_context.set_spacing(5.0)
	font_context.set_blur(6.0)
	*/

	if t.font != defaults.font.name {
		font_id := fc.fonts[t.font]
		font_context.set_font(font_id)
	}
	// color := sfons.rgba(255, 255, 255, 255)
	color := sfons.rgba(t.color.r, t.color.g, t.color.b, t.color.a)
	font_context.set_color(color)
	font_context.set_size(t.size)

	lines := t.text.split('\n')

	fm := t.metrics()
	line_height := fm.line_height

	mut max_w := f32(0)
	mut max_h := f32(0)
	if lines.len > 0 {
		mut p_r := Rect{}
		for line in lines {
			r := t.bounds(line)
			if r.w > max_w {
				max_w = r.w
			}
			max_h += line_height - 2 // 1 // lines.len
			// max_h += line_height - (line_height - r.h) - 1
			p_r = r
		}
		if lines.len == 1 {
			max_w = p_r.w
			max_h = p_r.h
		}
	}

	mut y_accu := f32(0)
	mut prev_line_height := f32(0)
	for i, line in lines {
		mut off_x := f32(0)
		mut off_y := f32(0)
		// if t.origin != .bottom_left {

		/*
		mut align := TextAlign.baseline
		if t.align.has(.right) {
			align.set(.right)
		} else if t.align.has(.center) {
			align.set(.center)
		} else {
			align.set(.left)
		}
		t.set_font_render_alignment(align)
		*/
		align := t.align
		t.set_font_render_alignment(align)
		r := t.bounds(line)

		// ymin, ymax := t.line_bounds(0)
		// base_lh := '' // t.baseline_height(line)
		// println('Origin: $t.origin $r.x,$r.y w$r.w h$r.h\nyMin $ymin,yMax $ymax\nMetrics: $fm\nBaseline height: $base_lh\nLine height: $line_height\nText: $line\nAlign: $t.align\n$max_w x $max_h ')

		// Tweak for which corner of the text we're drawing.
		// per default, fontstash has chosen to let the drawing start from left at the font's baseline
		// We compensate for that here:

		off_compensate_y := -(r.y + r.h) + r.h
		off_y = off_compensate_y

		align_off_x := if align.has(.center) {
			(max_w / 2)
		} else if align.has(.right) {
			max_w
		} else {
			0
		}
		off_x += align_off_x
		match t.origin {
			.top_left {}
			.top_center {
				off_x += -(max_w / 2)
			}
			.top_right {
				off_x += -max_w
			}
			.center_left {
				off_y += -(max_h / 2)
			}
			.center {
				off_x += -(max_w / 2)
				off_y += -(max_h / 2)
			}
			.center_right {
				off_x += -max_w
				off_y += -(max_h / 2)
			}
			.bottom_left {
				off_y += -max_h
			}
			.bottom_center {
				off_x += -(max_w / 2)
				off_y += -max_h
			}
			.bottom_right {
				off_x += -max_w
				off_y += -max_h
			}
		}
		y_accu += prev_line_height
		prev_line_height = line_height - 2 // lines.len

		// Rounding x and y off (f32(int(...))) is important to prevent the rendering being smeared
		x := f32(int(t.x + t.offset.x + off_x))
		y := f32(int(t.y + t.offset.y + off_y + y_accu))

		sgl.push_matrix()
		sgl.translate(x, y, 0)

		if t.rotation != 0 {
			sgl.rotate(t.rotation * mth.deg2rad, 0, 0, 1)
		}
		if t.scale != 1 {
			sgl.scale(t.scale, t.scale, 0)
		}
		font_context.draw_text(0, 0, line)

		t.dbg_draw_rect(r)

		$if shy_debug_draw ? {
			if i == 0 {
				t.dbg_draw_rect(Rect{
					x: r.x - align_off_x / 2
					y: r.y
					w: max_w
					h: max_h
				})
			}
		}

		sgl.translate(-x, -y, 0)
		sgl.pop_matrix()
	}
}

[inline; if shy_debug_draw ?]
fn (t Draw2DText) dbg_draw_line(x1 f32, y1 f32, x2 f32, y2 f32) {
	sgl.begin_line_strip()
	sgl.v2f(x1, y1)
	sgl.v2f(x2, y2)
	sgl.end()
}

[inline; if shy_debug_draw ?]
fn (t Draw2DText) dbg_draw_rect(r Rect) {
	sgl.begin_line_strip()
	sgl.v2f(r.x, r.y)
	sgl.v2f(r.x + r.w, r.y)
	sgl.v2f(r.x + r.w, r.y)
	sgl.v2f(r.x + r.w, r.y + r.h)
	sgl.v2f(r.x + r.w, r.y + r.h)
	sgl.v2f(r.x, r.y + r.h)
	sgl.v2f(r.x, r.y)
	sgl.end()
}

[inline]
pub fn (t Draw2DText) set_font_render_alignment(align TextAlign) {
	unsafe {
		t.cur_align = align
		t.fc.fsc.set_align(int(align))
	}
}

[inline]
pub fn (t Draw2DText) baseline_height(s string) f32 {
	prev_align := t.cur_align
	t.set_font_render_alignment(.left | .top)
	bounds_tl := t.bounds(s)
	t.set_font_render_alignment(.left | .baseline)
	bounds_de := t.bounds(s)
	t.set_font_render_alignment(prev_align)
	// println('btl: $bounds_base\nbbase: $bounds_base')
	return bounds_tl.y - bounds_de.y
}

[inline]
pub fn (t Draw2DText) bounds(s string) Rect {
	mut buf := [4]f32{}
	t.fc.fsc.text_bounds(0, 0, s, &buf[0])
	return Rect{
		x: buf[0]
		y: buf[1]
		w: buf[2] - buf[0]
		h: buf[3] - buf[1]
	}
}

[inline]
pub fn (t Draw2DText) line_bounds(y f32) (f32, f32) {
	mut min_y, mut max_y := f32(0), f32(0)
	t.fc.fsc.line_bounds(y, &min_y, &max_y)
	return min_y, max_y
}

pub struct FontMetrics {
pub:
	ascender    f32
	descender   f32
	line_height f32
}

[inline]
pub fn (t Draw2DText) metrics() FontMetrics {
	mut asc, mut desc, line_h := f32(0), f32(0), f32(0)
	t.fc.fsc.vert_metrics(&asc, &desc, &line_h)
	return FontMetrics{
		ascender: asc
		descender: desc
		line_height: line_h
	}
}

[inline]
fn (t Draw2DText) anchor_to_alignment(a Anchor) TextAlign {
	return match a {
		.top_left {
			.left | .top
		}
		.top_center {
			.top | .center
		}
		.top_right {
			.top | .right
		}
		.center_left {
			.middle | .left
		}
		.center {
			.middle | .center
		}
		.center_right {
			.middle | .right
		}
		.bottom_left {
			.bottom | .left
		}
		.bottom_center {
			.bottom | .center
		}
		.bottom_right {
			.bottom | .right
		}
	}
}

// DrawShape2D
pub struct DrawShape2D {
	ShyFrame
}

pub fn (mut d2d DrawShape2D) begin() {
	d2d.ShyFrame.begin()

	win := d2d.shy.api.wm.active_window()
	w, h := win.drawable_size()
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

// DrawShape2DRect
[params]
pub struct DrawShape2DRect {
	Rect
pub mut:
	visible  bool = true
	colors   ShapeColors
	radius   f32 = 1.0
	rotation f32
	scale    f32     = 1.0
	fills    Fill    = .solid | .outline
	cap      Cap     = .butt
	connect  Connect = .bevel
	offset   vec.Vec2<f32>
	origin   Anchor
}

/*
pub fn (mut r DrawShape2DRect) set(config DrawShape2DRect) {
	r.Rect = config.Rect
	r.color = config.color
	r.radius = config.radius
	r.scale = config.scale
	r.fills = config.fills
	r.cap = config.cap
	r.connect = config.connect
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
	sgp.translate(x + r.offset.x, y + r.offset.y + r.offset.y)

	if r.rotation != 0 {
		sgp.rotate_at(r.rotation * mth.deg2rad, -o_off_x, -o_off_y)
	}
	if r.scale != 1 {
		sgp.scale_at(r.scale, r.scale, -o_off_x, -o_off_y)
	}

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

	sgp.translate(-x, -y)
	sgp.pop_transform()

	sgp.flush()
}

[inline]
fn (r DrawShape2DRect) draw_anchor(x1 f32, y1 f32, x2 f32, y2 f32, x3 f32, y3 f32) {
	// Original author Chris H.F. Tsang / CPOL License
	// https://www.codeproject.com/Articles/226569/Drawing-polylines-by-tessellation
	// http://artgrammer.blogspot.com/search/label/opengl

	//!c := r.colors.outline
	//!sgl.c4b(c.r, c.g, c.b, c.a)
	color := r.colors.outline
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

// DrawShape2DLine

pub fn (d2d &DrawShape2D) line(config DrawShape2DLine) DrawShape2DLine {
	return config
}

[params]
pub struct DrawShape2DLine {
	LineSegment
pub mut:
	visible  bool = true
	color    Color
	radius   f32 = 1.0
	rotation f32
	scale    f32 = 1.0
	// fills    Fill    = .solid | .outline
	cap Cap = .butt
	// connect  Connect = .bevel
	offset vec.Vec2<f32>
	origin Anchor = .center_left //
}

[inline]
pub fn (l DrawShape2DLine) origin_offset() (f32, f32) {
	// p_x, p_y := l.origin.pos_wh(l.a.x - l.b.x, l.a.y - l.b.y)
	// return -p_x, -p_y
	return 0, 0
}

[inline]
pub fn (l DrawShape2DLine) draw() {
	if !l.visible {
		return
	}
	x1 := l.a.x
	y1 := l.a.y
	x2 := l.b.x
	y2 := l.b.y
	scale_factor := l.scale //* sgldraw.dpi_scale()

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
		sgp.rotate_at(l.rotation * mth.deg2rad, -o_off_x, -o_off_y)
	}
	if l.scale != 1 {
		sgp.scale_at(l.scale, l.scale, -o_off_x, -o_off_y)
	}

	if l.radius > 1 {
		radius := l.radius

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

// DrawImage

pub struct DrawImage {
	ShyFrame
}

pub fn (mut di DrawImage) begin() {
	di.ShyFrame.begin()

	/*
	win := di.shy.active_window()
	w, h := win.drawable_size()

	sgl.defaults()

	// sgl.set_context(fc.sgl)
	sgl.matrix_mode_projection()
	sgl.ortho(0.0, f32(w), f32(h), 0.0, -1.0, 1.0)
	*/

	win := di.shy.active_window()
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

pub fn (mut di DrawImage) end() {
	di.ShyFrame.end()

	/*
	// Finish a draw command queue, clearing it.
	sgl.draw()
	*/

	// Dispatch all draw commands to Sokol GFX.
	sgp.flush()
	// Finish a draw command queue, clearing it.
	sgp.end()
}

pub fn (di DrawImage) image_2d(image Image) Draw2DImage {
	return Draw2DImage{
		w: image.width
		h: image.height
		image: image
	}
	/*
	// TODO return small default image?
	panic('${@STRUCT}.${@FN}: TODO use stand-in Image here instead of panicing (image $uri was not loaded/cached)')
	return Draw2DImage{}
	*/
}

pub struct Draw2DImage {
	Rect
	image Image
pub mut:
	color  Color = rgb(255, 255, 255)
	origin Anchor
	// TODO clear up this mess
	scale  f32 = 1.0
	offset vec.Vec2<f32>
}

[inline]
pub fn (i Draw2DImage) draw() {
	// sgp.set_blend_mode(sgp.BlendMode)
	// sgp.reset_blend_mode()

	col := i.color.as_f32()

	sgp.set_color(col.r, col.g, col.b, col.a)
	sgp.set_image(0, i.image.gfx_image)

	/*
	dst := sgp.Rect{
		x: i.x
		y: i.y
		w: i.w
		h: i.h
	}
	src := sgp.Rect{
		x: 0
		y: 0
		w: 512/2
		h: 512/2
	}
    sgp.draw_textured_rect_ex(0, dst, src)
	*/

	sgp.draw_textured_rect(i.x, i.y, i.w, i.h)
	sgp.reset_image(0)
}

/*
[inline]
pub fn (i Draw2DImage) draw() {
	u0 := f32(0.0)
	v0 := f32(0.0)
	u1 := f32(1.0)
	v1 := f32(1.0)
	x0 := f32(0)
	y0 := f32(0)
	x1 := f32(i.w)
	y1 := f32(i.h)

	sgl.push_matrix()

	sgl.enable_texture()
	sgl.texture(i.image.gfx_image)
	sgl.translate(f32(i.x), f32(i.y), 0)
	sgl.c4b(i.color.r, i.color.g, i.color.b, i.color.a)

	sgl.begin_quads()
	sgl.v2f_t2f(x0, y0, u0, v0)
	sgl.v2f_t2f(x1, y0, u1, v0)
	sgl.v2f_t2f(x1, y1, u1, v1)
	sgl.v2f_t2f(x0, y1, u0, v1)
	sgl.end()

	sgl.translate(-f32(i.x), -f32(i.y), 0)
	sgl.disable_texture()

	sgl.pop_matrix()
}
*/
