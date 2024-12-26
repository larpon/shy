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
import shy.fetch

// Assets is a manager of `Asset` instances.
@[heap]
pub struct Assets {
	ShyStruct
mut:
	ass map[string]&Asset // Uuuh huh huh, hey Beavis... uhuh huh huh

	image_cache map[string]Image
	sound_cache map[string]Sound
	blob_cache  map[string]Blob
	sb          strings.Builder
	// Async loading
	async_load_queue []AssetLoadOptions
	in_progress      map[u32]AssetSource
	loader           fetch.Loader
	//
	error_asset Asset
	error_sound Sound
	error_image Image
	error_blob  Blob
}

pub fn (mut a Assets) init() ! {
	a.shy.log.gdebug('${@STRUCT}.${@FN}', '')
	$if shy_debug_assets ? {
		$if !debug {
			eprintln('Pass `-cg -d shy_debug_assets` to enable asset debug output')
		}
	}
	a.sb.ensure_cap(1024) // TODO: (lmp) this needs attention if no GC is used
	a.loader.init()!
	a.load_error_assets()!
}

pub fn (mut a Assets) shutdown() ! {
	a.async_load_queue.clear()
	a.loader.shutdown()!

	// BUG: there's invalid memory access upon Assets.shutdown() if too many of the
	// same asset has been unloaded and loaded again for some reason,
	// see Assets.unload that may, or may not, be the function that causes it.
	// It could be also just the `-d sdl_memory_no_gc` horrorshow.
	// keys := a.ass.keys()
	// values := a.ass.values()
	// println('Keys ${keys} ${keys.len} vs ${values.len}')
	for k, mut asset in a.ass {
		// asset.shy = a.shy
		if isnil(asset) {
			eprintln('${@LOCATION}: Upcoming crash at null pointer at key "${k}"')
			continue
		}
		asset.shutdown()!
	}
	// BUG: the `free(asset)` can not be done in the function above for unknown reasons
	for _, asset in a.ass {
		unsafe { free(asset) }
	}
	a.ass.clear()
	for _, mut image in a.image_cache {
		image.shutdown()!
		// a.image_cache.delete(k)
	}
	a.image_cache.clear()

	// Sounds are handled by the AudioEngine
	a.sound_cache.clear()

	// Blobs
	for _, mut blob in a.blob_cache {
		blob.shutdown()!
	}
	a.blob_cache.clear()

	unsafe { a.sb.free() }
}

fn (mut a Assets) load_error_assets() ! {
	a.error_asset = Asset{
		shy:    a.shy
		data:   [u8(0xD), 0xE, 0xA, 0xD]
		lo:     AssetLoadOptions{}
		status: .error
	}
	ass_image := a.load(
		source: c_embedded_asset_error_image
	)!
	a.error_image = ass_image.to[Image](ImageOptions{
		source: c_embedded_asset_error_image
	})!

	ass_blob := a.load(
		source: c_embedded_asset_error_blob
	)!
	a.error_blob = ass_blob.to[Blob](BlobOptions{
		source: c_embedded_asset_error_blob
	})!

	ass_sound := a.load(
		source: c_embedded_asset_error_sound
	)!
	a.error_sound = ass_sound.to[Sound](SoundOptions{
		source: c_embedded_asset_error_sound
	})!
}

