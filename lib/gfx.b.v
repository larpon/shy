// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module lib

import os.font
import shy.wraps.sokol.gfx
import shy.wraps.sokol.gl

pub struct GFX {
	ShyStruct
mut:
	ready bool
	// TODO render passes
	passes []RenderPass
	// pass RenderPass
	fonts Fonts
}

// Render passes / targets
pub struct RenderPass {
	// label string // TODO probably not necessary?
	pass        gfx.Pass
	pass_action gfx.PassAction
	// pipeline        gfx.Pipeline
	// bindings        gfx.Bindings
}

fn (mut g GFX) init_default_passes() ! {
	// Create a default pass (use window background color)
	color := g.shy.config.window.color.as_f32()
	pass_action := gfx.create_clear_pass(color.r, color.g, color.b, color.a)

	rp := RenderPass{
		// label: 'default'
		pass_action: pass_action
	}
	g.add_pass(rp)
}

pub fn (mut g GFX) add_pass(pass RenderPass) int {
	g.passes << pass
	return g.passes.len - 1
}

pub fn (mut g GFX) make_clear_color_pass_action(color Color) gfx.PassAction {
	c := color.as_f32()
	return gfx.create_clear_pass(c.r, c.g, c.b, c.a)
}

pub fn (mut g GFX) begin_pass(id u16) {
	g.shy.running
	assert g.passes.len > 0, 'no render passes available'

	if p := g.passes[id] {
		// g.pass = p
		// g.shy.log.gdebug('${@STRUCT}.${@FN}', 'setting render pass ${id}:${p.label}')
		if id == 0 {
			// Default pass
			width, height := g.shy.active_window().drawable_wh()
			gfx.begin_default_pass(&p.pass_action, width, height)
		} else {
			gfx.begin_pass(p.pass, &p.pass_action)
			// gfx.apply_pipeline(p.pipeline)
			// gfx.apply_bindings(&p.bindings)
			// gfx.apply_uniforms(.vs, SLOT_vs_params, &SG_RANGE(vs_params))
		}
		return
	}
	assert false, 'no render pass with id ${id} available'
}

pub fn (mut g GFX) init() ! {
	g.shy.assert_api_init()
	mut s := g.shy
	s.log.gdebug('${@STRUCT}.${@FN}', '')
	mut gfx_desc := gfx.Desc{
		shader_pool_size: 4 * 512 // default 32, NOTE this number affects the prealloc_contexts in fonts.b.v...
		context_pool_size: 4 * 512 // default 4, NOTE this number affects the prealloc_contexts in fonts.b.v...
		pipeline_pool_size: 4 * 1024 // default 64, NOTE this number affects the prealloc_contexts in fonts.b.v...
	}
	gfx_desc.context.sample_count = s.config.render.msaa
	gfx.setup(&gfx_desc)
	assert gfx.isvalid()

	g.init_default_passes()!

	g.ready = true
}

pub fn (mut g GFX) subsystem_init() ! {
	// g.shy.assert_api_init()
	mut s := g.shy
	s.log.gdebug('${@STRUCT}.${@FN}', '')

	// sokol_gl is used for all drawing operations in the Easy/Quick app types
	sample_count := g.shy.config.render.msaa
	gl_desc := &gl.Desc{
		// max_vertices: 1_000_000
		// max_commands: 100_000
		context_pool_size: 2 * 512 // TODO default 4, NOTE this number affects the prealloc_contexts in fonts.b.v...
		pipeline_pool_size: 2 * 1024 // TODO default 4, NOTE this number affects the prealloc_contexts in fonts.b.v...
		sample_count: sample_count
	}
	gl.setup(gl_desc)

	// TODO Initialize font drawing sub system
	mut preload_fonts := map[string]string{}
	$if !wasm32_emscripten {
		preload_fonts['system'] = font.default()
	}

	g.fonts.init(FontsConfig{
		shy: g.shy
		// prealloc_contexts: 8
		preload: preload_fonts
		render: g.shy.config.render
	})! // fonts.b.v
}

pub fn (mut g GFX) subsystem_shutdown() ! {
	// g.shy.assert_api_init()
	mut s := g.shy
	s.log.gdebug('${@STRUCT}.${@FN}', '')
	g.fonts.shutdown()!
	gl.shutdown()
}

pub fn (mut g GFX) shutdown() ! {
	g.shy.assert_api_shutdown()
	g.ready = false
	gfx.shutdown()
}

pub fn (g GFX) commit() {
	gfx.commit()
}

pub fn (mut g GFX) end_pass() {
	g.fonts.on_frame_end()
	gl.draw()
	gfx.end_pass()
}
