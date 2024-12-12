// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module lib

import shy.utils
import shy.mth
import rand
import math // TODO: should use internal

pub const colors = BaseColors{}

pub struct ColorHSV {
pub mut:
	h u16 // 0 - 360 // degrees
	s f32 // 0.0 - 1.0
	v f32 // 0.0 - 1.0
	a f32
}

pub struct Colorf32 {
pub mut:
	r f32
	g f32
	b f32
	a f32
}

pub fn (c &Colorf32) is_opaque() bool {
	return c.a == 1.0
}

pub struct ColorVariation {
pub mut:
	r f32
	g f32
	b f32
	a f32
}

pub fn (mut cv ColorVariation) set_all(value f32) {
	cv.r = value
	cv.g = value
	cv.b = value
	cv.a = value
}

pub fn (mut cv ColorVariation) set(r f32, g f32, b f32, a f32) {
	cv.r = r
	cv.g = g
	cv.b = b
	cv.a = a
}

pub fn (mut cv ColorVariation) max(max f32) {
	cv.r = f32(mth.min(max, cv.r))
	cv.g = f32(mth.min(max, cv.g))
	cv.b = f32(mth.min(max, cv.b))
	cv.a = f32(mth.min(max, cv.a))
}

pub fn (cv ColorVariation) has_variation() bool {
	return cv.r + cv.g + cv.b + cv.a != 0.0
}

// ShyColors holds the official project colors,
// NOTE: changing these will affect examples and visual tests
pub struct ShyColors {
pub:
	red    Color = rgb(185, 25, 25) // Same red as used in the shy logo #b91919
	green  Color = rgb(55, 150, 55) // #379637
	blue   Color = rgb(15, 75, 215) // #0f4bd7
	yellow Color = rgb(210, 200, 15) // #d2c80f
	white  Color = rgb(255, 255, 255) // Same white as used in the logo
	black  Color = rgb(0, 0, 0) // Back in black
}

pub struct BaseColors {
pub:
	red    Color = rgb(255, 0, 0)
	green  Color = rgb(0, 255, 0)
	blue   Color = rgb(0, 0, 255)
	yellow Color = rgb(255, 255, 0)
	white  Color = rgb(255, 255, 255)
	black  Color = rgb(0, 0, 0) // Back in black
	shy    ShyColors
}

pub struct Color {
pub mut:
	r u8
	g u8
	b u8
	a u8
}

pub fn (c &Color) is_transparent() bool {
	return c.a < 255
}

pub fn (c &Color) is_opaque() bool {
	return c.a == 255
}

pub fn (c &Color) copy_set_r(value u8) Color {
	return Color{
		...c
		r: value
	}
}

pub fn (c &Color) copy_set_g(value u8) Color {
	return Color{
		...c
		g: value
	}
}

pub fn (c &Color) copy_set_b(value u8) Color {
	return Color{
		...c
		b: value
	}
}

pub fn (c &Color) copy_set_a(value u8) Color {
	return Color{
		...c
		a: value
	}
}

pub fn (c &Color) darker() Color {
	return c.blend_with(Color{0, 0, 0, 255}, 0.1)
}

pub fn (c &Color) lighter() Color {
	return c.blend_with(Color{255, 255, 255, 255}, 0.1)
}

pub fn (c &Color) darker_by(amount f32) Color {
	return c.blend_with(Color{0, 0, 0, 255}, amount)
}

pub fn (c &Color) lighter_by(amount f32) Color {
	return c.blend_with(Color{255, 255, 255, 255}, amount)
}

pub fn (c &Color) blend_with(color Color, blend f32) Color {
	return Color{
		r: u8(color.r * blend + c.r * (1 - blend))
		g: u8(color.g * blend + c.g * (1 - blend))
		b: u8(color.b * blend + c.b * (1 - blend))
		a: c.a // color.a * (1 - blend) + c.a * blend
	}
}

pub fn (c &Color) as_f32() Colorf32 {
	return Colorf32{
		r: f32(c.r) / 255.0 // utils.remap_u8_to_f32(c.r, 0, 255, 0.0, 1.0)
		g: f32(c.g) / 255.0 // utils.remap_u8_to_f32(c.g, 0, 255, 0.0, 1.0)
		b: f32(c.b) / 255.0 // utils.remap_u8_to_f32(c.b, 0, 255, 0.0, 1.0)
		a: f32(c.a) / 255.0 // utils.remap_u8_to_f32(c.a, 0, 255, 0.0, 1.0)
	}
}

pub fn (c &Color) as_hsv() ColorHSV {
	// R, G, B values are divided by 255
	// to change the range from 0..255 to 0..1
	r := f64(c.r) / 255.0
	g := f64(c.g) / 255.0
	b := f64(c.b) / 255.0
	a := f32(c.a) / 255.0

	// h, s, v = hue, saturation, value
	cmax := mth.max(r, mth.max(g, b)) // maximum of r, g, b
	cmin := mth.min(r, mth.min(g, b)) // minimum of r, g, b
	diff := cmax - cmin // diff of cmax and cmin.
	mut h := f64(-1)
	mut s := f64(-1)
	mut v := cmax

	// if cmax and cmax are equal then h = 0
	if cmax == cmin {
		h = 0
	}
	// if cmax equal r then compute h
	else if cmax == r {
		h = math.fmod(60 * ((g - b) / diff) + 360, 360)
	}
	// if cmax equal g then compute h
	else if cmax == g {
		h = math.fmod(60 * ((b - r) / diff) + 120, 360)
	}
	// if cmax equal b then compute h
	else if cmax == b {
		h = math.fmod(60 * ((r - g) / diff) + 240, 360)
	}

	// if cmax equal zero
	if cmax == 0 {
		s = 0
	} else {
		// s = (diff / cmax) // * 100
		s = (diff / cmax)
	}

	// compute v
	v = cmax // * 100

	// println('HSV: ${h},${s},${v}')

	return ColorHSV{
		h: u16(h)
		// s: u16(mth.clamp(utils.remap(s,0,1,0,255),0,255)) // remaps to 0 - 255
		// v: u16(mth.clamp(utils.remap(v,0,1,0,255),0,255)) // remaps to 0 - 255
		s: f32(s)
		v: f32(v)
		a: a
	}
}