// load loads a binary blob from a variety of sources and return
// a reference to an `Asset`.
// See also: unload
pub fn (mut a Assets) load(alo AssetLoadOptions) !&Asset {
	analyse.count('${@MOD}.${@STRUCT}.${@FN}()', 1)
	source := alo.source
	if asset := a.ass[source.str()] {
		return asset
	}
	a.shy.vet_issue(.warn, .hot_code, '${@STRUCT}.${@FN}', 'memory fragmentation can happen when allocating in hot code paths. It is, in general, better to pre-load data. Loading "${source}"')

	if alo.io.has(.async) {
		// TODO: `os.file_size` does not work on Android
		file_size := int(os.file_size(source.str()))
		asset := &Asset{
			shy:    a.shy
			lo:     alo
			status: .loading
			data:   []u8{cap: file_size}
		}
		$if shy_debug_assets ? {
			a.shy.log.gdebug('${@STRUCT}.${@FN}', 'loading (asynchronously) "${source}"...')
		}
		a.ass[source.str()] = asset

		a.async_load_queue << alo

		return asset
	}

	$if shy_debug_assets ? {
		a.shy.log.gdebug('${@STRUCT}.${@FN}', 'loading "${source}"...')
	}
	mut bytes := []u8{len: 0}
	match source {
		string {
			analyse.count('${@MOD}.${@STRUCT}.${@FN}(filesystem)', 1)
			$if android && !termux {
				if !source.starts_with('/') {
					bytes = sdl_read_bytes_from_apk(source)!
				} else {
					return error('${@STRUCT}.${@FN}:${@LINE}: paths should be *relative* when loaded from an Android APK/AAB, "${source}" is not')
				}
			} $else {
				if !os.is_file(source) {
					return error('${@STRUCT}.${@FN}:${@LINE}: "${source}" does not exist on the file system')
				}
				bytes = os.read_bytes(source) or {
					return error('${@STRUCT}.${@FN}: "${source}" could not be loaded')
				}
			}
			$if shy_debug_assets ? {
				a.shy.log.gdebug('${@STRUCT}.${@FN}', 'read successfully from string')
			}
		}
		embed_file.EmbedFileData {
			analyse.count('${@MOD}.${@STRUCT}.${@FN}(embedded)', 1)
			bytes = source.to_bytes()
			$if shy_debug_assets ? {
				a.shy.log.gdebug('${@STRUCT}.${@FN}', 'read successfully from embedded data')
			}
		}
		TaggedSource {
			analyse.count('${@MOD}.${@STRUCT}.${@FN}(filesystem)', 1)
			$if android && !termux {
				if !source.str().starts_with('/') {
					bytes = sdl_read_bytes_from_apk(source.str())!
				} else {
					return error('${@STRUCT}.${@FN}:${@LINE}: paths should be *relative* when loaded from an Android APK/AAB, "${source.str()}" is not')
				}
			} $else {
				if !os.is_file(source.str()) {
					return error('${@STRUCT}.${@FN}:${@LINE}: "${source.str()}" does not exist on the file system')
				}
				bytes = os.read_bytes(source.str()) or {
					return error('${@STRUCT}.${@FN}: "${source.str()}" could not be loaded')
				}
			}
			$if shy_debug_assets ? {
				a.shy.log.gdebug('${@STRUCT}.${@FN}', 'read successfully from tagged string')
			}
		}
	}
	analyse.count_and_sum[u64]('${@MOD}.${@STRUCT}.${@FN}@bytes', u64(bytes.len))

	if bytes.len <= 0 {
		return error('${@STRUCT}.${@FN}:${@LINE}: error loaded <= 0 bytes from "${source.str()}"')
	}

	// PERFORMANCE: TODO: preallocated asset pool??
	asset := &Asset{
		shy:    a.shy
		data:   bytes
		lo:     alo
		status: .loaded
	}
	$if shy_debug_assets ? {
		a.shy.log.gdebug('${@STRUCT}.${@FN}', 'loaded ~${u64(bytes.len / 1024)} kB from "${source}"')
	}
	// a.cache[&Asset](asset)! // TODO
	a.ass[source.str()] = asset
	return asset
}

