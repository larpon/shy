// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module lib

import os.font
// import math
import shy.wraps.sokol.gfx
import shy.wraps.sokol.gl
import shy.wraps.sokol.sfons

pub struct GFX {
	ShyStruct
mut:
	ready          bool
	fonts          Fonts
	active_context u32
	contexts       []&Context
}

pub struct Context {
	ShyStruct
	id u32
mut:
	// sokol_* contexts
	gfx  gfx.Context
	font &FontContext = unsafe { nil }
	// Used by the Easy/Quick sub-system
	display   Display
	offscreen Offscreen
}

struct Offscreen {
mut:
	width       int
	height      int
	pass        gfx.Pass
	pass_desc   gfx.PassDesc
	pass_action gfx.PassAction
	img         gfx.Image
	gl_ctx      gl.Context
}

fn (o Offscreen) destroy() {
	gfx.destroy_image(o.img)
	gfx.destroy_pass(o.pass)
	gl.destroy_context(o.gl_ctx)
}

struct Display {
mut:
	pass_action gfx.PassAction
	gl_pip      gl.Pipeline
}

fn (d Display) destroy() {
	gl.destroy_pipeline(d.gl_pip)
}

pub fn (mut g GFX) make_clear_color_pass_action(color Color) gfx.PassAction {
	c := color.as_f32()
	return gfx.create_clear_pass(c.r, c.g, c.b, c.a)
}

pub fn (mut g GFX) init() ! {
	// g.shy.assert_api_init()
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

	g.ready = true
}

