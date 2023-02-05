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
	factor f32 = 1.0
	draw   &Draw
}

pub fn (mut di DrawImage) begin() {
	di.ShyFrame.begin()
}

pub fn (mut di DrawImage) end() {
	di.ShyFrame.end()

	// gl.draw_layer(di.shy.api.draw.layer)
	// Finish a draw command queue, clearing it.
	// gl.draw()
}

pub fn (di DrawImage) image_2d(image Image) Draw2DImage {
	return Draw2DImage{
		factor: di.factor
		width: image.width
		height: image.height
		image: image
		draw: di.draw
		// alpha_pipeline: di.draw.alpha_pipeline
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
	// alpha_pipeline gl.Pipeline
	factor f32 = 1.0
mut:
	draw &Draw // For scissor state restoring
pub mut:
	color     Color = rgb(255, 255, 255)
	origin    Anchor
	rotation  f32
	scale     f32 = 1.0
	offset    Vec2[f32]
	fill_mode ImageFillMode
}

[inline]
pub fn (i Draw2DImage) origin_offset() (f32, f32) {
	p_x, p_y := i.origin.pos_wh(i.width * i.factor, i.height * i.factor)
	return -p_x, -p_y
}

[inline]
pub fn (i Draw2DImage) draw() {
	x := i.x * i.factor
	y := i.y * i.factor
	// x := f32(int(i.x * i.factor)) - 0.5
	// y := f32(int(i.y * i.factor)) - 0.5
	w := i.width * i.factor
	h := i.height * i.factor

	u0 := f32(0.0)
	v0 := f32(0.0)
	mut u1 := f32(1.0)
	mut v1 := f32(1.0)
	x0 := f32(0)
	y0 := f32(0)
	mut x1 := f32(w)
	mut y1 := f32(h)
	image := i.image

	mut scissor_rect := Rect{0, 0, -1, -1}
	mut o_off_x, mut o_off_y := i.origin_offset()
	match i.fill_mode {
		.stretch {
			// default mode
		}
		.aspect_fit {
			ratio := mth.min(f32(i.height) / (image.height), f32(i.width) / (image.width))
			x1 = image.width * ratio
			y1 = image.height * ratio
			i_x, i_y := i.origin.pos_wh(w, h)
			x1x, y1y := i.origin.pos_wh(x1, y1)
			o_off_x += i_x - x1x
			o_off_y += i_y - y1y
		}
		.aspect_crop {
			ratio := mth.max(f32(i.height) / (image.height), f32(i.width) / (image.width))
			// u1 = utils.remap[f32](i.width, 0, image.width, 0, 1)i
			// v1 = utils.remap[f32](i.height, 0, image.height, 0, 1)
			x1 = image.width * ratio
			y1 = image.height * ratio

			i_x, i_y := i.origin.pos_wh(w, h)
			x1x, y1y := i.origin.pos_wh(x1, y1)
			o_off_x += i_x - x1x
			o_off_y += i_y - y1y

			scissor_rect = i.draw.scissor_rect
			mut scissor := Rect{
				x: x
				y: y
				width: w
				height: h
			}
			scissor = scissor.displaced_from(i.origin)
			i.draw.scissor(scissor)
		}
		.tile {
			assert image.opt.wrap_u == .repeat, 'Images used for fill_mode: .tile, must be loaded with wrap_u/wrap_v: .repeat'
			assert image.opt.wrap_v == .repeat, 'Images used for fill_mode: .tile, must be loaded with wrap_u/wrap_v: .repeat'
			u1 = utils.remap[f32](i.width, 0, image.width, 0, 1)
			v1 = utils.remap[f32](i.height, 0, image.height, 0, 1)
			x1 = i.width
			y1 = i.height
		}
		.tile_vertically {
			assert image.opt.wrap_u == .clamp_to_edge, 'Images used for fill_mode: .tile_vertically, must be loaded with wrap_u: .clamp_to_edge'
			assert image.opt.wrap_v == .repeat, 'Images used for fill_mode: .tile_vertically, must be loaded with wrap_v: .repeat'
			v1 = utils.remap[f32](i.height, 0, image.height, 0, 1)
			x1 = i.width
			y1 = i.height
		}
		.tile_horizontally {
			assert image.opt.wrap_u == .repeat, 'Images used for fill_mode: .tile_horizontally, must be loaded with wrap_u: .repeat'
			assert image.opt.wrap_v == .clamp_to_edge, 'Images used for fill_mode: .tile_horizontally, must be loaded with wrap_v: .clamp_to_edge'
			u1 = utils.remap[f32](i.width, 0, image.width, 0, 1)
			x1 = i.width
			y1 = i.height
		}
		.pad {
			x1 = i.image.width
			y1 = i.image.height
		}
	}

	gl.push_matrix()
	gl.enable_texture()
	gl.texture(i.image.gfx_image)

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

	// gl.push_pipeline()
	// if i.color.a < 255 {
	//	gl.load_pipeline(i.alpha_pipeline)
	//}
	gl.c4b(i.color.r, i.color.g, i.color.b, i.color.a)
	gl.begin_quads()
	gl.v2f_t2f(x0, y0, u0, v0)
	gl.v2f_t2f(x1, y0, u1, v0)
	gl.v2f_t2f(x1, y1, u1, v1)
	gl.v2f_t2f(x0, y1, u0, v1)
	gl.end()

	gl.translate(-f32(x), -f32(y), 0)
	gl.disable_texture()

	// gl.pop_pipeline()

	gl.pop_matrix()
	if scissor_rect.width >= 0 {
		i.draw.scissor(scissor_rect)
	}
}

[inline]
pub fn (i Draw2DImage) draw_region(src Rect, dst Rect) {
	// x := f32(int(i.x * i.factor))
	// y := f32(int(i.y * i.factor))
	x := i.x * i.factor
	y := i.y * i.factor
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

	mut x0 := f32(src.x) //- 0.5
	mut y0 := f32(src.y) //- 0.5
	mut x1 := f32(src.width) //- 0.5
	mut y1 := f32(src.height) // - 0.5

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

	// gl.push_pipeline()
	// if i.color.a < 255 {
	//	gl.load_pipeline(i.alpha_pipeline)
	//}
	gl.c4b(i.color.r, i.color.g, i.color.b, i.color.a)
	gl.begin_quads()
	gl.v2f_t2f(x0, y0, u0, v0)
	gl.v2f_t2f(x1, y0, u1, v0)
	gl.v2f_t2f(x1, y1, u1, v1)
	gl.v2f_t2f(x0, y1, u0, v1)
	gl.end()

	gl.translate(-f32(x), -f32(y), 0)
	gl.disable_texture()

	// gl.pop_pipeline()

	gl.pop_matrix()
}
