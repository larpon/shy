// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module lib

import shy.mth
import shy.vec { Vec2 }
import shy.wraps.sokol.gp

// DrawImage

pub struct DrawImage {
	ShyFrame
}

pub fn (mut di DrawImage) begin() {
	di.ShyFrame.begin()

	/*
	win := di.shy.active_window()
	w, h := win.drawable_wh()

	gl.defaults()

	// gl.set_context(fc.sgl)
	gl.matrix_mode_projection()
	gl.ortho(0.0, f32(w), f32(h), 0.0, -1.0, 1.0)
	*/

	win := di.shy.active_window()
	w, h := win.drawable_wh()
	// ratio := f32(w)/f32(h)

	// Begin recording draw commands for a frame buffer of size (width, height).
	gp.begin(w, h)

	// Set frame buffer drawing region to (0,0,width,height).
	gp.viewport(0, 0, w, h)
	// Set drawing coordinate space to (left=-ratio, right=ratio, top=1, bottom=-1).
	// gp.project(-ratio, ratio, 1.0, -1.0)
	// gp.project(0, 0, w, h)

	gp.reset_project()
}

pub fn (mut di DrawImage) end() {
	di.ShyFrame.end()

	/*
	// Finish a draw command queue, clearing it.
	sgl.draw()
	*/

	// Dispatch all draw commands to Sokol GFX.
	gp.flush()
	// Finish a draw command queue, clearing it.
	gp.end()
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
	offset   Vec2<f32>
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

	// gp.set_blend_mode(gp.BlendMode)
	// gp.reset_blend_mode()

	col := i.color.as_f32()

	gp.set_color(col.r, col.g, col.b, col.a)
	gp.set_image(0, i.image.gfx_image)

	gp.push_transform()
	o_off_x, o_off_y := i.origin_offset()

	gp.translate(o_off_x, o_off_y)
	gp.translate(x + i.offset.x, y + i.offset.y)

	if i.rotation != 0 {
		gp.rotate_at(i.rotation * mth.deg2rad, -o_off_x, -o_off_y)
	}
	if i.scale != 1 {
		gp.scale_at(i.scale, i.scale, -o_off_x, -o_off_y)
	}

	gp.draw_textured_rect(0, 0, w, h)

	gp.translate(-x, -y)
	gp.pop_transform()

	gp.reset_image(0)
}

[inline]
pub fn (i Draw2DImage) draw_region(src Rect, dst Rect) {
	// gp.set_blend_mode(gp.BlendMode)
	// gp.reset_blend_mode()

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
