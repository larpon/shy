// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module lib

import shy.wraps.sokol.gl
import shy.wraps.sokol.gfx

[heap]
pub struct Draw {
	ShyStruct
mut:
	alpha_pipeline gl.Pipeline
	viewport       Rect
	scissor_rect   Rect
	canvas         Canvas
}

pub fn (mut d Draw) init() ! {
	d.ShyStruct.init()!
	d.shy.log.gdebug('${@STRUCT}.${@FN}', '')

	win := d.shy.active_window()
	d.set_canvas(win.canvas()) // Set initial canvas

	// Make a sokol-gl pipeline with alpha blending enabled (used by DrawImage for alpha blending textures)
	mut alpha_pipdesc := gfx.PipelineDesc{}
	unsafe { vmemset(&alpha_pipdesc, 0, int(sizeof(alpha_pipdesc))) }
	alpha_pipdesc.label = c'alpha-pipeline'

	alpha_pipdesc.depth = gfx.DepthState{
		pixel_format: .@none // .depth // .rgba8 //.@none // rgba8
		write_enabled: true
		// compare: .less_equal
	}
	alpha_pipdesc.colors[0] = gfx.ColorState{
		blend: gfx.BlendState{
			enabled: true
			src_factor_rgb: .src_alpha
			dst_factor_rgb: .one_minus_src_alpha
		}
	}

	c := d.shy.api.gfx.get_active_context()
	off := c.offscreen
	d.alpha_pipeline = gl.context_make_pipeline(off.gl_ctx, &alpha_pipdesc)
}

// pub fn (mut d Draw) reset() ! {
//	d.shy.log.gdebug('${@STRUCT}.${@FN}', '')
//}

pub fn (mut d Draw) shutdown() ! {
	d.shy.log.gdebug('${@STRUCT}.${@FN}', '')
	gl.destroy_pipeline(d.alpha_pipeline)
	d.ShyStruct.shutdown()!
}

pub fn (mut d Draw) begin_2d() {
	// Keep around for while:
	// unsafe { di.shy.api.draw.layer++ }
	// gl.set_context(gl.default_context)
	// gl.layer(di.shy.api.draw.layer)

	gl.defaults()

	// According to sokol_gfx.h documentation the viewport and scissor rects are reset
	// to the size of the full framebuffer - so we can assume that here:
	d.set_viewport(d.canvas.rect())
	d.set_scissor_rect(d.viewport)

	// gl.set_context(s_gl_context)
	gl.matrix_mode_projection()
	gl.ortho(0.0, d.canvas.width, d.canvas.height, 0.0, -1.0, 1.0)

	gl.load_pipeline(d.alpha_pipeline)
}

pub fn (d &Draw) end_2d() {}

pub fn (mut d Draw) set_canvas(canvas Canvas) {
	d.canvas = canvas
}

pub fn (d &Draw) set_viewport(rect Rect) {
	gl.viewportf(rect.x, rect.y, rect.width, rect.height, true)
	unsafe {
		d.viewport = rect
	}
}

pub fn (d &Draw) set_scissor_rect(rect Rect) {
	gl.scissor_rectf(rect.x, rect.y, rect.width, rect.height, true)
	unsafe {
		d.scissor_rect = rect
	}
}

pub fn (d &Draw) push_matrix() {
	gl.push_matrix()
}

pub fn (d &Draw) pop_matrix() {
	gl.pop_matrix()
}

pub fn (d &Draw) translate(x f32, y f32, z f32) {
	gl.translate(x, y, z)
}

pub fn (d &Draw) rotate(angle_rad f32, x f32, y f32, z f32) {
	gl.rotate(angle_rad, x, y, z)
}

pub fn (d &Draw) scale(x f32, y f32, z f32) {
	gl.scale(x, y, z)
}
