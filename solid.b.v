// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module solid

// Some code found from
// "Minimal sprite rendering example with SDL2 for windowing, sokol_gfx for graphics API using OpenGL 3.3 on MacOS"
// https://gist.github.com/sherjilozair/c0fa81250c1b8f5e4234b1588e755bca
import sdl
import sokol.gfx
import sokol.sgl
import sgp // sokol_gp

pub fn (s Solid) performance_counter() u64 {
	return sdl.get_performance_counter()
}

pub fn (s Solid) performance_frequency() u64 {
	return sdl.get_performance_frequency()
}

pub fn (s Solid) clear_screen() {
	w, h := s.backend.get_drawable_size()
	gfx.begin_default_pass(&s.backend.pass_action, w, h)
}

pub fn (s Solid) display() {
	gfx.end_pass()
	gfx.commit()
	sdl.gl_swap_window(s.backend.window)
}

pub fn (mut s Solid) init() {
	s.log.gdebug(@STRUCT + '.' + 'lifecycle', @FN + ' called')
	$if linux {
		// Experiments
		// sdl.set_hint(sdl.hint_render_vsync.str,'1'.str)
		// sdl.set_hint(sdl.hint_video_x11_xrandr.str,'1'.str)
		// sdl.set_hint(sdl.hint_render_scale_quality.str, '1'.str )
	}

	$if windows {
		// NOTE Set the following to '0' if you run AND debug with .NET
		// We disable it since it trips end users more than it helps the majority.
		// Also note that it can be switched with the ENV var:
		// SDL_HINT_WINDOWS_DISABLE_THREAD_NAMING=0
		sdl.set_hint(sdl.hint_windows_disable_thread_naming.str, '1'.str)
	}

	// SDL debug info, must be called before sdl.init
	$if debug ? {
		s.log.set(.debug)
		if s.config.debug {
			s.log.gdebug(@STRUCT + '.' + 'config', 'debug on')
			sdl.log_set_all_priority(sdl.LogPriority.debug)
		}
	}

	init_flags := u32(sdl.init_video | sdl.init_gamecontroller | sdl.init_haptic)
	// init_flags := u32(sdl.init_everything)
	sdl.init(init_flags)

	mx, my := s.global_mouse_position()

	mut display_index := 0

	displays := solid.display_count()

	s.log.ginfo(@STRUCT + '.' + 'window', '$displays displays available')

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

	// TODO
	$if debug ? {
		mut display_mode := sdl.DisplayMode{}
		sdl.get_current_display_mode(display_index, &display_mode)
		dn := unsafe { cstring_to_vstring(sdl.get_display_name(display_index)) }
		dw := display_bounds[display_index].w
		dh := display_bounds[display_index].h
		s.log.ginfo(@STRUCT + '.' + 'window', 'opening on screen $display_index `$dn` ${dw}x$dh@${display_mode.refresh_rate}hz')
	}

	// $if opengl ? {
	// SDL_GL_SetAttribute(SDL_GL_ACCELERATED_VISUAL, HARDWARE_RENDERING);

	$if android {
		sdl.gl_set_attribute(.context_profile_mask, int(sdl.GLprofile.es))
		sdl.gl_set_attribute(.context_major_version, 2)
	} $else {
		sdl.gl_set_attribute(.context_flags, int(sdl.GLcontextFlag.forward_compatible_flag))
		sdl.gl_set_attribute(.context_profile_mask, int(sdl.GLprofile.core))
		sdl.gl_set_attribute(.context_major_version, 3)
		sdl.gl_set_attribute(.context_minor_version, 3)
	}
	sdl.gl_set_attribute(.doublebuffer, 1)
	sdl.gl_set_attribute(.depth_size, 24)
	sdl.gl_set_attribute(.stencil_size, 8)
	//
	if s.config.render.msaa > 0 {
		s.log.ginfo(@STRUCT + '.' + 'render', 'enabling $s.config.render.msaa x MSAA (Multi-Sample AntiAliasing)')
		sdl.gl_set_attribute(.multisamplebuffers, 1)
		sdl.gl_set_attribute(.multisamplesamples, s.config.render.msaa)
	}
	// } // end $if opengl

	window_config := s.config.window

	win_w := int(f32(display_bounds[display_index].w) * 0.75)
	win_h := int(f32(display_bounds[display_index].h) * 0.60)

	x := int(sdl.windowpos_centered_display(u32(display_index))) // display_bounds[display_index].x + display_bounds[display_index].w - win_w
	y := int(sdl.windowpos_centered_display(u32(display_index))) // display_bounds[display_index].y

	mut window_flags := u32(sdl.WindowFlags.shown)

	if s.config.window.resizable {
		s.log.ginfo(@STRUCT + '.' + 'window', 'is resizable')
		window_flags = window_flags | u32(sdl.WindowFlags.resizable)
	}

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
	match s.config.render.vsync {
		.off {
			if sdl.gl_set_swap_interval(0) < 0 {
				error_msg := unsafe { cstring_to_vstring(sdl.get_error()) }
				panic('Could not set OpenGL swap interval:\n$error_msg')
			}
		}
		.on {
			if sdl.gl_set_swap_interval(1) < 0 {
				error_msg := unsafe { cstring_to_vstring(sdl.get_error()) }
				panic('Could not set OpenGL swap interval:\n$error_msg')
			}
		}
		.adaptive {
			if sdl.gl_set_swap_interval(-1) < 0 {
				error_msg := unsafe { cstring_to_vstring(sdl.get_error()) }
				panic('Could not set OpenGL swap interval:\n$error_msg')
			}
		}
	}
	s.log.ginfo(@STRUCT + '.' + 'render', 'vsync=$s.config.render.vsync')
	// }

	mut gfx_desc := gfx.Desc{}
	gfx_desc.context.sample_count = s.config.render.msaa
	gfx.setup(&gfx_desc)
	assert gfx.is_valid() == true

	sgl_desc := &sgl.Desc{}
	sgl.setup(sgl_desc)

	// Initialize Sokol GP, adjust the size of command buffers for your own use.
	sgp_desc := sgp.Desc{
		// max_vertices: 1_000_000
		// max_commands: 100_000
	}
	sgp.setup(&sgp_desc)
	if !sgp.is_valid() {
		error_msg := unsafe { cstring_to_vstring(sgp.get_error_message(sgp.get_last_error())) }
		panic('Failed to create Sokol GP context:\n$error_msg')
	}

	// Initialize input systems (keyboard, mouse etc.)
	s.init_input()

	// Initialize font drawing sub system
	s.backend.font_system.init(&s) // font_system.b.v

	// Initialize font drawing sub system
	s.backend.shape_draw_system.init(&s) // shape_draw_system.b.v

	// Create a black color as a default pass (default window background color)
	clear_color := s.config.window.color.as_f32()
	pass_action := gfx.create_clear_pass(clear_color.r, clear_color.g, clear_color.b,
		clear_color.a)
	s.backend.pass_action = pass_action

	s.ready = true
}

