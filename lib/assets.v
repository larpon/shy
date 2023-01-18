// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module lib

import os
import shy.wraps.sokol.gfx
import stbi

pub enum AssetStatus {
	unknown
	error
	loading
	loaded
	streaming
	freed
}

pub type AssetOptions = ImageOptions | SoundOptions

pub struct AssetLoadOptions {
pub:
	uri    string
	async  bool = true
	stream bool
	cache  bool = true
}

[heap]
pub struct Asset {
	ShyStruct
	data []u8
pub:
	lo     AssetLoadOptions
	status AssetStatus
}

// to converts `Asset`'s `.data` into T and return it.
pub fn (mut a Asset) to[T](ao AssetOptions) !T {
	$if T is Image {
		match ao {
			ImageOptions {
				return a.to_image(ao)!
			}
			else {}
		}
	} $else $if T is Sound {
		match ao {
			SoundOptions {
				return a.to_sound(ao)!
			}
			else {}
		}
	}
	t := T{}
	return error('${@STRUCT}.${@FN}' +
		': could not convert ${typeof(ao).name} "${ao.uri}" to ${typeof(t).name}')
}

fn (mut a Asset) to_image(opt ImageOptions) !Image {
	if opt.cache {
		if image := a.shy.assets().image_cache[a.lo.uri] {
			return image
		}
	}
	assert a.status == .loaded, 'Asset is not loaded'
	assert a.data.len > 0, 'Asset.data appears empty'

	a.shy.log.gdebug('${@STRUCT}.${@FN}', 'converting asset "${a.lo.uri}" to image')
	stb_img := stbi.load_from_memory(a.data.data, a.data.len) or {
		return error('${@STRUCT}.${@FN}' + ': stbi failed loading asset "${a.lo.uri}"')
	}

	mut image := Image{
		asset: a
		opt: opt
		width: stb_img.width
		height: stb_img.height
		channels: stb_img.nr_channels
		mipmaps: opt.mipmaps
		// cache: opt.cache
		ready: stb_img.ok
		// data: stb_img.data
		kind: .png // TODO stb_img.ext
	}

	// Sokol image
	// eprintln('\n init sokol image ${img.path} ok=${img.sg_image_ok}')
	mut img_desc := gfx.ImageDesc{
		width: image.width
		height: image.height
		num_mipmaps: 0 // TODO image.mipmaps
		wrap_u: opt.wrap_u // .clamp_to_edge
		wrap_v: opt.wrap_v // .clamp_to_edge
		// label: &u8(0)
		pixel_format: .rgba8
	}

	// println('${image.width} x ${image.height} x ${image.channels} --- ${a.data.len}')
	// println('${usize(4 * image.width * image.height)} vs ${a.data.len}')
	img_desc.data.subimage[0][0] = gfx.Range{
		ptr: stb_img.data
		size: usize(4 * image.width * image.height) // NOTE 4 is not always equal to image.channels count, but sokol_gl contexts expect it
	}

	image.gfx_image = gfx.make_image(&img_desc)

	stb_img.free()

	if opt.cache {
		unsafe {
			a.shy.assets().image_cache[a.lo.uri] = image
		}
	}

	return image
}

fn (mut a Asset) to_sound(opt SoundOptions) !Sound {
	assert !isnil(a.shy), 'Asset struct is not initialized'
	a.shy.vet_issue(.warn, .hot_code, '${@STRUCT}.${@FN}', 'memory fragmentation can happen when allocating in hot code paths. It is, in general, better to pre-load data.')
	mut engine := a.shy.audio().engine(opt.engine_id)!

	mut id := u16(0)
	mut id_end := u16(0)
	if opt.max_repeats > 1 {
		id, id_end = engine.load_copies(a.lo.uri, opt.max_repeats)!
	} else {
		id = engine.load(a.lo.uri)!
	}
	return Sound{
		asset: a
		id: id
		id_end: id_end
		loop: opt.loop
	}
}

// TODO free resources etc.
[heap]
pub struct Assets {
	ShyStruct
mut:
	ass map[string]&Asset // Uuuh huh huh, hey Beavis... uhuh huh huh

	image_cache map[string]Image
}

pub fn (mut a Assets) init() ! {}

pub fn (mut a Assets) shutdown() ! {
	for _, mut image in a.image_cache {
		image.free()
	}
	// Sounds are handled by the AudioEngine
}

pub fn (mut a Assets) load(alo AssetLoadOptions) !&Asset {
	uri := alo.uri
	if asset := a.ass[uri] {
		return asset
	}
	a.shy.vet_issue(.warn, .hot_code, '${@STRUCT}.${@FN}', 'memory fragmentation can happen when allocating in hot code paths. It is, in general, better to pre-load data. Loading "${uri}"')

	// TODO enable network fetching etc.
	if alo.async {
	}
	if !os.is_file(uri) {
		return error('${@STRUCT}.${@FN}' + ': "${uri}" does not exist')
	}
	bytes := os.read_bytes(uri) or {
		return error('${@STRUCT}.${@FN}' + ': "${uri}" could not be loaded')
	}
	// TODO asset pool??
	asset := &Asset{
		shy: a.shy
		data: bytes
		lo: alo
		status: .loaded
	}
	a.shy.log.gdebug('${@STRUCT}.${@FN}', 'loaded "${uri}"')
	a.ass[uri] = asset
	return asset
}

