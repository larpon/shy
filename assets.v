// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module shy

import os
import sokol.gfx
import stbi

pub enum AssetStatus {
	unknown
	error
	loading
	loaded
	streaming
	freed
}

[heap]
pub struct Asset {
	ShyStruct
	data []u8
pub:
	ao     AssetOptions
	status AssetStatus
}

[params]
pub struct AssetOptions {
	uri    string
	async  bool = true
	stream bool
}

pub fn (mut a Asset) to_image(opt ImageOptions) !Image {
	a.shy.log.gdebug('${@STRUCT}.${@FN}', 'converting asset "$a.ao.uri" to image')
	stb_img := stbi.load_from_memory(a.data.data, a.data.len) or {
		return error('${@STRUCT}.${@FN}' + ': stbi failed loading asset "$a.ao.uri"')
	}

	mut image := Image{
		asset: a
		opt: opt
		width: stb_img.width
		height: stb_img.height
		channels: stb_img.nr_channels
		// cache: opt.cache
		ready: stb_img.ok
		// data: stb_img.data
		kind: .png // TODO stb_img.ext
	}

	// Sokol image
	// eprintln('\n init sokol image $img.path ok=$img.sg_image_ok')
	mut img_desc := gfx.ImageDesc{
		width: image.width
		height: image.height
		num_mipmaps: opt.mipmaps
		wrap_u: .clamp_to_edge
		wrap_v: .clamp_to_edge
		label: &u8(0)
		// d3d11_texture: 0
		pixel_format: .rgba8 // C.SG_PIXELFORMAT_RGBA8
	}

	// println('$image.width x $image.height x $image.channels --- $a.data.len')
	img_desc.data.subimage[0][0] = gfx.Range{
		ptr: stb_img.data
		size: usize(4 * image.width * image.height) // TODO 4 is not always equal to image.channels count ?
	}

	image.gfx_image = gfx.make_image(&img_desc)

	stb_img.free()

	return image
}

// TODO free resources etc.
[heap]
pub struct Assets {
	ShyStruct
mut:
	ass map[string]&Asset // Uuuh huh huh, hey Beavis... uhuh huh huh
}

pub fn (mut a Assets) load(ao AssetOptions) !&Asset {
	uri := ao.uri
	if !os.is_file(uri) {
		return error('${@STRUCT}.${@FN}' + ': "$uri" does not exist')
	}
	if _ := a.ass[uri] {
		return error('${@STRUCT}.${@FN}' + ': "$uri" already exist')
	}
	// TODO enable network fetching etc.
	if ao.async {
	}
	bytes := os.read_bytes(uri) or {
		return error('${@STRUCT}.${@FN}' + ': "$uri" could not be loaded')
	}
	// TODO asset pool??
	asset := &Asset{
		shy: a.shy
		data: bytes
		ao: ao
		status: .loaded
	}
	a.shy.log.gdebug('${@STRUCT}.${@FN}', 'loaded "$uri"')
	a.ass[uri] = asset
	return asset
}

pub fn (mut a Assets) get(uri string) !&Asset {
	if asset := a.ass[uri] {
		return asset
	}
	return error('${@STRUCT}.${@FN}' +
		': "$uri" is not available. Assets can be loaded with ${@STRUCT}.load(...)')
}

pub enum ImageKind {
	unknown
	png
	jpeg
}

[heap]
pub struct Image {
	asset &Asset
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

[params]
pub struct ImageOptions {
mut:
	width  int
	height int
	// cache   bool = true
	mipmaps int
}

pub fn (mut i Image) free() {
	unsafe {
		gfx.destroy_image(i.gfx_image)
	}
}
