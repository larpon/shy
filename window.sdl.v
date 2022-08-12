// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module solid

import sdl

pub struct Window {
pub:
	id u32
mut:
	solid    &Solid
	handle   &sdl.Window
	context  sdl.GLContext
	children []&Window
}

pub fn (b Boot) init() !&WM {
	s := b.solid
	s.log.gdebug(@STRUCT + '.' + 'lifecycle', @FN + ' called')
	wm := &WM{
		solid: s
	}
	return wm
}

pub fn (mut wm WM) init() ! {
	mut s := wm.solid

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
		if s.config.debug {
			s.log.gdebug(@STRUCT + '.' + 'config', 'debug on')
			sdl.log_set_all_priority(sdl.LogPriority.debug)
		}
	}

	init_flags := u32(sdl.init_video | sdl.init_gamecontroller | sdl.init_haptic)
	// init_flags := u32(sdl.init_everything)
	res := sdl.init(init_flags)
	if res < 0 {
		sdl_error_msg := unsafe { cstring_to_vstring(sdl.get_error()) }
		s.log.gerror(@STRUCT + '.' + @FN, 'SDL: $sdl_error_msg')
		return error('Could not initialize SDL window, SDL says:\n$sdl_error_msg')
	}

	root_win := wm.init_root_window()!
	wm.root = root_win
}

pub fn (wm WM) active_window() &Window {
	if !isnil(wm.root) {
		return wm.root
	}
	panic('WM: Error getting root window')
	// return wm.root
}

pub fn (wm WM) root() &Window {
	if !isnil(wm.root) {
		return wm.root
	}
	panic('WM: Error getting root window')
	// return wm.root
}

pub fn (mut wm WM) init_root_window() !&Window {
	// If no root window we initialize one
	s := wm.solid

	mut mx := 0
	mut my := 0
	sdl.get_global_mouse_state(&mx, &my)

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
		sdl_error_msg := unsafe { cstring_to_vstring(sdl.get_error()) }
		s.log.gerror(@STRUCT + '.' + @FN, 'SDL: $sdl_error_msg')
		return error('Could not create SDL window, SDL says:\n$sdl_error_msg')
	}

	// $if opengl ? {
	gl_context := sdl.gl_create_context(window)
	if gl_context == sdl.null {
		sdl_error_msg := unsafe { cstring_to_vstring(sdl.get_error()) }
		s.log.gerror(@STRUCT + '.' + @FN, 'SDL: $sdl_error_msg')
		return error('Could not create OpenGL context, SDL says:\n$sdl_error_msg')
	}

	// }
	mut win := &Window{
		solid: s
		id: 0
		handle: window
		context: gl_context
	}
	win.init()!
	wm.root = win
	return wm.root
}

pub fn (mut wm WM) shutdown() ! {
	wm.root.close()!
	// TODO test unsafe { free(wm) }

	sdl.quit()
}

pub fn (mut w Window) init() ! {
	w.solid.log.gdebug(@STRUCT + '.' + 'lifecycle', @FN + ' called')
	s := w.solid

	// $if opengl ? {
	sdl.gl_make_current(w.handle, w.context)
	match s.config.render.vsync {
		.off {
			if sdl.gl_set_swap_interval(0) < 0 {
				sdl_error_msg := unsafe { cstring_to_vstring(sdl.get_error()) }
				s.log.gerror(@STRUCT + '.' + @FN, 'SDL: $sdl_error_msg')
				return error('Could not set OpenGL swap interval:\n$sdl_error_msg')
			}
		}
		.on {
			if sdl.gl_set_swap_interval(1) < 0 {
				sdl_error_msg := unsafe { cstring_to_vstring(sdl.get_error()) }
				s.log.gerror(@STRUCT + '.' + @FN, 'SDL: $sdl_error_msg')
				return error('Could not set OpenGL swap interval:\n$sdl_error_msg')
			}
		}
		.adaptive {
			if sdl.gl_set_swap_interval(-1) < 0 {
				sdl_error_msg := unsafe { cstring_to_vstring(sdl.get_error()) }
				s.log.gerror(@STRUCT + '.' + @FN, 'SDL: $sdl_error_msg')
				return error('Could not set OpenGL swap interval:\n$sdl_error_msg')
			}
		}
	}
	s.log.ginfo(@STRUCT + '.' + 'render', 'vsync=$s.config.render.vsync')
	// }
}

pub fn (mut w Window) close() ! {
	// s := w.solid

	for mut window in w.children {
		window.close()!
	}
	// $if opengl ? {
	sdl.gl_delete_context(w.context)
	// }
	sdl.destroy_window(w.handle)
}

/*
pub fn (w Window) as_native() &sdl.Window {
	return &sdl.Window(w.ref)
}
*/

pub fn (mut w Window) toggle_fullscreen() {
	if w.is_fullscreen() {
		sdl.set_window_fullscreen(w.handle, 0)
	} else {
		mut window_flags := u32(0)
		$if linux {
			window_flags = u32(sdl.WindowFlags.fullscreen_desktop)
		} $else {
			window_flags = u32(sdl.WindowFlags.fullscreen)
		}
		sdl.set_window_fullscreen(w.handle, window_flags)
	}
}

pub fn (w &Window) is_fullscreen() bool {
	// sdl_window := &sdl.Window(w.ref)
	cur_flags := sdl.get_window_flags(w.handle)
	return cur_flags & u32(sdl.WindowFlags.fullscreen) > 0
		|| cur_flags & u32(sdl.WindowFlags.fullscreen_desktop) > 0
}

pub fn (w &Window) size() (int, int) {
	mut width, mut height := 0, 0
	sdl.get_window_size(w.handle, &width, &height)
	return width, height
}

pub fn (w &Window) drawable_size() (int, int) {
	mut width := 0
	mut height := 0
	// $if opengl ? {
	sdl.gl_get_drawable_size(w.handle, &width, &height)
	// }
	return width, height
}

pub fn (w &Window) swap() {
	// w.solid.gfx.commit()
	sdl.gl_swap_window(w.handle)
}