pub fn (mut g GFX) shutdown() ! {
	// g.shy.assert_api_shutdown() // TODO
	g.ready = false

	g.fonts.shutdown()!
	// TODO horrible workaround some sokol assertion (bug?) caused by sokol_gl, when using >1 sokol_gfx contexts:
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

pub fn (g &GFX) get_active_context() &Context {
	if ctx := g.contexts[g.active_context] {
		return ctx
	}
	panic('no active gfx context ${g.active_context} found')
}

pub fn (g &GFX) get_context(cid u32) &Context {
	if ctx := g.contexts[cid] {
		return ctx
	}
	panic('no gfx context ${cid} found')
}

pub fn (mut g GFX) activate_context(cid u32) {
	ctx := g.get_context(cid)
	gfx.activate_context(ctx.gfx)
	g.active_context = cid
}

pub fn (mut g GFX) make_context() !u32 {
	context_id := u32(g.contexts.len)

	sokol_gfx_context := gfx.setup_context()
	gfx.activate_context(sokol_gfx_context)

	mut context := &Context{
		shy: g.shy
		id: context_id
		gfx: sokol_gfx_context
	}

	context.init()!

	g.contexts << context
	return context_id
}

pub fn (mut g GFX) shutdown_context(cid u32) ! {
	mut ctx := g.get_context(cid)
	g.activate_context(cid)
	unsafe { ctx.shutdown()! } // TODO
}

pub fn (mut c Context) init() ! {
	// c.shy.assert_api_init() // TODO

	mut s := c.shy
	s.log.gdebug('${@STRUCT}.${@FN}', '')

	c.sokol_gl_init()!

	offscreen := c.offscreen
	gl_ctx := offscreen.gl_ctx
	gl.set_context(gl_ctx)

	// TODO Initialize font drawing sub system
	mut preload_fonts := map[string]string{}
	$if !wasm32_emscripten {
		preload_fonts['system'] = font.default()
	}

	font_context := s.api.gfx.fonts.new_context(FontsConfig{
		shy: c.shy
		// prealloc_contexts: 8
		preload: preload_fonts
		render: c.shy.config.render
	})! // fonts.b.v
	s.log.gdebug('${@STRUCT}.${@FN}', 'adding font context for GFX context ${c.id} ${ptr_str(font_context.fsc)}...')
	c.font = font_context

	gl.set_context(gl.default_context)
}

fn (mut c Context) sokol_gl_init() ! {
	// sokol_gl is used for all drawing operations in the easy/quick app types
	sample_count := c.shy.config.render.msaa

	offscreen_sample_count := 1

	win := c.shy.active_window()
	w, h := win.drawable_wh()

	gl_desc := &gl.Desc{
		// max_vertices: 1_000_000
		// max_commands: 100_000
		context_pool_size: 2 * 512 // TODO default 4, note this number affects the prealloc_contexts in fonts.b.v...
		pipeline_pool_size: 2 * 1024 // TODO default 4, note this number affects the prealloc_contexts in fonts.b.v...
		sample_count: sample_count
	}
	gl.setup(gl_desc)

	// pass action and pipeline for the default render pass
	mut gl_pip_desc := gfx.PipelineDesc{
		cull_mode: .back
		depth: gfx.DepthState{
			write_enabled: true
			compare: .less_equal
		}
	}

	display := Display{
		pass_action: gfx.create_clear_pass(0.5, 0.7, 1.0, 1.0)
		gl_pip: gl.context_make_pipeline(gl.default_context, &gl_pip_desc)
	}

	// create a sokol-gl context compatible with the offscreen render pass
	// (specific color pixel format, no depth-stencil-surface, no MSAA)
	gl_ctx_desc := gl.ContextDesc{
		// max_vertices: 8
		// max_commands: 4
		color_format: .rgba8
		depth_format: .@none
		sample_count: offscreen_sample_count
	}

	// create an offscreen render target texture, pass, and pass_action
	mut img_desc := gfx.ImageDesc{
		render_target: true
		width: w
		height: h
		pixel_format: .rgba8
		sample_count: offscreen_sample_count
		wrap_u: .clamp_to_edge
		wrap_v: .clamp_to_edge
		min_filter: .nearest
		mag_filter: .nearest
	}
	off_img := gfx.make_image(&img_desc)

	mut off_pass_desc := gfx.PassDesc{}
	off_pass_desc.color_attachments[0].image = off_img

	offscreen := Offscreen{
		width: w
		height: h
		pass: gfx.make_pass(&off_pass_desc)
		pass_action: gfx.create_clear_pass(0.0, 0.0, 0.0, 1.0)
		pass_desc: off_pass_desc
		gl_ctx: gl.make_context(gl_ctx_desc)
		img: off_img
	}

	c.display = display
	c.offscreen = offscreen
}

fn (mut c Context) offscreen_reinit(width int, height int) ! {
	offscreen_sample_count := 1

	gfx.destroy_pass(c.offscreen.pass)
	gfx.destroy_image(c.offscreen.pass_desc.color_attachments[0].image)
	// recreate an offscreen render target texture, pass, and pass_action
	mut img_desc := gfx.ImageDesc{
		render_target: true
		width: width
		height: height
		pixel_format: .rgba8
		sample_count: offscreen_sample_count
		wrap_u: .clamp_to_edge
		wrap_v: .clamp_to_edge
		min_filter: .nearest
		mag_filter: .nearest
	}
	off_img := gfx.make_image(&img_desc)

	mut off_pass_desc := gfx.PassDesc{}
	off_pass_desc.color_attachments[0].image = off_img

	c.offscreen.width = width
	c.offscreen.height = height
	c.offscreen.pass = gfx.make_pass(&off_pass_desc)
	c.offscreen.pass_desc = off_pass_desc
	c.offscreen.img = off_img
}

[manualfree]
pub fn (mut c Context) shutdown() ! {
	// g.shy.assert_api_init()
	mut s := c.shy
	s.log.gdebug('${@STRUCT}.${@FN}', '')

	off := c.offscreen
	ctx := off.gl_ctx
	gl.set_context(ctx)

	font_context := c.font
	if !isnil(font_context.fsc) {
		s.log.gdebug('${@STRUCT}.${@FN}', 'destroying font context ${ptr_str(font_context.fsc)}...')
		sfons.destroy(font_context.fsc)
		unsafe {
			font_context.fsc = nil
		}
	}
	unsafe {
		free(c.font)
		c.font = nil
	}
	off.destroy()
	c.display.destroy()

	gl.shutdown()

	gfx.discard_context(c.gfx)
}

pub fn (g GFX) commit() {
	gfx.commit()
}

pub fn (mut g GFX) begin_easy_frame() {
	c := g.get_active_context()
	off := c.offscreen
	gl.set_context(off.gl_ctx)

	// Reinit offscreen pass if necessary
	// TODO make nicer
	win := g.shy.active_window()
	w, h := win.drawable_wh()
	if off.width != w || off.height != h {
		mut mc := unsafe { g.get_active_context() }
		mc.offscreen_reinit(w, h) or { panic(err) }
	}
}

pub fn (mut g GFX) end_easy_frame() {
	win := g.shy.active_window()
	w, h := win.drawable_wh()

	c := g.get_active_context()
	off := c.offscreen
	dis := c.display

	// draw, using the offscreen render target as texture
	gl.set_context(gl.default_context)
	gl.defaults()
	gl.enable_texture()
	gl.texture(off.img)
	gl.load_pipeline(dis.gl_pip)

	/*
	// 3D plane version
	gl.matrix_mode_projection()
	gl.perspective(gl.rad(25.0), w / h, 0.1, 100.0)
	r:=45*lib.deg2rad
	eye_0 := math.sinf(r) * 6.0
	eye_1 := math.sinf(r) * 3.0
	eye_2 := math.cosf(r) * 6.0

	gl.matrix_mode_modelview()
	gl.lookat(eye_0, eye_1, eye_2, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0)

	gl.push_matrix()
	gl.c4b(255, 255, 255, 255)
	g.draw_3d_plane()
	gl.pop_matrix()
	*/

	// Flat 2D version
	gl.matrix_mode_projection()
	gl.ortho(0.0, w, h, 0.0, -1.0, 1.0)

	gl.push_matrix()

	// gl.scale(2.5, 2.5, 1)

	gl.c4b(255, 255, 255, 255)
	g.draw_flipped_textured_plane(0, 0, w, h)
	gl.pop_matrix()

	gl.disable_texture()

	// do the actual offscreen and display rendering in sokol-gfx passes
	gfx.begin_pass(off.pass, &off.pass_action)
	// Alternative: gl.context_draw(off.gl_ctx)
	gl.set_context(off.gl_ctx)
	gl.draw()
	gfx.end_pass()

	gfx.begin_default_pass(&dis.pass_action, int(w), int(h))
	// Alternative: gl.context_draw(gl.default_context)
	gl.set_context(gl.default_context)
	gl.draw()

	// End the pass for the whole GFX system
	g.end_pass()
}

fn (g &GFX) draw_flipped_textured_plane(x f32, y f32, w f32, h f32) {
	mut u0 := f32(0.0)
	mut v0 := f32(0.0)
	mut u1 := f32(1.0)
	mut v1 := f32(1.0)
	x0 := f32(x) // 0
	y0 := f32(y) // 0
	x1 := f32(w)
	y1 := f32(h)

	// println(h)

	gl.begin_quads()
	gl.v2f_t2f(x0, y1, u0, v0) // bottom-left x,y   top-left u,v    notice the coord flip
	gl.v2f_t2f(x1, y1, u1, v0) // bottom-right x,y
	gl.v2f_t2f(x1, y0, u1, v1) // top-right x,y
	gl.v2f_t2f(x0, y0, u0, v1) // top-left x,y
	gl.end()
}

fn (g &GFX) draw_3d_plane() {
	gl.begin_quads()
	gl.v3f_t2f(-1.0, -1.0, 1.0, 0.0, 0.0)
	gl.v3f_t2f(1.0, -1.0, 1.0, 1.0, 0.0)
	gl.v3f_t2f(1.0, 1.0, 1.0, 1.0, 1.0)
	gl.v3f_t2f(-1.0, 1.0, 1.0, 0.0, 1.0)
	gl.end()
}

pub fn (mut g GFX) end_pass() {
	mut c := g.get_active_context()
	if c.font.in_use {
		sfons.flush(c.font.fsc)
		c.font.in_use = false
		// eprintln('Fonts in ${c.id} marked NOT in use')
		// FLOOD fs.shy.log.gdebug('${@STRUCT}.${@FN}', 'handing out ${ptr_str(fc.fsc)}...')
	}
	gfx.end_pass()
}

pub fn (mut g GFX) get_font_context(cid u32) &FontContext {
	if mut ctx := g.contexts[cid] {
		if !ctx.font.in_use {
			unsafe {
				ctx.font.in_use = true
				// eprintln('Fonts in ${cid} marked in use')
			}
		}
		return ctx.font
	}
	panic('no font context in context ${cid} found')
}
