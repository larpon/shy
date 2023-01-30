// Copyright(C) 2020 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license file distributed with this software package

module particle

import shy.lib as shy
// import rand
import shy.wraps.sokol.gl
import shy.utils

type Painter = CustomPainter | RectPainter //| ImagePainter

pub struct CustomPainter {
mut:
	groups []string
	//	draw		fn(mut cp CustomPainter, mut p Particle)
	//	user_data	voidptr
}

pub struct RectPainter {
mut:
	groups          []string
	color           shy.Color = shy.Color{255, 255, 255, 255}
	color_variation shy.ColorVariation
}

fn (mut rp RectPainter) init(mut p Particle) {
	p.color.r = rp.color.r
	p.color.g = rp.color.g
	p.color.b = rp.color.b
	p.color.a = rp.color.a

	rp.color_variation.max(1.0)
	p.color.variate(rp.color_variation)
	p.init.color = p.color
}

fn (rp RectPainter) draw(mut p Particle, frame_dt f64) {
	fast := p.rotation == 0 && p.scale == 1

	mut color := p.color
	color.a = u8(p.init.color.a * utils.remap(p.life_time, p.init.life_time, p.end.life_time,
		1, 0))
	// color.a = u8(utils.remap(p.life_time, p.init.life_time, p.end.life_time, 255, 0))

	// if color.eq(default_color) {
	//	println('${p.life_time}/${p.init.life_time}')
	//}

	l := p.position
	if fast {
		lx := f32(l.x) - f32(p.size.x) * 0.5
		ly := f32(l.y) - f32(p.size.y) * 0.5
		width := f32(p.size.x)
		height := f32(p.size.y)

		gl.c4b(color.r, color.g, color.b, color.a)
		gl.begin_quads()

		gl.v2f(lx, ly)
		gl.v2f(lx + width, ly)
		gl.v2f(lx + width, ly + height)
		gl.v2f(lx, ly + height)

		gl.end()
	} else {
		gl.push_matrix()

		// gl.translate(0, 0, 0)
		gl.translate(f32(l.x), f32(l.y), 0)
		gl.translate(-f32(p.size.x) * 0.5, -f32(p.size.y) * 0.5, 0)

		gl.translate(f32(p.size.x) * 0.5, f32(p.size.y) * 0.5, 0)
		gl.rotate(gl.rad(p.rotation), 0, 0, 1)
		gl.translate(-f32(p.size.x) * 0.5, -f32(p.size.y) * 0.5, 0)

		gl.translate(f32(p.size.x) * 0.5, f32(p.size.y) * 0.5, 0)
		gl.scale(p.scale, p.scale, 1)
		gl.translate(-f32(p.size.x) * 0.5, -f32(p.size.y) * 0.5, 0)

		gl.c4b(p.color.r, p.color.g, p.color.b, p.color.a)
		gl.begin_quads()

		gl.v2f(0, 0)
		gl.v2f(0 + f32(p.size.x), 0)
		gl.v2f(0 + f32(p.size.x), 0 + f32(p.size.y))
		gl.v2f(0, 0 + f32(p.size.y))

		gl.end()

		// gl.translate(f32(l.x), f32(l.y), 0)
		// gl.rotate(float angle_rad, float x, float y, float z)
		// gl.scale(float x, float y, float z)

		gl.pop_matrix()
	}
}

/*
pub struct ImagePainter {
mut:
	groups []string

	color           shy.Color
	color_variation shy.ColorVariation

	path   string
	mipmap bool = true

	image Image
}

fn (mut ip ImagePainter) init(mut p Particle) {
	p.color.r = ip.color.r
	p.color.g = ip.color.g
	p.color.b = ip.color.b
	p.color.a = ip.color.a

	ip.color_variation.max(1.0)
	p.color.variate(ip.color_variation)
	p.init.color = p.color
}

fn (mut ip ImagePainter) draw(mut p Particle, frame_dt f64) {
	if !ip.image.ready {
		eprintln('Loading image "${ip.path}" on demand')
		num_mipmap := if ip.mipmap { 4 } else { 0 } // TODO find good trade-off value
		ip.image = p.system.load_image(
			path: ip.path
			mipmaps: num_mipmap
			cache: true
		) or { panic(err) }
	}

	mut color := p.color
	color.a = u8(p.init.color.a * utils.remap(p.life_time, p.init.life_time, p.end.life_time, 1, 0))

	u0 := f32(0.0)
	v0 := f32(0.0)
	u1 := f32(1.0)
	v1 := f32(1.0)
	x0 := f32(0)
	y0 := f32(0)
	x1 := f32(p.size.x)
	y1 := f32(p.size.y)

	pre_tx := f32(p.size.x)
	pre_ty := f32(p.size.y)
	pre_tz := 0 // f32(p.position.z)

	// println(pre_ty)

	gl.push_matrix()

	gl.enable_texture()
	gl.texture(ip.image.sg_image)

	gl.translate(f32(p.position.x), f32(p.position.y), pre_tz)
	gl.translate(-pre_tx * 0.5, -pre_ty * 0.5, pre_tz)

	if p.rotation != 0.0 {
		gl.translate(pre_tx * 0.5, pre_ty * 0.5, pre_tz)
		gl.rotate(gl.rad(p.rotation), 0, 0, 1)
		gl.translate(-pre_tx * 0.5, -pre_ty * 0.5, pre_tz)
	}

	if p.scale != 1.0 {
		gl.translate(pre_tx * 0.5, pre_ty * 0.5, pre_tz)
		gl.scale(p.scale, p.scale, 1)
		gl.translate(-pre_tx * 0.5, -pre_ty * 0.5, pre_tz)
	}

	gl.c4b(p.color.r, p.color.g, p.color.b, p.color.a)

	gl.begin_quads()
	gl.v2f_t2f(x0, y0, u0, v0)
	gl.v2f_t2f(x1, y0, u1, v0)
	gl.v2f_t2f(x1, y1, u1, v1)
	gl.v2f_t2f(x0, y1, u0, v1)
	gl.end()
	gl.disable_texture()
	gl.pop_matrix()
}
*/
