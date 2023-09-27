// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module lib

import os
import strings
import shy.wraps.sokol.gfx
import shy.wraps.stbi
import v.embed_file
import shy.analyse

// Assets is a manager of `Asset` instances.
[heap]
pub struct Assets {
	ShyStruct
mut:
	ass map[string]&Asset // Uuuh huh huh, hey Beavis... uhuh huh huh

	image_cache map[string]Image
	sound_cache map[string]Sound
	sb          strings.Builder
}

pub fn (mut a Assets) init() ! {
	a.shy.log.gdebug('${@STRUCT}.${@FN}', '')
	a.sb.ensure_cap(1024) // NOTE TODO(lmp) this needs attention if no GC is used
}

pub fn (mut a Assets) shutdown() ! {
	for _, mut image in a.image_cache {
		image.free()
	}
	a.image_cache.clear()
	for _, mut asset in a.ass {
		asset.shutdown()!
	}
	// Sounds are handled by the AudioEngine
	a.sound_cache.clear()

	unsafe { a.sb.free() }
}

// load loads a binary blob from a variety of sources and return
// a reference to an `Asset`.
pub fn (mut a Assets) load(alo AssetLoadOptions) !&Asset {
	analyse.count('${@MOD}.${@STRUCT}.${@FN}()', 1)
	source := alo.source
	if asset := a.ass[source.cache_key(mut a.sb)] {
		return asset
	}
	a.shy.vet_issue(.warn, .hot_code, '${@STRUCT}.${@FN}', 'memory fragmentation can happen when allocating in hot code paths. It is, in general, better to pre-load data. Loading "${source}"')

	// TODO enable network fetching etc.
	if alo.async {
		return error('${@STRUCT}.${@FN}: "${source}" asynchronously loading not implemented')
		/*
		asset := &Asset{
			shy: a.shy
			lo: alo
			status: .loading
		}
		a.shy.log.gdebug('${@STRUCT}.${@FN}', 'loading asynchronously "${source}"')
		a.ass[source.str()] = asset
		return asset
		*/
	}

	mut bytes := []u8{}
	match source {
		string {
			if !os.is_file(source) {
				return error('${@STRUCT}.${@FN}: "${source}" does not exist on the file system')
			}
			analyse.count('${@MOD}.${@STRUCT}.${@FN}(filesystem)', 1)
			bytes = os.read_bytes(source) or {
				return error('${@STRUCT}.${@FN}: "${source}" could not be loaded')
			}
		}
		embed_file.EmbedFileData {
			analyse.count('${@MOD}.${@STRUCT}.${@FN}(embedded)', 1)
			bytes = source.to_bytes()
		}
		TaggedSource {
			if !os.is_file(source.str()) {
				return error('${@STRUCT}.${@FN}: "${source.str()}" does not exist on the file system')
			}
			analyse.count('${@MOD}.${@STRUCT}.${@FN}(filesystem)', 1)
			bytes = os.read_bytes(source.str()) or {
				return error('${@STRUCT}.${@FN}: "${source.str()}" could not be loaded')
			}
		}
	}
	analyse.count_and_sum[u64]('${@MOD}.${@STRUCT}.${@FN}@bytes', u64(bytes.len))
	// TODO preallocated asset pool??
	asset := &Asset{
		shy: a.shy
		data: bytes
		lo: alo
		status: .loaded
	}
	a.shy.log.gdebug('${@STRUCT}.${@FN}', 'loaded "${source}"')
	// a.cache[&Asset](asset)! // TODO
	a.ass[source.str()] = asset
	return asset
}

/*
pub fn (mut a Assets) cache[T](asset T) ! {
	$if T is Image {
		ass := asset // as Image
		assert !isnil(ass.asset)
		analyse.count[u64]('${@MOD}.${@STRUCT}.${@FN}(${typeof(ass).name})', 1)
		a.image_cache[ass.asset.lo.source.cache_key(a.sb)] = asset
	} $else $if T is Sound {
		ass := asset //as Image
		assert !isnil(ass.asset)
		analyse.count[u64]('${@MOD}.${@STRUCT}.${@FN}(${typeof(ass).name})', 1)
		a.sound_cache[ass.asset.lo.source.cache_key(mut a.sb)] = asset
	} $else $if T is &Asset {
		ass := asset //as &Asset
		analyse.count[u64]('${@MOD}.${@STRUCT}.${@FN}(${typeof(ass).name})', 1)
		a.ass[asset.lo.source.str()] = ass
	} $else {
		return error('${@STRUCT}.${@FN}: caching of type ${typeof(asset).name} is not supported')
	}
	// return error('${@STRUCT}.${@FN}: Assets can be loaded with ${@STRUCT}.load(...)')
}
*/