pub fn (c &Color) r_as[T]() T {
	$if T.typ is f32 {
		return utils.remap_u8_to_f32(c.r, 0, 255, 0.0, 1.0)
	}
	panic('A shy TODO :)')
}

pub fn (c &Color) g_as[T]() T {
	$if T.typ is f32 {
		return utils.remap_u8_to_f32(c.g, 0, 255, 0.0, 1.0)
	}
	panic('A shy TODO :)')
}

pub fn (c &Color) b_as[T]() T {
	$if T.typ is f32 {
		return utils.remap_u8_to_f32(c.b, 0, 255, 0.0, 1.0)
	}
	panic('A shy TODO :)')
}

pub fn (c &Color) a_as[T]() T {
	$if T.typ is f32 {
		return utils.remap_u8_to_f32(c.a, 0, 255, 0.0, 1.0)
	}
	panic('A shy TODO :)')
}

// TODO: does not work as expected in regards to values generated from hex codes via 0xXXXXXX
pub fn (c &Color) to[T]() T {
	u32_res := ((u32(c.r) & 0xff) << 24) + ((u32(c.g) & 0xff) << 16) + ((u32(c.b) & 0xff) << 8) +
		(u32(c.a) & 0xff)
	return T(u32_res)
}

pub fn (mut c Color) variate(cv ColorVariation) {
	if !cv.has_variation() {
		return
	}
	if cv.r > 0 {
		c.r = u8(c.r * (1 - cv.r) + rand.f32_in_range(0, 255) or { 255 } * cv.r)
	}
	if cv.g > 0 {
		c.g = u8(c.g * (1 - cv.g) + rand.f32_in_range(0, 255) or { 0 } * cv.g)
	}
	if cv.b > 0 {
		c.b = u8(c.b * (1 - cv.b) + rand.f32_in_range(0, 255) or { 0 } * cv.b)
	}
	if cv.a > 0 {
		c.a = u8(c.a * (1 - cv.a) + rand.f32_in_range(0, 255) or { 255 } * cv.a)
	}
}

@[inline]
pub fn rgb_hex(hex u32) Color {
	return Color{u8(((hex >> 16) & 0xff)), u8(((hex >> 8) & 0xff)), u8((hex & 0xff)), u8(255)}
}

@[inline]
pub fn rgba_hex(hex u32) Color {
	return Color{u8(((hex >> 24) & 0xff)), u8(((hex >> 16) & 0xff)), u8(((hex >> 8) & 0xff)), u8((hex & 0xff))}
}

@[inline]
pub fn rgb(r u8, g u8, b u8) Color {
	return Color{r, g, b, u8(255)}
}

@[inline]
pub fn rgba(r u8, g u8, b u8, a u8) Color {
	return Color{r, g, b, a}
}

@[inline]
pub fn rgb_f32(r f32, g f32, b f32) Color {
	return Color{
		r: utils.remap_f32_to_u8(r, 0.0, 1.0, 0, 255)
		g: utils.remap_f32_to_u8(g, 0.0, 1.0, 0, 255)
		b: utils.remap_f32_to_u8(b, 0.0, 1.0, 0, 255)
		a: 255
	}
}

@[inline]
pub fn rgba_f32(r f32, g f32, b f32, a f32) Color {
	return Color{
		r: utils.remap_f32_to_u8(r, 0.0, 1.0, 0, 255)
		g: utils.remap_f32_to_u8(g, 0.0, 1.0, 0, 255)
		b: utils.remap_f32_to_u8(b, 0.0, 1.0, 0, 255)
		a: utils.remap_f32_to_u8(a, 0.0, 1.0, 0, 255)
	}
}

pub fn (c &ColorHSV) as_rgb() Color {
	mut r := f32(0)
	mut g := f32(0)
	mut b := f32(0)
	a := u8(utils.remap_f32_to_u8(c.a, 0, 1, 0, 255))

	h := utils.remap(f32(c.h), 0, 360, 0, 1)
	s := c.s
	v := c.v

	i := int(mth.floor(h * 6))
	f := h * 6 - i
	p := v * (1 - s)
	q := v * (1 - f * s)
	t := v * (1 - (1 - f) * s)

	// println('c.h: ${c.h} h: ${h} i: ${i} -> ${math.fmod(i, 6)}')

	match i % 6 {
		0 {
			r = v
			g = t
			b = p
		}
		1 {
			r = q
			g = v
			b = p
		}
		2 {
			r = p
			g = v
			b = t
		}
		3 {
			r = p
			g = q
			b = v
		}
		4 {
			r = t
			g = p
			b = v
		}
		5 {
			r = v
			g = p
			b = q
		}
		else {}
	}

	// println(utils.remap(f32(c.h), 0, 360, 0, 1))
	// println('HSV: ${h} ${s} ${v} I ${i} FPQT: ${f} ${p} ${q} ${t}')
	// println('RGBA: ${r} ${g} ${b} ${a} RGB*255(A): ${r * 255} ${g * 255} ${b * 255} (${a})')

	return Color{
		r: u8(r * 255)
		g: u8(g * 255)
		b: u8(b * 255)
		a: a
	}
}
