// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module embed

import os
import time
import os.font
import shy.lib as shy
import shy.easy
import shy.wraps.sokol.gl
// import shy.wraps.sokol.gfx as sg

// Base app skeleton for easy embedding in examples
pub struct App {
	shy.ShyStruct // Initialized by shy.run<T>(...)
}

pub fn (mut a App) init() ! {
	a.shy.assert_api_init()
}

pub fn (mut a App) shutdown() ! {}

pub fn (mut a App) fixed_update(dt f64) {}

pub fn (mut a App) variable_update(dt f64) {}

pub fn (mut a App) frame_begin() {}

pub fn (mut a App) frame(dt f64) {}

pub fn (mut a App) frame_end() {}

pub fn (mut a App) event(e shy.Event) {}

// Simple app skeleton for easy embedding in e.g. examples
pub struct EasyApp {
	App
mut:
	offscreen_pass_id int
	gfx               &shy.GFX = shy.null
	quick             easy.Quick
	easy              &easy.Easy    = shy.null
	assets            &shy.Assets   = shy.null
	draw              &shy.Draw     = shy.null
	mouse             &shy.Mouse    = shy.null
	kbd               &shy.Keyboard = shy.null
	window            &shy.Window   = shy.null
	fonts             shy.Fonts
}

pub fn (mut a EasyApp) init() ! {
	a.App.init()!

	api := unsafe { a.shy.api() }

	a.gfx = api.gfx()
	a.easy = &easy.Easy{
		shy: a.shy
	}
	unsafe {
		a.quick.easy = a.easy
	}
	a.assets = a.shy.assets()
	a.draw = a.shy.draw()
	a.mouse = api.input().mouse(0)!
	a.kbd = api.input().keyboard(0)!
	a.window = api.wm().active_window()

	// sokol_gl is used for all drawing operations in the Easy/Quick app types
	sample_count := a.shy.config.render.msaa
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

	a.fonts.init(shy.FontsConfig{
		shy: a.shy
		// prealloc_contexts: 8
		preload: preload_fonts
		render: a.shy.config.render
	})! // fonts.b.v

	a.easy.init(fonts: a.fonts)! // TODO fix this horrible font mess

	/*
	win_w, win_h := a.window.drawable_wh()
	// Setup passes used in EasyApp based apps

    // a render pass with one color- and one depth-attachment image
	mut img_desc := sg.ImageDesc{
		render_target: true
		width: win_w
		height: win_h
		pixel_format: .rgba8
		min_filter: .linear
		mag_filter: .linear
		wrap_u: .clamp_to_edge
		wrap_v: .clamp_to_edge
		sample_count: 4
		label: 'image'.str
    }
	color_img := sg.make_image(&img_desc)

	img_desc.pixel_format = .depth
    img_desc.label = 'depth'.str
	depth_img := sg.make_image(&img_desc)

	mut pass_desc := sg.PassDesc{}
    pass_desc.color_attachments[0].image = color_img
    pass_desc.depth_stencil_attachment.image = depth_img
    pass_desc.label = "offscreen-pass".str
	pass := sg.make_pass(pass_desc)

	mut rp := shy.RenderPass{
		pass: pass
		pass_action: a.gfx.make_clear_color_pass_action(shy.rgb(0,0,255))
	}
	a.offscreen_pass_id = a.gfx.add_pass(rp)
	*/
}

pub fn (mut a EasyApp) shutdown() ! {
	a.fonts.shutdown()!
	gl.shutdown()
	a.App.shutdown()!
}

pub fn (mut a EasyApp) frame_begin() {
	a.App.frame_begin()
	a.gfx.begin_pass(0)
}

pub fn (mut a EasyApp) frame_end() {
	a.fonts.on_frame_end()

	gl.set_context(gl.default_context)
	gl.draw()
	a.gfx.end_pass()

	// a.gfx.begin_pass(0)
	// a.gfx.end_pass()

	a.App.frame_end()
}

pub fn (mut a EasyApp) event(e shy.Event) {
	match e {
		shy.QuitEvent {
			a.shy.shutdown = true
		}
		shy.KeyEvent {
			if e.state == .up {
				return
			}
			key := e.key_code
			kb := a.kbd
			alt_is_held := (kb.is_key_down(.lalt) || kb.is_key_down(.ralt))
			match key {
				.escape {
					a.shy.shutdown = true
				}
				.printscreen, .f12 {
					date := time.now()
					date_str := date.format_ss_milli().replace_each([' ', '', '.', '', '-', '',
						':', ''])
					shot_file := os.join_path(os.temp_dir(), 'shy', '${@STRUCT}', '${date_str}f${a.window.state.frame}.png')
					a.window.screenshot(shot_file) or {
						a.shy.log.gerror('${@STRUCT}.${@FN}', '${err}')
					}
					a.shy.log.gdebug('${@STRUCT}', 'saved screenshot to "${shot_file}"')
				}
				else {
					if key == .f || key == .f11 || (key == .@return && alt_is_held) {
						a.window.toggle_fullscreen()
					}
				}
			}
		}
		// MouseMotionEvent {
		// 	a.shy.api.mouse.show()
		// }
		else {}
	}
}

// Example app skeleton for all the examples
struct ExampleApp {
	EasyApp
}

// asset unifies locating example assets
pub fn (ea ExampleApp) asset(path string) string {
	$if wasm32_emscripten {
		return path
	}
	return os.resource_abs_path(os.join_path('..', 'assets', path))
}

// pub fn (mut ea ExampleApp) init()! {
// 	ea.EasyApp.init() !
// }

// Developer app skeleton
struct DevApp {
	EasyApp
}

/*
pub fn (mut a DevApp) init() ! {
	a.EasyApp.init()!
}

pub fn (mut a DevApp) shutdown() ! {
	a.EasyApp.shutdown()!
}
*/

pub fn (mut a DevApp) event(e shy.Event) {
	a.EasyApp.event(e)
	mut s := a.shy
	// Handle debug output control here
	if e is shy.KeyEvent {
		key_code := e.key_code
		if e.state == .down {
			kb := a.kbd
			if kb.is_key_down(.comma) {
				if key_code == .s {
					s.log.print_status('STATUS')
					return
				}

				if key_code == .f1 {
					w := s.active_window()
					s.log.gdebug('${@STRUCT}.${@FN}', 'Current FPS ${w.fps()}')
					return
				}

				if key_code == .f2 {
					s.log.gdebug('${@STRUCT}.${@FN}', 'Current Performance Count ${s.performance_counter()}')
					return
				}

				if key_code == .f3 {
					s.log.gdebug('${@STRUCT}.${@FN}', 'Current Performance Frequency ${s.performance_frequency()}')
					return
				}

				// Log print control
				if kb.is_key_down(.l) {
					s.log.on(.log)

					if key_code == .f {
						s.log.toggle(.flood)
						return
					}
					if key_code == .minus || kb.is_key_down(.minus) {
						s.log.off(.log)
					} else if key_code == ._0 {
						s.log.toggle(.debug)
					} else if key_code == ._1 {
						s.log.toggle(.info)
					} else if key_code == ._2 {
						s.log.toggle(.warn)
					} else if key_code == ._3 {
						s.log.toggle(.error)
					} else if key_code == ._4 {
						s.log.toggle(.critical)
					}
					return
				}
			}
		}
	}
}

// Test app skeleton for the visual tests
struct TestApp {
	EasyApp
}
