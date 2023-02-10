// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module lib

// import os
import sdl
import stbi
import shy.analyse

fn (mut a Asset) to_sdl_surface(opt ImageOptions) !&sdl.Surface {
	analyse.count[u64]('${@MOD}.${@STRUCT}.${@FN}()', 1)
	assert !isnil(a.shy), 'Asset struct is not initialized'

	// TODO
	// 	if opt.cache {
	// 		if image := a.shy.assets().get[Image](a.lo.source) {
	// 			return image
	// 		}
	// 	}
	assert a.status == .loaded, 'Asset is not loaded'
	assert a.data.len > 0, 'Asset.data appears empty'

	a.shy.log.gdebug('${@STRUCT}.${@FN}', 'converting asset "${a.lo.source}" to &sdl.Surface')
	stb_img := stbi.load_from_memory(a.data.data, a.data.len) or {
		return error('${@STRUCT}.${@FN}' + ': stbi failed loading asset "${a.lo.source}"')
	}

	// mut surf := sdl.Surface(0)

	// SDL 2.0.5 introduced SDL_CreateRGBSurfaceWithFormatFrom() and SDL_PIXELFORMAT_RGBA32
	// which makes this code much simpler.

	// TODO everything is loaded to fit sokol's rgba8 pixel format
	// So vlib's stbi format is currently always C.STBI_rgb_alpha
	format := unsafe { u32(sdl.Format.rgba32) }
	// format := if image.pixel_format == .rgba { sdl.Format.rgb24 } else { sdl.Format.rgba32 }
	stb_img_format := int(C.STBI_rgb_alpha) // TODO *YUK*
	depth := stb_img_format * 8
	pitch := stb_img_format * stb_img.width

	mut surf := sdl.create_rgb_surface_with_format_from(stb_img.data, stb_img.width, stb_img.height,
		depth, pitch, format)

	if surf == sdl.null {
		// hopefully SDL_CreateRGBSurfaceFrom() has set an sdl error
		sdl_error_msg := unsafe { cstring_to_vstring(sdl.get_error()) }
		a.shy.log.gerror('${@STRUCT}.${@FN}', 'SDL: ${sdl_error_msg}')
		return error('Could not create sdl.Surface from "${a.lo.source}", SDL says:\n${sdl_error_msg}')
	}

	stb_img.free()
	/*
	if(freeWithSurface)
	{
		// SDL_Surface::flags is documented to be read-only.. but if the pixeldata
		// has been allocated with SDL_malloc()/SDL_calloc()/SDL_realloc() this
		// should work (and it currently does) + @icculus said it's reasonably safe:
		//  https://twitter.com/icculus/status/667036586610139137 :-)
		// clear the SDL_PREALLOC flag, so SDL_FreeSurface() free()s the data passed from img.data
		surf->flags &= ~SDL_PREALLOC;
	}
	*/

	/*
	mut image := Image{
		asset: a
		opt: opt
		width: stb_img.width
		height: stb_img.height
		channels: stb_img.nr_channels
		mipmaps: opt.mipmaps
		ready: stb_img.ok
		// data: stb_img.data
		kind: .png // TODO stb_img.ext
	}*/

	// 	if opt.cache {
	// 		unsafe {
	// 			mut assets := a.shy.assets()
	// 			// assets.cache[Image](image)! // TODO
	// 			assets.image_cache[a.lo.source.str()] = image
	// 		}
	// 	}
	return surf
}
