// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module solid

// Some code found from
// "Minimal sprite rendering example with SDL2 for windowing, sokol_gfx for graphics API using OpenGL 3.3 on MacOS"
// https://gist.github.com/sherjilozair/c0fa81250c1b8f5e4234b1588e755bca
import os.font
import sdl
import sdl.ttf
import sokol.gfx

// Use `v shader` or `sokol-shdc` to generate the necessary `.h` file
// Using `v shader -v .` in this directory will show some additional
// info - and what you should include to make things work.
#flag -I @VMODROOT/.
#include "simple_shader.h"

// simple_shader_desc is a C function declaration defined by
// the `@program` entry in the `simple_shader.glsl` shader file.
// When the shader is compiled this function name is generated
// by the shader compiler for easier inclusion of universal shader code
// in C (and V) code.
fn C.simple_shader_desc(gfx.Backend) &gfx.ShaderDesc

// Vertex_t makes it possible to model vertex buffer data
// for use with the shader system
struct Vertex_t {
	// Position
	x f32
	y f32
	z f32
	// Color
	r f32
	g f32
	b f32
	a f32
}

pub fn (s Solid) performance_counter() u64 {
	return sdl.get_performance_counter()
}

pub fn (s Solid) performance_frequency() u64 {
	return sdl.get_performance_frequency()
}

pub fn (s Solid) clear_screen() {
	// sdl.set_render_draw_color(s.backend.renderer, 49, 54, 59, 255)
	// sdl.render_clear(s.backend.renderer)
	pass_action := gfx.create_clear_pass(0.0, 0.0, 0.0, 1.0) // This will create a black color as a default pass (window background color)
	// gfx.PassAction{}
	w, h := s.backend.get_drawable_size()
	gfx.begin_default_pass(&pass_action, w, h)
}

pub fn (s Solid) display() {
	gfx.apply_pipeline(s.backend.shader_pipeline)
	gfx.apply_bindings(&s.backend.bind)

	gfx.draw(0, 3, 1)
	gfx.end_pass()
	gfx.commit()

	sdl.gl_swap_window(s.backend.window)
	// sdl.render_present(s.backend.renderer)
}

