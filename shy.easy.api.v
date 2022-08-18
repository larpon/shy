// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
//
// This file defines (most of) Shy's public API
module shy

// import shy.vec
// High-level API

pub struct Easy {
	ShyApp
}

[params]
pub struct EasyText {
	x      f32
	y      f32
	text   string
	origin Origin
}

[inline]
pub fn (e Easy) text(et EasyText) {
	gfx := e.shy.api.gfx

	mut dt := gfx.draw.new_text()
	dt.begin()
	mut t := dt.new()
	t.text = et.text
	t.x = et.x
	t.y = et.y
	t.draw()
	dt.end()
}

[params]
pub struct EasyRect {
	Rect
}

[inline]
pub fn (e Easy) rect(er EasyRect) {
	gfx := e.shy.api.gfx
	mut d := gfx.draw.new_2d()
	d.begin()
	mut r := d.new_rect()
	r.x = er.x
	r.y = er.y
	r.w = er.w
	r.h = er.h
	r.draw()
	d.end()
}
