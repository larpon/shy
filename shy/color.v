// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module shy

import shy.utils

// TODO outphase this
const color_target_size = 2 // TODO a V bug prevent this to be moved to e.g. draw.v

pub const (
	colors = BaseColors{}
)

pub struct Color {
	r u8
	g u8
	b u8
	a u8
}

pub struct Colorf32 {
	r f32
	g f32
	b f32
	a f32
}

pub struct ShyColors {
pub:
	red   Color = Color{155, 25, 25, 255}
	white Color = Color{211, 211, 211, 255}
	blue  Color = Color{0, 0, 211, 255}
}

pub struct BaseColors {
pub:
	red   Color = Color{255, 0, 0, 255} // NOTE BUG using rgb(...) here triggers a C compiler error
	green Color = Color{0, 255, 0, 255}
	blue  Color = Color{0, 0, 255, 255}
	white Color = Color{255, 255, 255, 255}
	shy   ShyColors
}

pub struct ColorsSolidAndOutline {
pub mut:
	solid   Color = rgb(155, 25, 25)
	outline Color = rgb(211, 211, 211)
}

pub fn (c Color) is_opaque() bool {
	return c.a == 255
}

pub fn (c Color) as_f32() Colorf32 {
	return Colorf32{
		r: utils.remap_u8_to_f32(c.r, 0, 255, 0.0, 1.0)
		g: utils.remap_u8_to_f32(c.g, 0, 255, 0.0, 1.0)
		b: utils.remap_u8_to_f32(c.b, 0, 255, 0.0, 1.0)
		a: utils.remap_u8_to_f32(c.a, 0, 255, 0.0, 1.0)
	}
}

pub fn (c Color) r_as<T>() T {
	$if T.typ is f32 {
		return utils.remap_u8_to_f32(c.r, 0, 255, 0.0, 1.0)
	}
	panic('A shy TODO :)')
}

pub fn (c Color) g_as<T>() T {
	$if T.typ is f32 {
		return utils.remap_u8_to_f32(c.g, 0, 255, 0.0, 1.0)
	}
	panic('A shy TODO :)')
}

pub fn (c Color) b_as<T>() T {
	$if T.typ is f32 {
		return utils.remap_u8_to_f32(c.b, 0, 255, 0.0, 1.0)
	}
	panic('A shy TODO :)')
}

pub fn (c Color) a_as<T>() T {
	$if T.typ is f32 {
		return utils.remap_u8_to_f32(c.a, 0, 255, 0.0, 1.0)
	}
	panic('A shy TODO :)')
}

[inline]
pub fn rgb(r u8, g u8, b u8) Color {
	return Color{r, g, b, u8(255)}
}

[inline]
pub fn rgba(r u8, g u8, b u8, a u8) Color {
	return Color{r, g, b, a}
}

[inline]
pub fn rgb_f32(r f32, g f32, b f32) Color {
	return Color{
		r: utils.remap_f32_to_u8(r, 0.0, 1.0, 0, 255)
		g: utils.remap_f32_to_u8(g, 0.0, 1.0, 0, 255)
		b: utils.remap_f32_to_u8(b, 0.0, 1.0, 0, 255)
		a: 255
	}
}

[inline]
pub fn rgba_f32(r f32, g f32, b f32, a f32) Color {
	return Color{
		r: utils.remap_f32_to_u8(r, 0.0, 1.0, 0, 255)
		g: utils.remap_f32_to_u8(g, 0.0, 1.0, 0, 255)
		b: utils.remap_f32_to_u8(b, 0.0, 1.0, 0, 255)
		a: utils.remap_f32_to_u8(a, 0.0, 1.0, 0, 255)
	}
}