pub fn (a &Assets) get[T](source AssetSource) !T {
	mut sb := a.sb // TODO(lmp) workaround V compile error
	$if T is Image {
		if image := a.image_cache[source.cache_key(mut sb)] {
			return image
		}
	} $else $if T is Sound {
		if sound := a.sound_cache[source.cache_key(mut sb)] {
			return sound
		}
	} $else $if T is &Asset {
		return a.ass[source.cache_key(mut sb)]
	} $else {
		// t := T{}
		// tof := typeof(t).name
		tof := 'TODO'
		return error('${@STRUCT}.${@FN}' + ': "${source}" of type ${tof} is not supported')
	}
	return error('${@STRUCT}.${@FN}: "${source}" is not available. Assets can be loaded with ${@STRUCT}.load(...)')
}

// Asset

pub enum AssetStatus {
	unknown
	error
	loading
	loaded
	streaming
	freed
}

pub struct TaggedSource {
	source AssetSource
	tag    string
}

pub fn (ts TaggedSource) str() string {
	return match ts.source {
		string {
			ts.source
		}
		embed_file.EmbedFileData {
			ts.source.path
		}
		TaggedSource {
			panic('${@STRUCT} does not support recursive tagged sources')
		}
	}
}

pub type AssetSource = TaggedSource | embed_file.EmbedFileData | string

fn (a AssetSource) cache_key(mut sb strings.Builder) string {
	return match a {
		string {
			a
		}
		embed_file.EmbedFileData {
			a.path
		}
		TaggedSource {
			//'${a.source.str()}#${a.tag}'
			sb.write_string(a.source.str())
			sb.write_string('#')
			sb.write_string(a.tag)
			sb.str()
		}
	}
}

pub fn (a AssetSource) str() string {
	return match a {
		string {
			a
		}
		embed_file.EmbedFileData {
			a.path
		}
		TaggedSource {
			a.source.str()
		}
	}
}

pub type AssetOptions = ImageOptions | SoundOptions

pub struct AssetLoadOptions {
pub:
	source AssetSource
	async  bool
	stream bool
	cache  bool = true
}

// Asset represents an binary blob
[heap]
pub struct Asset {
	ShyStruct
	data []u8
pub:
	lo     AssetLoadOptions
	status AssetStatus
}

pub fn (mut a Asset) shutdown() ! {
	unsafe {
		a.data.free()
	}
	a.ShyStruct.shutdown()!
}

// to converts `Asset`'s `.data` into T and return it.
pub fn (mut a Asset) to[T](ao AssetOptions) !T {
	$if T is Image {
		match ao {
			ImageOptions {
				return a.to_image(ao)!
			}
			else {
				t := T{}
				return error('${@STRUCT}.${@FN}: could not convert ${typeof(ao).name} "${ao.source}" to ${typeof(t).name}')
			}
		}
	} $else $if T is Sound {
		match ao {
			SoundOptions {
				return a.to_sound(ao)!
			}
			else {
				t := T{}
				return error('${@STRUCT}.${@FN}: could not convert ${typeof(ao).name} "${ao.source}" to ${typeof(t).name}')
			}
		}
	} $else {
		$compile_error('Asset.to[T]: only convertion to Image and Sound is currently supported')
	}
	// This should never be reached
	t := T{}
	return error('${@STRUCT}.${@FN}: could not convert ${typeof(ao).name} "${ao.source}" to ${typeof(t).name}')
}

