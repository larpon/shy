// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module lib

import os.font
import shy.wraps.sokol.gfx
import shy.wraps.sokol.gl
import shy.wraps.sokol.sfons

pub struct GFX {
	ShyStruct
mut:
	ready bool
	// TODO render passes
	passes []RenderPass
	// pass RenderPass
	fonts Fonts
pub mut:
	// sokol_gl contexts
	gfx_contexts map[u32]gfx.Context
	sgl_contexts map[u32]gl.Context
	//
	font_contexts map[u32]&FontContext
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
	panic('no render pass with id ${id} available')
}

pub fn (mut g GFX) init() ! {
	g.shy.assert_api_init()
	mut s := g.shy
	s.log.gdebug('${@STRUCT}.${@FN}', '')
	mut gfx_desc := gfx.Desc{
		// shader_pool_size: 4 * 512 // default 32, NOTE this number affects the prealloc_contexts in fonts.b.v...
		// context_pool_size: 4 * 512 // default 4, NOTE this number affects the prealloc_contexts in fonts.b.v...
		// pipeline_pool_size: 4 * 1024 // default 64, NOTE this number affects the prealloc_contexts in fonts.b.v...
	}
	gfx_desc.context.sample_count = s.config.render.msaa
	gfx.setup(&gfx_desc)

	assert gfx.isvalid()

	g.init_default_passes()!

	g.ready = true
}

pub fn (g &GFX) activate_context(id u32) {
	if ctx := g.gfx_contexts[id] {
		gfx.activate_context(ctx)
		return
	}
	panic('no gfx context ${id} found')
}

pub fn (mut g GFX) init_context(id u32) ! {
	g.gfx_contexts[id] = gfx.setup_context()
}

pub fn (mut g GFX) shutdown_context(id u32) ! {
	if ctx := g.gfx_contexts[id] {
		g.activate_context(id)
		gfx.discard_context(ctx)
		g.gfx_contexts.delete(id)
		return
	}
	panic('no gfx context ${id} found')
}

pub fn (mut g GFX) subsystem_gl_init(id u32) ! {
	// sokol_gl is used for all drawing operations in the easy/quick app types
	sample_count := g.shy.config.render.msaa
	gl_desc := &gl.Desc{
		// max_vertices: 1_000_000
		// max_commands: 100_000
		context_pool_size: 2 * 512 // todo default 4, note this number affects the prealloc_contexts in fonts.b.v...
		pipeline_pool_size: 2 * 1024 // todo default 4, note this number affects the prealloc_contexts in fonts.b.v...
		sample_count: sample_count
	}
	gl.setup(gl_desc)
}

pub fn (mut g GFX) subsystem_gl_shutdown(id u32) ! {
	gl.shutdown() // NOTE this is currently a mystery, we may leak something here - but we get context mismatch errors otherwise :(
}

pub fn (g &GFX) activate_subsystem_context(id u32) {
	if ctx := g.sgl_contexts[id] {
		gl.set_context(ctx)
		return
	}
	panic('no sgl context ${id} found')
}

pub fn (mut g GFX) subsystem_init(id u32) ! {
	// g.shy.assert_api_init()
	mut s := g.shy
	s.log.gdebug('${@STRUCT}.${@FN}', '')

	sgl_ctx_desc := gl.ContextDesc{
		// max_vertices: ...        // default: 64k
		// max_commands: ...        // default: 16k
		// color_format: .rgba8
		// depth_format: .@none
		sample_count: s.config.render.msaa
	}
	sgl_ctx := gl.make_context(sgl_ctx_desc)
	g.sgl_contexts[id] = sgl_ctx
	gl.set_context(sgl_ctx)
	// g.activate_subsystem_context(id)

	// TODO Initialize font drawing sub system
	mut preload_fonts := map[string]string{}
	$if !wasm32_emscripten {
		preload_fonts['system'] = font.default()
	}

	font_context := g.fonts.new_context(FontsConfig{
		shy: g.shy
		// prealloc_contexts: 8
		preload: preload_fonts
		render: g.shy.config.render
	})! // fonts.b.v
	s.log.gdebug('${@STRUCT}.${@FN}', 'adding font context for ${id} ${ptr_str(font_context.fsc)}...')
	g.font_contexts[id] = font_context
}

pub fn (mut g GFX) subsystem_shutdown(id u32) ! {
	// g.shy.assert_api_init()
	mut s := g.shy
	s.log.gdebug('${@STRUCT}.${@FN}', '')
	if ctx := g.sgl_contexts[id] {
		gl.set_context(ctx)

		for _, context in g.font_contexts {
			if !isnil(context.fsc) {
				s.log.gdebug('${@STRUCT}.${@FN}', 'destroying font context ${ptr_str(context.fsc)}...')
				sfons.destroy(context.fsc)
				unsafe {
					context.fsc = nil
				}
			}
		}

		gl.destroy_context(ctx)
		g.sgl_contexts.delete(id)
		return
	}
	panic('no gfx context ${id} found')
}

pub fn (mut g GFX) shutdown() ! {
	g.shy.assert_api_shutdown()
	g.ready = false

	g.fonts.shutdown()!
	// TODO horrible workaround some sokol assertion (bug?) caused by sokol_gl, when using sokol_gfx contexts:
	// _sg_uninit_buffer: active context mismatch (must be same as for creation)
	// .../sokol_gfx.h:16213: sg_destroy_buffer: Assertion `buf->slot.state == SG_RESOURCESTATE_ALLOC' failed.
	/*
	gfx.shutdown()
	mut gfx_desc := gfx.Desc{}
	gfx_desc.context.sample_count = g.shy.config.render.msaa
	gfx.setup(&gfx_desc)

	gl.set_context(gl.default_context)
	gl.shutdown() // NOTE this is currently a mystery, we may leak something here - but we get context mismatch errors otherwise :(
	*/
	gfx.shutdown()
}

pub fn (g GFX) commit() {
	gfx.commit()
}

pub fn (mut g GFX) end_pass() {
	for _, mut fc in g.font_contexts {
		if fc.in_use {
			sfons.flush(fc.fsc)
			fc.in_use = false
			// FLOOD fs.shy.log.gdebug('${@STRUCT}.${@FN}', 'handing out ${ptr_str(fc.fsc)}...')
		}
	}
	// g.fonts.on_frame_end()
	gl.draw()
	gfx.end_pass()
}

pub fn (mut g GFX) get_font_context(id u32) &FontContext {
	if ctx := g.font_contexts[id] {
		if !ctx.in_use {
			unsafe {
				ctx.in_use = true
			}
			return ctx
		}
		return ctx
	}
	panic('no font context ${id} found')
}
