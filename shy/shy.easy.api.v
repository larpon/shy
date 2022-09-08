// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module shy

// import shy.vec
// High-level API

pub struct Easy {
	ShyStruct
mut:
	audio_engine &AudioEngine = null
	image_cache  map[string]Image
}

pub fn (mut e Easy) init() ! {
	e.audio_engine = e.shy.api.audio.engine(0)!
}

pub fn (mut e Easy) shutdown() ! {
	for _, mut image in e.image_cache {
		image.free()
	}
}

[params]
pub struct EasyText {
	x      f32
	y      f32
	text   string
	anchor Anchor
}

[inline]
pub fn (e Easy) text(et EasyText) {
	gfx := e.shy.api.gfx

	mut dt := gfx.draw.text()
	dt.begin()
	mut t := dt.text_2d()
	t.text = et.text
	t.x = et.x
	t.y = et.y
	t.draw()
	dt.end()
}

// Shape drawing sub-system

[params]
pub struct EasyRect {
	Rect
}

[inline]
pub fn (e Easy) rect(er EasyRect) {
	gfx := e.shy.api.gfx
	mut d := gfx.draw.shape_2d()
	d.begin()
	mut r := d.rect()
	r.x = er.x
	r.y = er.y
	r.w = er.w
	r.h = er.h
	r.draw()
	d.end()
}

// Audio sub-system

[params]
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

pub fn (e Easy) new_sound(esc EasySoundConfig) !&EasySound {
	e.shy.vet_issue(.warn, .hot_code, @STRUCT + '.' + @FN, 'memory fragmentation can happen when allocating in hot code paths. It is, in general, better to pre-load your assets...')
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
pub struct EasyImage {
	Rect
pub:
	uri   string
	color Color = rgb(255, 255, 255)
}

[inline]
pub fn (e Easy) image(ei EasyImage) {
	image := e.image_cache[ei.uri] or { return }

	gfx := e.shy.api.gfx
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

// Assets
pub fn (e &Easy) load(ao AssetOptions) ! {
	if _ := e.image_cache[ao.uri] {
		return
	}
	e.shy.vet_issue(.warn, .hot_code, '${@STRUCT}.${@FN}', 'memory fragmentation can happen when allocating in hot code paths. It is, in general, better to pre-load your assets...')
	mut assets := e.shy.assets()
	mut asset := assets.load(ao)!
	image := asset.to_image(
		mipmaps: 4
	)!
	unsafe {
		e.image_cache[ao.uri] = image
	}
}