// to_image converts the asset data into an Image
fn (mut a Asset) to_image(opt ImageOptions) !Image {
	analyse.count[u64]('${@MOD}.${@STRUCT}.${@FN}()', 1)
	assert !isnil(a.shy), 'Asset struct is not initialized'

	if opt.cache {
		if image := a.shy.assets().get[Image](a.lo.source) {
			return image
		}
	}
	assert a.status == .loaded, '${@STRUCT}.${@FN} Asset is not loaded'
	assert a.data.len > 0, '${@STRUCT}.${@FN} Asset.data appears empty'

	a.shy.log.gdebug('${@STRUCT}.${@FN}', 'converting asset "${a.lo.source}" to image')
	mut stb_img := stbi.load_from_memory(a.data.data, a.data.len) or {
		return error('${@STRUCT}.${@FN}' +
			': stbi failed loading asset "${a.lo.source}". Error: ${err}')
	}

	mut new_width := int(stb_img.width)
	mut new_height := int(stb_img.height)

	match opt.resize {
		f32 {
			new_width = int(f32(stb_img.width) * opt.resize)
			new_height = int(f32(stb_img.height) * opt.resize)
		}
		f64 {
			new_width = int(f32(stb_img.width) * opt.resize)
			new_height = int(f32(stb_img.height) * opt.resize)
		}
		Size {
			new_width = int(opt.resize.width)
			new_height = int(opt.resize.height)
		}
	}
	if new_width != stb_img.width || new_height != stb_img.height {
		a.shy.log.gdebug('${@STRUCT}.${@FN}', 'resizing image "${a.lo.source}" from ${stb_img.width}x${stb_img.height} to ${new_width}x${new_height}')
		scaled_stb_img := stbi.resize_uint8(&stb_img, new_width, new_height) or {
			return error('${@STRUCT}.${@FN}' +
				': stbi failed to resize loaded asset "${a.lo.source}". Error: ${err}')
		}
		assert scaled_stb_img.width > 0, 'Asset.to_image resized image width <= 0'
		assert scaled_stb_img.height > 0, 'Asset.to_image resized image height <= 0'
		stb_img.free()
		stb_img = scaled_stb_img
	}

	mut image := Image{
		asset: a
		opt: opt
		width: stb_img.width
		height: stb_img.height
		channels: stb_img.use_channels
		mipmaps: opt.mipmaps
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
			mut assets := a.shy.assets()
			// assets.cache[Image](image)! // TODO
			assets.image_cache[a.lo.source.cache_key(mut assets.sb)] = image
		}
	}
	return image
}

fn (mut a Asset) to_sound(opt SoundOptions) !Sound {
	analyse.count[u64]('${@MOD}.${@STRUCT}.${@FN}()', 1)
	assert !isnil(a.shy), 'Asset struct is not initialized'
	if opt.cache {
		if sound := a.shy.assets().get[Sound](a.lo.source) {
			return sound
		}
	}
	a.shy.vet_issue(.warn, .hot_code, '${@STRUCT}.${@FN}', 'memory fragmentation can happen when allocating in hot code paths. It is, in general, better to pre-load data.')
	mut engine := a.shy.audio().engine(opt.engine_id)!

	mut id := u16(0)
	mut id_end := u16(0)
	if opt.max_repeats > 1 {
		id, id_end = engine.load_copies(a.lo.source, opt.max_repeats)!
	} else {
		id = engine.load(a.lo.source)!
	}
	sound := Sound{
		asset: a
		id: id
		id_end: id_end
		loop: opt.loop
	}
	if opt.cache {
		unsafe {
			mut assets := a.shy.assets()
			assets.sound_cache[a.lo.source.cache_key(mut assets.sb)] = sound
			// assets.cache[Sound](sound)!
		}
	}

	return sound
}

// Image

pub enum ImageKind {
	unknown
	png
	jpeg
}

pub enum ImageFillMode {
	stretch // image is stretched to fit all of image width and height
	stretch_horizontally_tile_vertically // image is stretched to fit image width and tiled along the y axis (height/vertically)
	stretch_vertically_tile_horizontally // image is stretched to fit image height and tiled along the x axis (width/horizontally)
	aspect_fit // image is scaled uniformly to fit with no cropping into image width and height
	aspect_crop // image is scaled uniformly to fill image width and height and cropped if necessary
	tile // image is duplicated horizontally and vertically
	tile_vertically // image is stretched horizontally and tiled vertically
	tile_horizontally // image is stretched vertically and tiled horizontally
	pad // image is not transformed, leaving empty space if image width and/or height is > that loaded bitmap width/height
}

pub fn (ifm ImageFillMode) next() ImageFillMode {
	return match ifm {
		.stretch {
			.stretch_horizontally_tile_vertically
		}
		.stretch_horizontally_tile_vertically {
			.stretch_vertically_tile_horizontally
		}
		.stretch_vertically_tile_horizontally {
			.aspect_fit
		}
		.aspect_fit {
			.aspect_crop
		}
		.aspect_crop {
			.tile
		}
		.tile {
			.tile_vertically
		}
		.tile_vertically {
			.tile_horizontally
		}
		.tile_horizontally {
			.pad
		}
		.pad {
			.stretch
		}
	}
}

pub fn (ifm ImageFillMode) prev() ImageFillMode {
	return match ifm {
		.stretch {
			.pad
		}
		.stretch_horizontally_tile_vertically {
			.stretch
		}
		.stretch_vertically_tile_horizontally {
			.stretch_horizontally_tile_vertically
		}
		.aspect_fit {
			.stretch_vertically_tile_horizontally
		}
		.aspect_crop {
			.aspect_fit
		}
		.tile {
			.aspect_crop
		}
		.tile_vertically {
			.tile
		}
		.tile_horizontally {
			.tile_vertically
		}
		.pad {
			.tile_horizontally
		}
	}
}