pub fn (mut s Solid) init() {
	s.log.gdebug(@STRUCT + '.' + 'lifecycle', @FN + ' called')
	$if linux {
		// Experiments
		// sdl.set_hint(sdl.hint_render_vsync.str,'1'.str)
		// sdl.set_hint(sdl.hint_video_x11_xrandr.str,'1'.str)
	}

	// SDL debug info, must be called before sdl.init
	// sdl.log_set_all_priority(sdl.LogPriority.debug)

	init_flags := u32(sdl.init_video | sdl.init_gamecontroller | sdl.init_haptic)
	// init_flags := u32(sdl.init_everything)
	sdl.init(init_flags)
	ttf.init()

	mx, my := s.global_mouse_pos()

	mut display_index := 0

	displays := solid.display_count()

	// eprintln('Displays: $displays')
	// get display bounds for all displays
	mut display_bounds := []sdl.Rect{}
	for i in 0 .. displays {
		mut display_bound := sdl.Rect{}
		sdl.get_display_bounds(i, &display_bound)

		mp := sdl.Point{mx, my}
		if sdl.point_in_rect(&mp, &display_bound) {
			display_index = i
		}
		display_bounds << display_bound
	}
	// eprintln('Bounds: $display_bounds')

	// TODO
	$if debug ? {
		mut display_mode := sdl.DisplayMode{}
		sdl.get_current_display_mode(display_index, &display_mode)
		dn := unsafe { cstring_to_vstring(sdl.get_display_name(display_index)) }
		s.log.ginfo(@STRUCT + '.' + 'display', 'opening on screen $display_index `$dn` @${display_mode.refresh_rate}hz')
	}

	font_size := 14
	s.backend.font = ttf.open_font(font.get_path_variant(font.default(), .mono).str, font_size)
	mut txt_w, mut txt_h := 0, 0
	ttf.size_utf8(s.backend.font, 'Åjƒ'.str, &txt_w, &txt_h)

	s.backend.text_input.text_height = txt_h

	// $if opengl ? {
	// SDL_GL_SetAttribute(SDL_GL_ACCELERATED_VISUAL, HARDWARE_RENDERING);
	sdl.gl_set_attribute(.context_flags, int(sdl.GLcontextFlag.forward_compatible_flag))
	sdl.gl_set_attribute(.context_profile_mask, int(sdl.GLprofile.core))
	sdl.gl_set_attribute(.context_major_version, 3)
	sdl.gl_set_attribute(.context_minor_version, 3)
	sdl.gl_set_attribute(.doublebuffer, 1)
	sdl.gl_set_attribute(.depth_size, 24)
	sdl.gl_set_attribute(.stencil_size, 8)
	// }

	window_config := s.config.window

	win_w := int(f32(display_bounds[display_index].w) * 0.75)
	win_h := int(f32(display_bounds[display_index].h) * 0.60)

	x := int(sdl.windowpos_centered_display(u32(display_index))) // display_bounds[display_index].x + display_bounds[display_index].w - win_w
	y := int(sdl.windowpos_centered_display(u32(display_index))) // display_bounds[display_index].y

	mut window_flags := u32(sdl.WindowFlags.resizable) | u32(sdl.WindowFlags.shown)
	// $if opengl ? {
	window_flags = window_flags | u32(sdl.WindowFlags.opengl) | u32(sdl.WindowFlags.allow_highdpi)
	// }
	// window_flags := u32(sdl.null)
	// window_flags := u32(sdl.WindowFlags.fullscreen)

	window := sdl.create_window(window_config.title.str, x, y, win_w, win_h, window_flags)
	if window == sdl.null {
		error_msg := unsafe { cstring_to_vstring(sdl.get_error()) }
		panic('Could not create SDL window, SDL says:\n$error_msg')
	}
	s.backend.window = window

	// $if opengl ? {
	s.backend.gl_context = sdl.gl_create_context(window)
	if s.backend.gl_context == sdl.null {
		error_msg := unsafe { cstring_to_vstring(sdl.get_error()) }
		panic('Could not create OpenGL context, SDL says:\n$error_msg')
	}
	sdl.gl_make_current(window, s.backend.gl_context)
	if sdl.gl_set_swap_interval(1) < 0 {
		error_msg := unsafe { cstring_to_vstring(sdl.get_error()) }
		panic('Could not set OpenGL swap interval to VSYNC:\n$error_msg')
	}
	// }

	desc := gfx.Desc{}
	gfx.setup(&desc)
	assert gfx.is_valid() == true

	// render_flags := u32(sdl.RendererFlags.accelerated) | u32(sdl.RendererFlags.presentvsync)
	// renderer := sdl.create_renderer(window, -1, render_flags)

	// Check for joysticks/game controllers
	if sdl.num_joysticks() < 1 {
		s.log.ginfo(@STRUCT + '.' + 'input', 'no joysticks or game controllers connected')
	} else {
		// Load joystick(s)
		for i in 0 .. 5 {
			/*
			controller = sdl.joystick_open(i)
			if isnil(game_controller) {
				error_msg := unsafe { cstring_to_vstring(sdl.get_error()) }
				println('Warning: Unable to open controller $i SDL Error: $error_msg' )
				continue
			}*/
			if sdl.is_game_controller(i) {
				controller := sdl.game_controller_open(i)
				if isnil(controller) {
					error_msg := unsafe { cstring_to_vstring(sdl.get_error()) }
					s.log.gerror(@STRUCT + '.' + 'input', 'unable to open controller $i:\n$error_msg')
					continue
				}
				controller_name := unsafe { cstring_to_vstring(sdl.game_controller_name_for_index(i)) }
				s.log.ginfo(@STRUCT + '.' + 'input', 'detected controller $i as "$controller_name"')
				s.backend.controllers[i] = controller
			} else {
				// sdl.joystick_close(i)
				// eprintln('Warning: Not adding controller $i - not a game controller' )
				continue
			}
		}
	}

	// sdl.set_render_draw_blend_mode(renderer, .blend)

	// s.backend.renderer = renderer

	// `vertices` defines a vertex buffer with 3 vertices
	// with 3 position fields XYZ and 4 color components RGBA -
	// for drawing a multi-colored triangle.
	//
	// C code:
	// float vertices[] = {
	//    // Positions     // Colors
	//    0.0,  0.5, 0.5,     1.0, 0.0, 0.0, 1.0,
	//    0.5, -0.5, 0.5,     0.0, 1.0, 0.0, 1.0,
	//   -0.5, -0.5, 0.5,     0.0, 0.0, 1.0, 1.0
	// };
	//
	// Array entries in the following V code is the equivalent
	// of the C code entry described above:
	vertices := [
		Vertex_t{0.0, 0.5, 0.5, 1.0, 0.0, 0.0, 1.0},
		Vertex_t{0.5, -0.5, 0.5, 0.0, 1.0, 0.0, 1.0},
		Vertex_t{-0.5, -0.5, 0.5, 0.0, 0.0, 1.0, 1.0},
	]

	// Create a vertex buffer with the 3 vertices defined above.
	mut vertex_buffer_desc := gfx.BufferDesc{
		label: c'triangle-vertices'
	}
	unsafe { vmemset(&vertex_buffer_desc, 0, int(sizeof(vertex_buffer_desc))) }

	vertex_buffer_desc.size = usize(vertices.len * int(sizeof(Vertex_t)))
	vertex_buffer_desc.data = gfx.Range{
		ptr: vertices.data
		size: vertex_buffer_desc.size
	}

	s.backend.bind.vertex_buffers[0] = gfx.make_buffer(&vertex_buffer_desc)

	// Create shader from the code-generated sg_shader_desc (gfx.ShaderDesc in V).
	// Note the function `C.simple_shader_desc()` (also defined above) - this is
	// the function that returns the compiled shader code/desciption we have
	// written in `simple_shader.glsl` and compiled with `v shader .` (`sokol-shdc`).
	shader := gfx.make_shader(C.simple_shader_desc(gfx.query_backend()))

	// Create a pipeline object (default render states are fine for triangle)
	mut pipeline_desc := gfx.PipelineDesc{}
	// This will zero the memory used to store the pipeline in.
	unsafe { vmemset(&pipeline_desc, 0, int(sizeof(pipeline_desc))) }

	// Populate the essential struct fields
	pipeline_desc.shader = shader
	// The vertex shader (`simple_shader.glsl`) takes 2 inputs:
	// ```glsl
	// in vec4 position;
	// in vec4 color0;
	// ```
	// Also note the naming of the C.ATTR_* used as indicies.
	// They are the prefixed versions of the names of the input variables in the shader code.
	// If they change in the shader code they will also change here.
	pipeline_desc.layout.attrs[C.ATTR_vs_position].format = .float3 // x,y,z as f32
	pipeline_desc.layout.attrs[C.ATTR_vs_color0].format = .float4 // r, g, b, a as f32
	// The .label is optional but can aid debugging sokol shader related issues
	// When things get complex - and you get tired :)
	pipeline_desc.label = c'triangle-pipeline'

	s.backend.shader_pipeline = gfx.make_pipeline(&pipeline_desc)

	s.ready = true
}