fn (mut s Solid) init_input() {
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
				if controller == sdl.null {
					error_msg := unsafe { cstring_to_vstring(sdl.get_error()) }
					s.log.gerror(@STRUCT + '.' + 'input', 'unable to open controller $i:\n$error_msg')
					continue
				}
				controller_name := unsafe { cstring_to_vstring(sdl.game_controller_name_for_index(i)) }
				s.log.ginfo(@STRUCT + '.' + 'input', 'detected controller $i as "$controller_name"')
				s.backend.controllers[i] = controller

				// Open the device
				haptic := sdl.haptic_open_from_joystick(sdl.game_controller_get_joystick(controller))
				if haptic == sdl.null {
					// error_msg := unsafe { cstring_to_vstring(sdl.get_error()) }
					s.log.ginfo(@STRUCT + '.' + 'input', 'controller $i ($controller_name) does not seem to have haptic features')
				} else {
					// See if it can do sine waves
					if (sdl.haptic_query(haptic) & u32(sdl.haptic_sine)) == 0 {
						s.log.ginfo(@STRUCT + '.' + 'input', 'controller $i ($controller_name) does not seem to have haptic SINE effects')
					} else {
						/*
						// Create the effect
						mut effect := sdl.HapticEffect{}
						unsafe {
							vmemset( &effect, 0, int(sizeof(effect)) ) // 0 is safe default
						}

						effect.@type = u16(sdl.haptic_sine)
						effect.periodic.direction.@type = u8(sdl.haptic_polar) // Polar coordinates
						effect.periodic.direction.dir[0] = 18000 // Force comes from south
						effect.periodic.period = 1000 // 1000 ms
						effect.periodic.magnitude = 20000 // 20000/32767 strength
						effect.periodic.length = 5000 // 5 seconds long
						effect.periodic.attack_length = 1000 // Takes 1 second to get max strength
						effect.periodic.fade_length = 1000 // Takes 1 second to fade away

						// Upload the effect
						effect_id := sdl.haptic_new_effect( haptic, &effect )

						// Test the effect
						sdl.haptic_run_effect( haptic, effect_id, 1 )
						sdl.delay( 5000) // Wait for the effect to finish

						// We destroy the effect, although closing the device also does this
						sdl.haptic_destroy_effect( haptic, effect_id )
						*/
					}
				}
				// Close the device
				sdl.haptic_close(haptic)
			} else {
				// sdl.joystick_close(i)
				// eprintln('Warning: Not adding controller $i - not a game controller' )
				continue
			}
		}
	}
}

pub fn (mut s Solid) deinit() {
	s.log.gdebug(@STRUCT + '.' + 'lifecycle', @FN + ' called')

	s.backend.font_system.shutdown()

	sgp.shutdown()

	gfx.shutdown()
	// $if opengl ? {
	sdl.gl_delete_context(s.backend.gl_context)
	// }
	sdl.destroy_window(s.backend.window)

	sdl.quit()
	s.log.gdebug(@STRUCT + '.' + 'death', 'bye bye')
	s.log.free()
}

fn (s Solid) global_mouse_position() (int, int) {
	mut mx := 0
	mut my := 0
	sdl.get_global_mouse_state(&mx, &my)
	return mx, my
}

// window_mouse_position returns the `x` and `y` coordinate of the mouse
// relatively to the active window
fn (s Solid) window_mouse_position() (int, int) {
	mut mx := 0
	mut my := 0
	sdl.get_mouse_state(&mx, &my)
	return mx, my
}

pub fn (s Solid) scope(action ScopeAction, scope Scope) {
	// TODO verify open/close state of the scope(s)
	match scope {
		.shape_draw {
			match action {
				.open {
					s.backend.shape_draw_system.scope_open()
				}
				.close {
					s.backend.shape_draw_system.scope_close()
				}
			}
		}
		.text_draw {
			match action {
				.open {
					s.backend.font_system.scope_open()
				}
				.close {
					s.backend.font_system.scope_close()
				}
			}
		}
	}
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
	window &sdl.Window
	// sokol
	pass_action gfx.PassAction
	//
	gl_context sdl.GLContext
	// Font backend
	font_system FontSystem
	//
	shape_draw_system ShapeDrawSystem
	//
	controllers map[int]&sdl.GameController
}

fn (b &Backend) get_drawable_size() (int, int) {
	mut w := 0
	mut h := 0
	// $if opengl ? {
	sdl.gl_get_drawable_size(b.window, &w, &h)
	// }
	return w, h
}
