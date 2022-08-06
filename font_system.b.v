// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module solid

import os
import os.font
import fontstash
import sokol.sfons
import sokol.sgl

struct FontSystem {
mut:
	solid        &Solid
	context      &fontstash.Context
	default_font int // ID of the default font
}

fn (mut fs FontSystem) init(solid &Solid) {
	fs.solid = solid
	mut s := fs.solid
	s.log.ginfo(@STRUCT + '.' + 'init', 'initializing...')
	font_context := sfons.create(512, 512, 1)
	s.backend.font_system.context = font_context
	font_path := font.default()
	if bytes := os.read_bytes(font.default()) {
		s.backend.font_system.default_font = font_context.add_font_mem('sans', bytes,
			false)
		s.log.ginfo(@STRUCT + '.' + 'font', 'loaded: $font_path')
	}
}

fn (mut fs FontSystem) shutdown() {
	sfons.destroy(fs.context)
	// sfons.shutdown()
}

fn (fs FontSystem) scope_open() {
	font_context := fs.context

	font_context.clear_state()
	sgl.defaults()
	sgl.matrix_mode_projection()

	win_width, win_height := fs.solid.window().size()

	sgl.ortho(0.0, f32(win_width), f32(win_height), 0.0, -1.0, 1.0)
}

fn (fs FontSystem) scope_close() {
	font_context := fs.context
	sfons.flush(font_context)
	sgl.draw()
}

fn (fs FontSystem) draw_text_at(text string, x int, y int) {
	font_context := fs.context

	white := sfons.rgba(255, 255, 255, 255)

	font_context.set_font(fs.default_font)
	font_context.set_color(white)
	font_context.set_size(16.0)

	// x =
	font_context.draw_text(x, y, text)
}