pub fn (a &Assets) get[T](uri string) !T {
	$if T is Image {
		return a.get_cached_image(uri)
	} $else $if T is Asset {
		return a.ass[uri]
	} $else {
		// t := T{}
		// tof := typeof(t).name
		tof := 'TODO'
		return error('${@STRUCT}.${@FN}' + ': "${uri}" of type ${tof} is not supported')
	}
}

pub fn (a &Assets) get_cached_image(uri string) !Image {
	if image := a.image_cache[uri] {
		return image
	}
	return error('${@STRUCT}.${@FN}' +
		': "${uri}" is not available. Assets can be loaded with ${@STRUCT}.load(...)')
}

pub fn (a &Assets) get_cached[T](uri string) !T {
	i_t := T{}
	if typeof(i_t).name.all_after('shy.') == 'Image' {
		if image := a.image_cache[uri] {
			return image
		}
	}
	return error('${@STRUCT}.${@FN}' +
		': "${uri}" is not available. Assets can be loaded with ${@STRUCT}.load(...)')
}

pub enum ImageKind {
	unknown
	png
	jpeg
}

pub enum ImageFillMode {
	stretch // image is scaled to fit
	aspect_fit // image is scaled uniformly to fit with no cropping
	aspect_crop // image is scaled uniformly to fill and cropped if necessary
	tile // image is duplicated horizontally and vertically
	tile_vertically // image is stretched horizontally and tiled vertically
	tile_horizontally // image is stretched vertically and tiled horizontally
	pad // image is not transformed
}

[heap]
pub struct Image {
	asset &Asset = null // TODO removing this results in compiler warnings a few places
	opt   ImageOptions
pub:
	width  int
	height int
mut:
	channels int
	ready    bool
	mipmaps  int
	// data voidptr
	kind ImageKind
	// Implementation specific
	gfx_image gfx.Image
}

pub type ImageWrap = gfx.Wrap

[params]
pub struct ImageOptions {
	AssetLoadOptions
mut:
	width   int
	height  int
	mipmaps int
	wrap_u  ImageWrap = .clamp_to_edge
	wrap_v  ImageWrap = .clamp_to_edge
}

pub fn (mut i Image) free() {
	unsafe {
		gfx.destroy_image(i.gfx_image)
	}
}

pub fn (i &Image) uri() string {
	return i.asset.lo.uri
}

[params]
pub struct SoundOptions {
	AssetLoadOptions
	engine_id   u8   // Load sound into this engine
	loop        bool //
	max_repeats u8
}

[heap]
pub struct Sound {
	asset  &Asset = null // TODO removing this results in compiler warnings a few places
	opt    SoundOptions
	id     u16
	id_end u16
pub mut:
	loop bool
}

// play plays the sound.
pub fn (s &Sound) play() {
	assert !isnil(s.asset), 'Sound is not initialized'
	engine := s.engine()
	engine.set_looping(s.id, s.loop)
	mut id := s.id
	if s.id_end > 0 {
		for i in id .. s.id_end {
			if !engine.is_playing(i) {
				id = i
				break
			}
		}
	}
	engine.play(id)
}

fn (s &Sound) engine() &AudioEngine {
	engine := s.asset.shy.audio().engine(s.opt.engine_id) or { unsafe { nil } }
	assert !isnil(engine), 'Sound engine is not valid'
	return engine
}

// is_looping returns `true` if the sound is looping, `false` otherwise.
pub fn (s &Sound) is_looping() bool {
	assert !isnil(s.asset), 'Sound is not initialized'
	engine := s.engine()
	mut id := s.id
	if s.id_end > 0 {
		for i in id .. s.id_end {
			if engine.is_looping(i) {
				return true
			}
		}
	}
	return engine.is_looping(id)
}

// is_playing returns `true` if the sound is playing, `false` otherwise.
pub fn (s &Sound) is_playing() bool {
	assert !isnil(s.asset), 'Sound is not initialized'
	engine := s.engine()

	mut id := s.id
	if s.id_end > 0 {
		for i in id .. s.id_end {
			if engine.is_playing(i) {
				return true
			}
		}
	}
	return engine.is_playing(id)
}

// stop stops the sound, if it is playing.
pub fn (s &Sound) stop() {
	assert !isnil(s.asset), 'Sound is not initialized'
	engine := s.engine()
	engine.stop(s.id)
	engine.set_looping(s.id, s.loop)
}