// unload unloads a binary blob from a range of targets
pub fn (mut a Assets) unload(auo AssetUnloadOptions) ! {
	analyse.count('${@MOD}.${@STRUCT}.${@FN}()', 1)
	source := auo.source
	source_cache_key := source.cache_key(mut a.sb)
	$if shy_debug_assets ? {
		a.shy.log.gdebug('${@STRUCT}.${@FN}', 'unloading "${source_cache_key}"...')
	}
	// BUG: there's invalid memory access upon Assets.shutdown() if too many of the same asset has been unloaded and loaded again for some reason, see Asset.shutdown / Assets.shutdown
	if mut asset := a.ass[source_cache_key] {
		a.shy.vet_issue(.warn, .hot_code, '${@STRUCT}.${@FN}', 'memory fragmentation can happen when deallocating in hot code paths. It is, in general, better to unload data on shutdown. Unloading "${source.str()}"')

		if mut blob := a.blob_cache[source_cache_key] {
			blob.shutdown()!
			a.blob_cache.delete(source_cache_key)
		}
		if mut image := a.image_cache[source_cache_key] {
			image.shutdown()!
			a.image_cache.delete(source_cache_key)
		}
		if _ := a.sound_cache[source_cache_key] {
			a.sound_cache.delete(source_cache_key)
		}

		asset.shutdown()!
		unsafe { free(asset) }

		// a.ass[source.str()] = null
		a.ass.delete(source.str())
		$if shy_debug_assets ? {
			a.shy.log.gdebug('${@STRUCT}.${@FN}', 'unloaded "${source_cache_key}"')
		}
		return
	}
	return error('Asset ${source.str()} not loaded, nothing to unload')
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

const c_embedded_asset_error_blob = $embed_file('../assets/blobs/dead')
const c_embedded_asset_error_image = $embed_file('../assets/images/error.png')
const c_embedded_asset_error_sound = $embed_file('../assets/sfx/error.flac')

pub enum AssetGetStatus {
	error
	ok
}

pub struct AssetRef {
pub:
	asset &Asset
}

pub fn (a &Assets) get_image_no_matter_what(source AssetSource) Image {
	mut sb := unsafe { a.sb }
	source_cache_key := source.cache_key(mut sb)
	if image := a.image_cache[source_cache_key] {
		return image
	}
	return a.error_image
}

pub fn (a &Assets) get[T](source AssetSource) (T, AssetGetStatus) {
	// TODO:  PERFORMANCE: getting anything from a map each frame is currently leaking AF in V
	// This function should do better somehow when compiled with `-gc none` ... :(
	// There's multiple things that suck currently in this whole setup
	// string interpolation in error('${leak}') leaks and `if value := amap[key] {..}` leaks...

	mut sb := unsafe { a.sb }
	source_cache_key := source.cache_key(mut sb)
	$if T is Blob {
		if blob := a.blob_cache[source_cache_key] {
			return blob, AssetGetStatus.ok
		}
		return a.error_blob, AssetGetStatus.error
	} $else $if T is Image {
		if image := a.image_cache[source_cache_key] {
			return image, AssetGetStatus.ok
		}
		return a.error_image, AssetGetStatus.error
	} $else $if T is Sound {
		if sound := a.sound_cache[source_cache_key] {
			return sound, AssetGetStatus.ok
		}
		return a.error_sound, AssetGetStatus.error
	} $else $if T is AssetRef {
		if asset := a.ass[source.str()] {
			return AssetRef{
				asset: asset
			}, AssetGetStatus.ok
		}
		return AssetRef{
			asset: &a.error_asset
		}, AssetGetStatus.error
	}
	// BUG:
	// V BUG galore https://github.com/vlang/v/issues/21594
	// $else $if T is &Asset {
	// 	if asset := a.ass[source.str()] {
	// 		return asset, AssetGetStatus.ok
	// 	}
	// 	return &a.error_asset, AssetGetStatus.error
	// }
	$else {
		$compile_error('Asset.get[T]: only retreival of Blob, Image, Sound and &Asset is currently supported')
	}
	// Should not could be reached:

	// NOTE: Do not use string interpolation in these error returns, they leak with `-gc none`
	// return error('${@STRUCT}.${@FN}: "${source}" is not available in cached data. assets can be loaded and cached with ${@struct}.load(...)') <- no go

	return T{}, AssetGetStatus.error
}

pub fn (mut a Assets) update() {
	analyse.count('${@MOD}.${@STRUCT}.${@FN}()', 1)

	if a.loader.is_working() {
		// mut loops := 0
		for {
			// println('for')
			if job := a.loader.update() {
				// println('Job #${job.id} progress ${job.progress * 100}% status ${job.status}')
				if job.status == .running || job.status == .done {
					source := a.in_progress[u32(job.id)] or { panic('Asset not in progress') }
					assref, status := a.get[AssetRef](source)
					if status == .error {
						panic('Asset not in cache')
					}
					mut asset := assref.asset
					if job.data.size > 0 {
						chunk := job.data.chunk
						size := job.data.size
						for i := 0; i < size; i++ {
							asset.data << chunk[i]
						}
					}
					asset.progress = job.progress
					if job.status == .done {
						$if shy_debug_assets ? {
							a.shy.log.gdebug('${@STRUCT}.${@FN}', 'loaded (asynchronously) "${source}"')
						}
						asset.status = .loaded
					}
				}
			} else {
				// println('for break no job')
				break
			}
			// if loops > a.loader.workers() * 100 {
			// 	println('for break loop limit')
			// 	break
			// }
			// loops++
			// println('for end')
		}
	}

	if a.async_load_queue.len > 0 {
		alo := a.async_load_queue.pop()
		source := alo.source
		mut path := ''
		match source {
			string {
				$if android && !termux {
					if !source.starts_with('/') {
						path = 'file://${source}'
					} else {
						eprintln('${@STRUCT}.${@FN}: error converting "${source}" (Android) to `fetch` compatible source"')
					}
				} $else {
					if os.is_file(source) {
						path = 'file://${source}'
					} else {
						eprintln('${@STRUCT}.${@FN}: error converting "${source}" to `fetch` compatible source"')
					}
				}
			}
			TaggedSource {
				$if android && !termux {
					if !source.str().starts_with('/') {
						path = 'file://${source.str()}'
					} else {
						eprintln('${@STRUCT}.${@FN}: error converting "${source.str()}" (Android) to `fetch` compatible source"')
					}
				} $else {
					if os.is_file(source.str()) {
						path = 'file://${source.str()}'
					} else {
						eprintln('${@STRUCT}.${@FN}: error converting "${source.str()}" to `fetch` compatible source"')
					}
				}
			}
			else {}
		}
		if path != '' {
			// println('loading ${path}')
			handle := a.loader.load(
				url:   path
				flags: .async
			)
			id := u32(handle.id)
			a.in_progress[id] = source

			$if shy_debug_assets ? {
				a.shy.log.gdebug('${@STRUCT}.${@FN}', 'sent off "${path}" to async loading via `shy.fetch`')
			}
		}

		/*
		for i, asset_load_option in a.async_load_queue {
			source := asset_load_option.source
			if asset := a.ass[source.str()] {
				if asset.status != .loading {
					a.async_load_queue.delete(i)
					continue
				}
				a.async_load_tick(asset)
			}
		}*/
	}
}

/*
fn (mut a Assets) async_load_tick(asset &Asset) {
	analyse.count('${@MOD}.${@STRUCT}.${@FN}()', 1)
	assert asset.status == .loading


	// println('asset ${asset}')
}*/

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
pub:
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
			// TODO: V memory leaks '${a.source.str()}#${a.tag}', hence the `sb` :(
			sb.write_string(a.source.str())
			sb.write_string('#')
			sb.write_string(a.tag)
			sb.str()
		}
	}
}

