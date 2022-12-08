// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module lib

import shy.mth
import shy.utils
import shy.vec { Vec2 }
import shy.wraps.sokol.gl

// DrawImage
pub struct DrawImage {
	ShyFrame
	draw &Draw
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
		width: image.width
		height: image.height
		image: image
		alpha_pipeline: di.draw.alpha_pipeline
	}
	/*
	// TODO return small default image?
	panic('${@STRUCT}.${@FN}: TODO use stand-in Image here instead of panicing (image $uri was not loaded/cached)')
	return Draw2DImage{}
	*/
}

pub struct Draw2DImage {
	Rect
	image          Image
	alpha_pipeline gl.Pipeline
pub mut:
	color    Color = rgb(255, 255, 255)
	origin   Anchor
	rotation f32
	scale    f32 = 1.0
	offset   Vec2[f32]
}

[inline]
pub fn (i Draw2DImage) origin_offset() (f32, f32) {
	p_x, p_y := i.origin.pos_wh(i.width, i.height)
	return -p_x, -p_y
}

[inline]
pub fn (i Draw2DImage) draw() {
	x := i.x
	y := i.y
	w := i.width
	h := i.height

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

	mut o_off_x, mut o_off_y := i.origin_offset()
	// o_off_x = int(o_off_x)
	// o_off_y = int(o_off_y)

	gl.translate(o_off_x, o_off_y, 0)
	gl.translate(x + i.offset.x, y + i.offset.y, 0)

	// println('${o_off_x} x: ${x} w: ${w} h: ${h}')

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

	gl.push_pipeline()
	if i.color.a < 255 {
		gl.load_pipeline(i.alpha_pipeline)
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

	gl.pop_pipeline()

	gl.pop_matrix()
}

[inline]
pub fn (i Draw2DImage) draw_region(src Rect, dst Rect) {
	x := i.x
	y := i.y
	w := i.image.width
	h := i.image.height

	mut u0 := f32(0.0)
	mut v0 := f32(0.0)
	mut u1 := f32(1.0)
	mut v1 := f32(1.0)

	u0 = utils.remap(dst.x, 0, w, 0, 1)
	v0 = utils.remap(dst.y, 0, h, 0, 1)
	u1 = utils.remap(dst.x + dst.width, 0, w, 0, 1)
	v1 = utils.remap(dst.y + dst.height, 0, h, 0, 1)
	// eprintln('dst: ${dst.x},${dst.y},${dst.width},${dst.height} u0: $u0, v0: $v0, u1: $u1, v1: $v1')

	mut x0 := f32(src.x)
	mut y0 := f32(src.y)
	mut x1 := f32(src.width)
	mut y1 := f32(src.height)

	gl.push_matrix()

	gl.enable_texture()
	gl.texture(i.image.gfx_image)

	mut o_off_x, mut o_off_y := i.origin_offset()
	// o_off_x = int(o_off_x)
	// o_off_y = int(o_off_y)

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

	// eprintln('image: ${w}x${h}\nsrc: ${src} dst: ${dst}')
	// TODO division by zero can probably happen here...
	dw := mth.min(dst.width, w) / mth.max(dst.width, w)
	dh := mth.min(dst.height, h) / mth.max(dst.height, h)
	if dw != 1 || dh != 1 {
		gl.translate(-o_off_x, -o_off_y, 0)
		gl.scale(dw, dh, 1)
		gl.translate(o_off_x, o_off_y, 0)
	}

	gl.push_pipeline()
	if i.color.a < 255 {
		gl.load_pipeline(i.alpha_pipeline)
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

	gl.pop_pipeline()

	gl.pop_matrix()
}
