// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module shy

import shy.vec { Vec2 }
import shy.mth
import sgp
import sokol.sgl // Required for font rendering

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
	// sgp.project(-ratio, ratio, 1.0, -1.0)
	// sgp.project(0, 0, w, h)

	sgp.reset_project()
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
	fc.begin()
}

pub fn (mut dt DrawText) end() {
	dt.ShyFrame.end()
	fc := dt.font_context
	if !isnil(fc) {
		//¤ FLOOD d2d.shy.log.gdebug('${@STRUCT}.${@FN}', 'end   ${ptr_str(fc.fsc)}...')
		fc.end()
		dt.font_context = null
	}
}

pub fn (mut dt DrawText) text_2d() Draw2DText {
	assert !isnil(dt.font_context), 'DrawText.font_context is null'
	return Draw2DText{
		fc: dt.font_context
	}
}

pub struct Draw2DText {
	vec.Vec2<f32>
	fc &FontContext
pub mut:
	text   string
	font   string = defaults.font.name
	colors [color_target_size]Color = [rgb(0, 70, 255), rgb(255, 255, 255)]!
	anchor Anchor
	// TODO clear up this mess
	size   f32  = defaults.font.size
	scale  f32  = 1.0
	fills  Fill = .solid | .outline
	offset vec.Vec2<f32>
}

[inline]
pub fn (t Draw2DText) draw() {
	//¤ FLOOD d2d.shy.log.gdebug('${@STRUCT}.${@FN}', 'using ${ptr_str(fc.fsc)}...')
	fc := t.fc
	font_context := fc.fsc

	assert !isnil(font_context), '${@STRUCT}.${@FN}' + ': no font context'

	// color := sfons.rgba(255, 255, 255, 255)
	if t.font != defaults.font.name {
		font_id := fc.fonts[t.font]
		font_context.set_font(font_id)
	}
	// font_context.set_color(color)
	font_context.set_size(t.size)

	lines := t.text.split('\n')

	mut y_accu := f32(0)
	for line in lines {
		mut off_x := f32(0)
		mut off_y := f32(0)
		if t.anchor != .bottom_left {
			mut buf := [4]f32{}
			font_context.text_bounds(t.x, t.y, line, &buf[0])
			match t.anchor {
				.top_left {
					off_y = buf[3] - buf[1]
				}
				.top_center {
					off_y = buf[3] - buf[1]
					off_x = (buf[0] - buf[2]) / 2
				}
				.top_right {
					off_y = buf[3] - buf[1]
					off_x = (buf[0] - buf[2])
				}
				.center_left {
					off_y = (buf[3] - buf[1]) / 2
				}
				.center {
					off_y = (buf[3] - buf[1]) / 2
					off_x = (buf[0] - buf[2]) / 2
				}
				.center_right {
					off_y = (buf[3] - buf[1]) / 2
					off_x = (buf[0] - buf[2])
				}
				else {
					// TODO
				}
			}
			y_accu += off_y
		}
		x := t.offset.x + t.x + off_x
		y := t.offset.y + t.y + y_accu
		font_context.draw_text(x, y, line)
	}
}

// DrawShape2DRect
[params]
pub struct DrawShape2DRect {
	Rect
pub mut:
	// visible bool = true
	colors [color_target_size]Color = [rgb(255, 5, 5), rgb(255, 255, 255)]!
	// TODO clear up this mess
	radius  f32     = 1.0
	scale   f32     = 1.0
	fills   Fill    = .solid | .outline
	cap     Cap     = .butt
	connect Connect = .bevel
	offset  vec.Vec2<f32>
}

pub fn (mut r DrawShape2DRect) set(config DrawShape2DRect) {
	r.Rect = config.Rect
	r.colors = config.colors
	r.radius = config.radius
	r.scale = config.scale
	r.fills = config.fills
	r.cap = config.cap
	r.connect = config.connect
	r.offset = config.offset
}

pub fn (r DrawShape2DRect) fill_color() Color {
	return r.colors[0]
}

pub fn (r DrawShape2DRect) outline_color() Color {
	return r.colors[1]
}

[inline]
fn (r DrawShape2DRect) draw_anchor(x1 f32, y1 f32, x2 f32, y2 f32, x3 f32, y3 f32) {
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
pub fn (r DrawShape2DRect) draw() {
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

	win := di.shy.api.wm.active_window()
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
	anchor Anchor
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
