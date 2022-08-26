// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
//
// This file defines (most of) Shy's public API
module shy

// import shy.vec
// High-level API

pub struct Easy {
	ShyStruct
}

[params]
pub struct EasyText {
	x      f32
	y      f32
	text   string
	anchor Anchor
}

[params]
pub struct EasyAudio {
	id string
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

[inline]
pub fn (e Easy) load_audio(id string, path string) ! {
	audio := e.shy.api.audio
	audio.load(id, path)!
}

pub fn (e Easy) play_audio(ea EasyAudio) {
	audio := e.shy.api.audio
	audio.play(ea.id)
}

pub fn (e Easy) stop_audio(ea EasyAudio) {
	audio := e.shy.api.audio
	audio.stop(ea.id)
}