[heap; noinit]
pub struct Image {
	opt ImageOptions
pub:
	asset  &Asset = null // TODO removing this results in compiler warnings a few places
	width  int
	height int
mut:
	channels int
	ready    bool
	mipmaps  int
	kind     ImageKind
	// Implementation specific
	gfx_image gfx.Image
}

pub type ImageWrap = gfx.Wrap

pub type ResizeValue = Size | f32 | f64

[params]
pub struct ImageOptions {
	AssetLoadOptions
mut:
	resize  ResizeValue = f32(1.0)
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

pub fn (i &Image) source() AssetSource {
	return i.asset.lo.source
}

[markused]
pub const no_sound = Sound{}

[params]
pub struct SoundOptions {
	AssetLoadOptions
	engine_id   u8   // Load sound into this engine
	loop        bool //
	max_repeats u8
}

[heap; noinit]
pub struct Sound {
pub:
	asset  &Asset = null // TODO removing this results in compiler warnings a few places
	opt    SoundOptions
	id     u16
	id_end u16
mut:
	alarm  AlarmID
	paused bool // TODO
pub mut:
	volume   f32 = 1.0
	pitch    f32
	loop     bool
	on_end   ?fn (Sound)
	on_start ?fn (Sound)
	on_pause ?fn (Sound, bool)
}

fn sound_alarm_check(sound voidptr) bool {
	assert !isnil(sound)
	s := unsafe { &Sound(sound) }
	ended := !s.is_playing() && !s.is_looping() && !s.paused
	if ended {
		if on_end := s.on_end {
			on_end(Sound{
				...s
			})
		}
		return true
	}
	return false
}

fn (s &Sound) engine() &AudioEngine {
	engine := s.asset.shy.audio().engine(s.opt.engine_id) or { unsafe { nil } }
	assert !isnil(engine), 'Sound engine is not valid'
	return engine
}

// play plays the sound.
pub fn (s &Sound) play() {
	assert !isnil(s.asset), 'Sound is not initialized'
	engine := s.engine()
	engine.set_looping(s.id, s.loop)
	s.set_volume(s.volume)
	if s.pitch != 0 {
		s.set_pitch(s.pitch)
	}
	mut id := s.id
	if s.id_end > 0 {
		for i in id .. s.id_end {
			if !engine.is_playing(i) {
				id = i
				break
			}
		}
	}

	// This check prevents double fires if sound is stop()/play() in same time frame.
	if !s.is_playing() {
		if on_start := s.on_start {
			on_start(Sound{
				...s
			})
		}
		// Create an alarm to watch for changes to the sound's state
		// TODO this could probably be made smarter
		aid := s.asset.shy.make_alarm(
			check: sound_alarm_check
			user_data: voidptr(s)
		)
		unsafe {
			s.alarm = aid
		}
	}
	engine.play(id)
}

// set_volume sets the volume of the `Sound`.
// See also: `AudioEngine.set_master_volume`.
pub fn (s &Sound) set_volume(volume f32) {
	engine := s.engine()
	engine.set_volume(s.id, volume)
}

// set_pitch sets the pitch for the `Sound`.
pub fn (s &Sound) set_pitch(pitch f32) {
	engine := s.engine()
	engine.set_pitch(s.id, pitch)
}

// is_paused returns true if the sound is paused.
pub fn (s &Sound) is_paused() bool {
	return s.paused
}

// pause pauses the sound.
pub fn (s &Sound) pause(pause bool) {
	assert !isnil(s.asset), 'Sound is not initialized'
	engine := s.engine()

	// TODO doesn't work as expected currently
	// since all this shit is on the stack maybe check where the cursor is instead?
	already_paused := s.paused
	// This check prevents double fires.
	if already_paused == pause {
		return
	}
	unsafe {
		s.paused = pause
	}
	if on_pause := s.on_pause {
		on_pause(Sound{
			...s
		}, s.paused)
	}
	unsafe { s.asset.shy.pause_alarm(s.alarm, s.paused) }
	if s.paused {
		engine.stop(s.id)
	} else {
		engine.play(s.id)
	}
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
	assert !isnil(engine), 'Sound engine is not initialized'
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
	engine.seek_to_pcm_frame(s.id, 0)
	engine.set_looping(s.id, s.loop)
}