pub fn (a AssetSource) str() string {
	s := match a {
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
	return s
}

pub type AssetOptions = BlobOptions | ImageOptions | SoundOptions

@[flag]
pub enum AssetIOHints {
	async
	stream
	cache
}

pub struct AssetLoadOptions {
pub:
	source AssetSource // BUG: @[required]
	io     AssetIOHints = .cache
}

@[param]
pub struct AssetUnloadOptions {
pub:
	source AssetSource
	// async  bool
	// memory bool = true // Unload from memory
	// cache  bool = true // Unloads from cache
}

// Asset represents a binary blob of data in memory
@[heap]
pub struct Asset {
	ShyStruct
mut:
	data     []u8
	progress f32
pub:
	lo AssetLoadOptions
pub mut:
	status AssetStatus // TODO: (lmp) should be pub read-only to the outside world if V ever gets that access modifier
}

@[manualfree]
pub fn (mut a Asset) shutdown() ! {
	if isnil(a) {
		println('${@LOCATION}: Crashing at hard-to-fix V memory BUG...\nTry using `v -d sdl_memory_no_gc ...`')
	}
	unsafe {
		a.data.free()
	}
	a.status = .freed
	a.ShyStruct.shutdown()!
}

// to converts `Asset`'s `.data` into T and return it.
pub fn (a &Asset) to[T](ao AssetOptions) !T {
	mut muta := unsafe { a }
	$if T is Blob {
		match ao {
			BlobOptions {
				return muta.to_blob(ao)!
			}
			else {
				t := T{}
				return error('${@STRUCT}.${@FN}: could not convert ${typeof(ao).name} "${ao.source}" to ${typeof(t).name}')
			}
		}
	} $else $if T is Image {
		match ao {
			ImageOptions {
				return muta.to_image(ao)!
			}
			else {
				t := T{}
				return error('${@STRUCT}.${@FN}: could not convert ${typeof(ao).name} "${ao.source}" to ${typeof(t).name}')
			}
		}
	} $else $if T is Sound {
		match ao {
			SoundOptions {
				return muta.to_sound(ao)!
			}
			else {
				t := T{}
				return error('${@STRUCT}.${@FN}: could not convert ${typeof(ao).name} "${ao.source}" to ${typeof(t).name}')
			}
		}
	} $else {
		$compile_error('Asset.to[T]: only convertion to Image, Sound and Blob is currently supported')
	}
	// This should never be reached
	t := T{}
	return error('${@STRUCT}.${@FN}: could not convert ${typeof(ao).name} "${ao.source}" to ${typeof(t).name}')
}

// to_blob converts the asset data into a binary Blob
fn (mut a Asset) to_blob(opt BlobOptions) !Blob {
	analyse.count[u64]('${@MOD}.${@STRUCT}.${@FN}()', 1)
	assert !isnil(a.shy), 'Asset struct is not initialized'

	if opt.io.has(.cache) {
		blob, status := a.shy.assets().get[Blob](a.lo.source)
		if status == .ok {
			return blob
		}
	}
	assert a.status == .loaded, '${@STRUCT}.${@FN} Asset is not loaded'
	assert a.data.len > 0, '${@STRUCT}.${@FN} Asset.data appears empty'

	a.shy.log.gdebug('${@STRUCT}.${@FN}', 'converting asset "${a.lo.source}" to binary blob')

	mut blob := Blob{
		asset: a
		opt:   opt
	}

	if opt.io.has(.cache) {
		unsafe {
			mut assets := a.shy.assets()
			// assets.cache[blob](blob)! // TODO
			assets.blob_cache[a.lo.source.cache_key(mut assets.sb)] = blob
		}
	}

	$if shy_debug_assets ? {
		a.shy.log.gdebug('${@STRUCT}.${@FN}', 'converted Asset ("${a.lo.source}") to Blob')
	}

	return blob
}

// to_image converts the asset data into an Image
fn (mut a Asset) to_image(opt ImageOptions) !Image {
	analyse.count[u64]('${@MOD}.${@STRUCT}.${@FN}()', 1)
	assert !isnil(a.shy), 'Asset struct is not initialized'

	if opt.io.has(.cache) {
		image, status := a.shy.assets().get[Image](a.lo.source)
		if status == .ok {
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
	a.shy.log.gdebug('${@STRUCT}.${@FN}', 'loaded asset "${a.lo.source}" via stbi')

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
		asset:   a
		opt:     opt
		width:   stb_img.width
		height:  stb_img.height
		mipmaps: opt.mipmaps
		ready:   stb_img.ok
		kind:    .png // TODO: stb_img.ext
		//
		channels: stb_img.use_channels
	}

	// Sokol image
	// eprintln('\n init sokol image ${img.path} ok=${img.sg_image_ok}')
	mut img_desc := gfx.ImageDesc{
		width:       image.width
		height:      image.height
		num_mipmaps: 0 // TODO: image.mipmaps
		// label: &u8(0)
		pixel_format: .rgba8
	}

	mut smp_desc := gfx.SamplerDesc{
		wrap_u:     opt.wrap_u     // .clamp_to_edge
		wrap_v:     opt.wrap_v     // .clamp_to_edge
		min_filter: opt.min_filter // .linear
		mag_filter: opt.mag_filter // .linear
	}

	// println('${image.width} x ${image.height} x ${image.channels} --- ${a.data.len}')
	// println('${usize(4 * image.width * image.height)} vs ${a.data.len}')
	img_desc.data.subimage[0][0] = gfx.Range{
		ptr:  stb_img.data
		size: usize(4 * image.width * image.height) // NOTE: 4 is not always equal to image.channels count, but sokol_gl contexts expect it
	}

	image.gfx_image = gfx.make_image(&img_desc)
	image.gfx_sampler = gfx.make_sampler(&smp_desc)

	stb_img.free()

	if opt.io.has(.cache) {
		unsafe {
			mut assets := a.shy.assets()
			// assets.cache[Image](image)! // TODO
			assets.image_cache[a.lo.source.cache_key(mut assets.sb)] = image
		}
	}

	$if shy_debug_assets ? {
		a.shy.log.gdebug('${@STRUCT}.${@FN}', 'converted Asset ("${a.lo.source}") to Image')
	}

	return image
}

fn (mut a Asset) to_sound(opt SoundOptions) !Sound {
	analyse.count[u64]('${@MOD}.${@STRUCT}.${@FN}()', 1)
	assert !isnil(a.shy), 'Asset struct is not initialized'
	if opt.io.has(.cache) {
		sound, status := a.shy.assets().get[Sound](a.lo.source)
		if status == .ok {
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
		asset:  a
		id:     id
		id_end: id_end
		loop:   opt.loop
	}
	if opt.io.has(.cache) {
		unsafe {
			mut assets := a.shy.assets()
			assets.sound_cache[a.lo.source.cache_key(mut assets.sb)] = sound
			// assets.cache[Sound](sound)!
		}
	}

	$if shy_debug_assets ? {
		a.shy.log.gdebug('${@STRUCT}.${@FN}', 'converted Asset ("${a.lo.source}") to Sound ${sound.id}')
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
	aspect_fit        // image is scaled uniformly to fit with no cropping into image width and height
	aspect_crop       // image is scaled uniformly to fill image width and height and cropped if necessary
	tile              // image is duplicated horizontally and vertically
	tile_vertically   // image is stretched horizontally and tiled vertically
	tile_horizontally // image is stretched vertically and tiled horizontally
	pad               // image is not transformed, leaving empty space if image width and/or height is > that loaded bitmap width/height
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

@[heap; noinit]
pub struct Blob {
	opt BlobOptions
pub:
	asset &Asset = null // TODO: removing this results in compiler warnings a few places
}

@[params]
pub struct BlobOptions {
	AssetLoadOptions
}

pub fn (b &Blob) as_string() string {
	if b.asset.status != .loaded {
		return ''
	}
	return b.asset.data.bytestr()
}

pub fn (b &Blob) data() []u8 {
	if b.asset.status != .loaded {
		return []u8{}
	}
	return b.asset.data
}

pub fn (mut b Blob) shutdown() ! {}

pub fn (b &Blob) source() AssetSource {
	return b.asset.lo.source
}

@[heap; noinit]
pub struct Image {
	opt ImageOptions
pub:
	asset  &Asset = null // TODO: removing this results in compiler warnings a few places
	width  int
	height int
mut:
	channels int
	ready    bool
	mipmaps  int
	kind     ImageKind
	// Implementation specific
	gfx_image   gfx.Image
	gfx_sampler gfx.Sampler
}

pub type ImageWrap = gfx.Wrap

pub type ImageFilter = gfx.Filter

pub type ResizeValue = Size | f32 | f64

@[params]
pub struct ImageOptions {
	AssetLoadOptions
pub:
	resize     ResizeValue = f32(1.0)
	width      int
	height     int
	mipmaps    int
	wrap_u     ImageWrap   = .clamp_to_edge
	wrap_v     ImageWrap   = .clamp_to_edge
	min_filter ImageFilter = .linear
	mag_filter ImageFilter = .linear
}

//@[params]
// pub struct ImageUnloadOptions {
//	AssetUnloadOptions
// pub:
//	graphics_memory bool
//}

pub fn (mut i Image) shutdown() ! {
	gfx.destroy_image(i.gfx_image)
	gfx.destroy_sampler(i.gfx_sampler)
}

pub fn (i &Image) source() AssetSource {
	return i.asset.lo.source
}

// TODO: rewrite this mess ASAP if you want to support declarative updates (e.g.: s.volume = x)
// sounds should probably go on the heap etc. there needs to be taken some design decisions.

@[markused]
pub const no_sound = Sound{}

@[params]
pub struct SoundOptions {
	AssetLoadOptions
	engine_id u8 // Load sound into this engine
pub:
	loop        bool //
	max_repeats u8
}

@[heap; noinit]
pub struct Sound {
pub:
	asset  &Asset = null // TODO: removing this results in compiler warnings a few places
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
	if s.asset.status != .loaded { // TODO: .streaming???
		$if shy_debug_assets ? {
			s.asset.shy.log.gdebug('${@STRUCT}.${@FN}', 'Sound ${s.id} Asset is not loaded. Sound.asset.status: ${s.asset.status}')
		}
		return
	}
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
		// TODO: this could probably be made smarter
		// TODO: ... Also it is not good for predictability
		aid := s.asset.shy.make_alarm(
			check:     sound_alarm_check
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
	unsafe {
		s.volume = volume
	}
	engine.set_volume(s.id, s.volume)
}

// set_pitch sets the pitch for the `Sound`.
pub fn (s &Sound) set_pitch(pitch f32) {
	engine := s.engine()
	unsafe {
		s.pitch = pitch
	}
	engine.set_pitch(s.id, s.pitch)
}

// is_paused returns true if the sound is paused.
pub fn (s &Sound) is_paused() bool {
	if s.asset.status != .loaded {
		$if shy_debug_assets ? {
			s.asset.shy.log.gdebug('${@STRUCT}.${@FN}', 'Sound ${s.id} Asset is not loaded. Sound.asset.status: ${s.asset.status}')
		}
		return false
	}
	return s.paused
}

// pause pauses the sound.
pub fn (s &Sound) pause(pause bool) {
	assert !isnil(s.asset), 'Sound is not initialized'
	if s.asset.status != .loaded {
		$if shy_debug_assets ? {
			s.asset.shy.log.gdebug('${@STRUCT}.${@FN}', 'Sound ${s.id} Asset is not loaded. Sound.asset.status: ${s.asset.status}')
		}
		return
	}
	engine := s.engine()

	// TODO: doesn't work as expected currently
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
	if s.asset.status != .loaded {
		$if shy_debug_assets ? {
			s.asset.shy.log.gdebug('${@STRUCT}.${@FN}', 'Sound ${s.id} Asset is not loaded. Sound.asset.status: ${s.asset.status}')
		}
		return false
	}
	engine := s.engine()
	id := s.id
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
	if s.asset.status != .loaded {
		$if shy_debug_assets ? {
			s.asset.shy.log.gdebug('${@STRUCT}.${@FN}', 'Sound ${s.id} Asset is not loaded. Sound.asset.status: ${s.asset.status}')
		}
		return false
	}
	engine := s.engine()
	assert !isnil(engine), 'Sound engine is not initialized'
	id := s.id
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
	if s.asset.status != .loaded {
		$if shy_debug_assets ? {
			s.asset.shy.log.gdebug('${@STRUCT}.${@FN}', 'Sound ${s.id} Asset is not loaded. Sound.asset.status: ${s.asset.status}')
		}
		return
	}
	engine := s.engine()
	engine.stop(s.id)
	engine.seek_to_pcm_frame(s.id, 0)
	engine.set_looping(s.id, s.loop)
}