pub fn (mut s Solid) deinit() {
	s.log.gdebug(@STRUCT + '.' + 'lifecycle', @FN + ' called')
	// sdl.destroy_renderer(s.backend.renderer)
	gfx.shutdown()
	// $if opengl ? {
	sdl.gl_delete_context(s.backend.gl_context)
	// }
	sdl.destroy_window(s.backend.window)
	ttf.close_font(s.backend.font)
	sdl.quit()
	s.log.gdebug(@STRUCT + '.' + 'death', 'bye bye')
}

// pub fn (mut s Solid) new_window() int {
// 	s.active_window++
// 	window := Window {
// 		id: u32(s.active_window)
// 		sdl_window: voidptr(0)
// 	}
// 	return s.active_window
// }

struct Backend {
pub mut:
	window   &sdl.Window
	renderer &sdl.Renderer
	screen   &sdl.Surface
	texture  &sdl.Texture
	// sokol
	shader_pipeline gfx.Pipeline
	bind            gfx.Bindings
	// Text
	//
	gl_context sdl.GLContext
	// TTF context for font drawing
	font &ttf.Font

	controllers map[int]&sdl.GameController
	text_input  Text
	// physics
	// cms ChipmunkSpace
	// ball       Ball
	text_cache map[string]&sdl.Texture
}

fn (b &Backend) get_drawable_size() (int, int) {
	mut w := 0
	mut h := 0
	// $if opengl ? {
	sdl.gl_get_drawable_size(b.window, &w, &h)
	// }
	return w, h
}

pub fn (b Backend) global_mouse_pos() (int, int) {
	mut mx := 0
	mut my := 0
	sdl.get_global_mouse_state(&mx, &my)
	return mx, my
}
