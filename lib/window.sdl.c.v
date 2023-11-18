// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module lib

import os
import shy.wraps.stbi

#include "@VMODROOT/lib/shy_gl_read_pixels.h"

// shy_gl_read_rgba_pixels reads pixles from the current OpenGL context buffer into `pixels`.
fn C.shy_gl_read_rgba_pixels(x int, y int, width int, height int, pixels charptr)

// screenshot takes a screenshot of the current window and
// saves it to `path`. The format is inferred from the extension
// of the file name in `path`.
//
// Supported formats are: `.png`, `.ppm`.
pub fn (w Window) screenshot(path string) ! {
	area := Rect{
		x: 0
		y: 0
		width: w.width()
		height: w.height()
	}
	return w.areashot(area, path)
}

pub fn (w Window) areashot(area Rect, path string) ! {
	dir := os.dir(path)
	if !os.is_dir(dir) {
		os.mkdir_all(dir) or { return error('${@MOD}.${@STRUCT}.${@FN}: ${err}') }
	}
	match os.file_ext(path) {
		'.png' {
			return w.areashot_png(area, path)
		}
		'.ppm' {
			return w.areashot_ppm(area, path)
		}
		else {
			return error('${@MOD}.${@STRUCT}.${@FN} currently only supports .png and .ppm files.')
		}
	}
}

// areashot_ppm takes a screenshot of the current window and
// saves it to `path` as a .ppm file.
@[manualfree]
fn (w Window) areashot_ppm(area Rect, path string) ! {
	ss := w.dump_pixels(area)
	defer {
		unsafe { ss.destroy() }
	}
	write_rgba_to_ppm(path, ss.width, ss.height, 4, ss.pixels) or {
		return error('${@MOD}.${@STRUCT}.${@FN}: ${err}')
	}
}

// areashot_png takes a screenshot of the current window and
// saves it to `path` as a .png file.
@[manualfree]
fn (w Window) areashot_png(area Rect, path string) ! {
	ss := w.dump_pixels(area)
	defer {
		unsafe { ss.destroy() }
	}
	stbi.set_flip_vertically_on_write(true)
	stbi.stbi_write_png(path, ss.width, ss.height, 4, ss.pixels, ss.width * 4) or {
		return error('${@MOD}.${@STRUCT}.${@FN}: ${err}')
	}
}

// write_rgba_to_ppm writes `pixels` data in RGBA format to PPM3 format.
fn write_rgba_to_ppm(path string, w int, h int, components int, pixels &u8) ! {
	mut f_out := os.create(path)!
	defer {
		f_out.close()
	}
	f_out.writeln('P3')!
	f_out.writeln('${w} ${h}')!
	f_out.writeln('255')!
	for i := h - 1; i >= 0; i-- {
		for j := 0; j < w; j++ {
			idx := i * w * components + j * components
			unsafe {
				r := int(pixels[idx])
				g := int(pixels[idx + 1])
				b := int(pixels[idx + 2])
				f_out.write_string('${r} ${g} ${b} ')!
			}
		}
	}
}

@[heap]
struct Screenshot {
	width  int
	height int
	size   int
mut:
	pixels &u8 = unsafe { nil }
}

@[manualfree]
fn (w Window) dump_pixels(rect Rect) &Screenshot {
	img_width := int(rect.width)
	img_height := int(rect.height)
	img_size := img_width * img_height * 4
	img_pixels := unsafe { &u8(malloc(img_size)) }
	C.shy_gl_read_rgba_pixels(rect.x, rect.y, img_width, img_height, img_pixels)
	return &Screenshot{
		width: img_width
		height: img_height
		size: img_size
		pixels: img_pixels
	}
}

// free - free *only* the Screenshot pixels.
@[unsafe]
pub fn (mut ss Screenshot) free() {
	unsafe {
		shy_free(ss.pixels)
		ss.pixels = &u8(0)
	}
}

// destroy - free the Screenshot pixels,
// then free the screenshot data structure itself.
@[unsafe]
pub fn (mut ss Screenshot) destroy() {
	unsafe { ss.free() }
	unsafe { shy_free(ss) }
}
