// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module shy

// High-level as-easy-as-it-gets API

// EasyDo is an internal struct for fire-and-forget/instant calling of Easy methods.
[noinit]
pub struct EasyDo {
pub mut: // TODO error: field ... is not public - make this just "pub" to callers - and mut to internal system
	easy &Easy = null
}

[heap]
pub struct Easy {
	ShyStruct
mut:
	do           EasyDo
	audio_engine &AudioEngine = null
}

pub fn (mut e Easy) init() ! {
	assert !isnil(e.shy), 'Easy struct is not initialized'
	e.do.easy = e
	e.audio_engine = e.shy.api.audio.engine(0)!
}

pub fn (mut e Easy) shutdown() ! {}

[params]
pub struct EasyTextConfig {
pub mut:
	x      f32
	y      f32
	text   string
	anchor Anchor
}

[noinit]
pub struct EasyText {
	ShyStruct
pub mut:
	x      f32
	y      f32
	text   string
	anchor Anchor
}

[inline]
pub fn (et &EasyText) draw() {
	gfx := et.shy.api.gfx
	mut dt := gfx.draw.text()
	dt.begin()
	mut t := dt.text_2d()
	t.text = et.text
	t.x = et.x
	t.y = et.y
	t.draw()
	dt.end()
}

[inline]
pub fn (e &Easy) text(etc EasyTextConfig) EasyText {
	assert !isnil(e.shy), 'Easy struct is not initialized'
	return EasyText{
		...etc
		shy: e.shy
	}
}

[inline]
pub fn (ed &EasyDo) text(etc EasyTextConfig) {
	assert !isnil(ed.easy), 'Easy struct is not initialized'
	ed.easy.text(etc).draw()
}

// Shape drawing sub-system

[params]
pub struct EasyRectConfig {
	Rect
pub mut:
	colors ShapeColors
}

[noinit]
pub struct EasyRect {
	ShyStruct
	Rect
pub mut:
	colors ShapeColors
}

[inline]
pub fn (er &EasyRect) draw() {
	gfx := er.shy.api.gfx
	mut d := gfx.draw.shape_2d()
	d.begin()
	mut r := d.rect()
	r.x = er.x
	r.y = er.y
	r.w = er.w
	r.h = er.h
	r.colors = er.colors
	r.draw()
	d.end()
}

[inline]
pub fn (e &Easy) rect(erc EasyRectConfig) EasyRect {
	assert !isnil(e.shy), 'Easy struct is not initialized'
	return EasyRect{
		...erc
		shy: e.shy
	}
}

[inline]
pub fn (ed &EasyDo) rect(erc EasyRectConfig) {
	assert !isnil(ed.easy), 'Easy struct is not initialized'
	ed.easy.rect(erc).draw()
}

// Audio sub-system

[noinit]
pub struct EasySound {
	ShyStruct
	engine &AudioEngine
	id     u16
	id_end u16
pub mut:
	loop bool
}

[params]
pub struct EasySoundConfig {
	path        string
	loop        bool
	max_repeats u8 // number of copies of the sound, needed to support repeated playback of the same sound
}

pub fn (e &Easy) new_sound(esc EasySoundConfig) !&EasySound {
	assert !isnil(e.shy), 'Easy struct is not initialized'
	e.shy.vet_issue(.warn, .hot_code, '${@STRUCT}.${@FN}', 'memory fragmentation can happen when allocating in hot code paths. It is, in general, better to pre-load data.')
	mut audio := e.audio_engine

	mut id := u16(0)
	mut id_end := u16(0)
	if esc.max_repeats > 1 {
		id, id_end = audio.load_copies(esc.path, esc.max_repeats)!
	} else {
		id = audio.load(esc.path)!
	}
	return &EasySound{
		shy: e.shy
		engine: e.audio_engine
		id: id
		id_end: id_end
		loop: esc.loop
	}
}

pub fn (es &EasySound) play() {
	es.engine.set_looping(es.id, es.loop)
	mut id := es.id
	if es.id_end > 0 {
		for i in id .. es.id_end {
			if !es.engine.is_playing(i) {
				id = i
				break
			}
		}
	}
	es.engine.play(id)
}

pub fn (es &EasySound) is_looping() bool {
	mut id := es.id
	if es.id_end > 0 {
		for i in id .. es.id_end {
			if es.engine.is_looping(i) {
				return true
			}
		}
	}
	return es.engine.is_looping(id)
}

pub fn (es &EasySound) is_playing() bool {
	mut id := es.id
	if es.id_end > 0 {
		for i in id .. es.id_end {
			if es.engine.is_playing(i) {
				return true
			}
		}
	}
	return es.engine.is_playing(id)
}

pub fn (es &EasySound) stop() {
	es.engine.stop(es.id)
	es.engine.set_looping(es.id, es.loop)
}

// Image drawing sub-system
[params]
pub struct EasyImageConfig {
	Rect
pub:
	uri   string
	color Color = rgb(255, 255, 255)
}

[noinit]
pub struct EasyImage {
	ShyStruct
	Rect
pub:
	uri   string
	color Color = rgb(255, 255, 255)
}

pub fn (ei &EasyImage) draw() {
	// TODO e.shy.assets.get_cached(...) ???
	mut image := Image{}
	if img := ei.shy.assets().image_cache[ei.uri] {
		image = img
	} else {
		return
	}

	gfx := ei.shy.api.gfx
	mut d := gfx.draw.image()
	d.begin()
	mut i2d := d.image_2d(image)
	i2d.color = ei.color
	i2d.x = ei.x
	i2d.y = ei.y
	i2d.w = ei.w
	i2d.h = ei.h
	i2d.draw()
	d.end()
}

[inline]
pub fn (e &Easy) image(eic EasyImageConfig) EasyImage {
	assert !isnil(e.shy), 'Easy struct is not initialized'
	return EasyImage{
		...eic
		shy: e.shy
	}
}

[inline]
pub fn (ed &EasyDo) image(eic EasyImageConfig) {
	assert !isnil(ed.easy), 'Easy struct is not initialized'
	ed.easy.image(eic).draw()
}

// Assets
pub fn (e &Easy) load(ao AssetOptions) ! {
	// TODO e.shy.assets.is_cached(...) ???
	if _ := e.shy.assets().image_cache[ao.uri] {
		return
	}
	e.shy.vet_issue(.warn, .hot_code, '${@STRUCT}.${@FN}', 'memory fragmentation can happen when allocating in hot code paths. It is, in general, better to pre-load data.')
	mut assets := e.shy.assets()
	mut asset := assets.load(ao)!
	_ := asset.to_image(
		cache: true
		mipmaps: 4
	)!
}

[inline]
pub fn (ed &EasyDo) load(ao AssetOptions) ! {
	assert !isnil(ed.easy), 'Easy struct is not initialized'
	ed.easy.load(ao)!
}
