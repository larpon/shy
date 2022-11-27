// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module lib

import shy.mth
import shy.vec { Vec2 }
import shy.wraps.sokol.gl

// DrawImage

pub struct DrawImage {
	ShyFrame
}

pub fn (mut di DrawImage) begin() {
	di.ShyFrame.begin()

	win := di.shy.active_window()
	w, h := win.drawable_wh()

	// unsafe { di.shy.api.draw.layer++ }
	// gl.set_context(gl.default_context)
	// gl.layer(di.shy.api.draw.layer)

	gl.defaults()

	// gl.set_context(s_gl_context)
	gl.matrix_mode_projection()
	gl.ortho(0.0, f32(w), f32(h), 0.0, -1.0, 1.0)
}

pub fn (mut di DrawImage) end() {
	di.ShyFrame.end()

	// gl.draw_layer(di.shy.api.draw.layer)
	// Finish a draw command queue, clearing it.
	// gl.draw()
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
	color    Color = rgb(255, 255, 255)
	origin   Anchor
	rotation f32
	scale    f32 = 1.0
	offset   Vec2[f32]
}

[inline]
pub fn (i Draw2DImage) origin_offset() (f32, f32) {
	p_x, p_y := i.origin.pos_wh(i.w, i.h)
	return -p_x, -p_y
}

[inline]
pub fn (i Draw2DImage) draw() {
	x := i.x
	y := i.y
	w := i.w
	h := i.h

	u0 := f32(0.0)
	v0 := f32(0.0)
	u1 := f32(1.0)
	v1 := f32(1.0)
	x0 := f32(0)
	y0 := f32(0)
	x1 := f32(w)
	y1 := f32(h)

	gl.push_matrix()

	gl.enable_texture()
	gl.texture(i.image.gfx_image)

	o_off_x, o_off_y := i.origin_offset()

	gl.translate(o_off_x, o_off_y, 0)
	gl.translate(x + i.offset.x, y + i.offset.y, 0)

	if i.rotation != 0 {
		gl.translate(-o_off_x, -o_off_y, 0)
		gl.rotate(i.rotation * mth.deg2rad, 0, 0, 1.0)
		gl.translate(o_off_x, o_off_y, 0)
	}
	if i.scale != 1 {
		gl.translate(-o_off_x, -o_off_y, 0)
		gl.scale(i.scale, i.scale, 1)
		gl.translate(o_off_x, o_off_y, 0)
	}

	gl.c4b(i.color.r, i.color.g, i.color.b, i.color.a)
	gl.begin_quads()
	gl.v2f_t2f(x0, y0, u0, v0)
	gl.v2f_t2f(x1, y0, u1, v0)
	gl.v2f_t2f(x1, y1, u1, v1)
	gl.v2f_t2f(x0, y1, u0, v1)
	gl.end()

	gl.translate(-f32(x), -f32(y), 0)
	gl.disable_texture()

	gl.pop_matrix()
}

[inline]
pub fn (i Draw2DImage) draw_region(src Rect, dst Rect) {
	// gp.set_blend_mode(gp.BlendMode)
	// gp.reset_blend_mode()

	panic('${@FN} TODO')
	/*
	col := i.color.as_f32()

	gp.set_color(col.r, col.g, col.b, col.a)
	gp.set_image(0, i.image.gfx_image)

	sgp_src := gp.Rect{
		x: src.x
		y: src.y
		w: src.w
		h: src.h
	}
	sgp_dst := gp.Rect{
		x: dst.x
		y: dst.y
		w: dst.w
		h: dst.h
	}
	gp.draw_textured_rect_ex(0, sgp_dst, sgp_src)

	gp.reset_image(0)
	*/
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
