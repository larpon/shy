// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module lib

import sdl
import shy.analyse
// import shy.wraps.sokol.gfx

// Some code found from
// "Minimal sprite rendering example with SDL2 for windowing, sokol_gfx for graphics API using OpenGL 3.3 on MacOS"
// https://gist.github.com/sherjilozair/c0fa81250c1b8f5e4234b1588e755bca

pub fn (mut wm WM) init() ! {
	wm.shy.assert_api_init()
	mut s := wm.shy

	// SDL debug info, must be called before sdl.init
	$if debug ? {
		if s.config.debug {
			s.log.gdebug('${@STRUCT}.${@FN}', 'debug on')
			sdl.log_set_all_priority(sdl.LogPriority.debug)
		}
	}

	s.log.gdebug('${@STRUCT}.${@FN}', '')

	$if linux {
		// Experiments
		// sdl.set_hint(sdl.hint_render_vsync.str,'1'.str)
		// sdl.set_hint(sdl.hint_video_x11_xrandr.str,'1'.str)
		// sdl.set_hint(sdl.hint_render_scale_quality.str, '1'.str )
		// sdl.set_hint(sdl.hint_video_highdpi_disabled.str, '0'.str)
		//
		// Stop the big "blackout/flash" on Linux desktops
		if !sdl.set_hint(sdl.hint_video_x11_net_wm_bypass_compositor.str, '0'.str) {
			sdl_error_msg := unsafe { cstring_to_vstring(sdl.get_error()) }
			s.log.gerror('${@STRUCT}.${@FN}', 'SDL: ${sdl_error_msg}')
			return error('SDL could not bypass compositor, SDL says:\n${sdl_error_msg}')
		}
	}

	$if windows {
		// NOTE Set the following to '0' if you run AND debug with .NET
		// We disable it since it trips end users more than it helps the majority.
		// Also note that it can be switched with the ENV var:
		// SDL_HINT_WINDOWS_DISABLE_THREAD_NAMING=0
		sdl.set_hint(sdl.hint_windows_disable_thread_naming.str, '1'.str)
	}

	mut init_flags := u32(sdl.init_video)
	$if wasm32_emscripten {
		init_flags = init_flags | u32(sdl.init_gamecontroller)
	} $else {
		init_flags = init_flags | u32(sdl.init_gamecontroller | sdl.init_haptic)
	}
	// init_flags := u32(sdl.init_everything)
	res := sdl.init(init_flags)
	if res < 0 {
		sdl_error_msg := unsafe { cstring_to_vstring(sdl.get_error()) }
		s.log.gerror('${@STRUCT}.${@FN}', 'SDL: ${sdl_error_msg}')
		return error('Could not initialize SDL, SDL says:\n${sdl_error_msg}')
	}

	wm.init_root_window()!
}

pub fn (mut wm WM) reset() ! {
	wm.shy.log.gdebug('${@STRUCT}.${@FN}', '')
	wm.root.reset()!
}

pub fn (mut wm WM) shutdown() ! {
	wm.shy.assert_api_shutdown()
	wm.shy.log.gdebug('${@STRUCT}.${@FN}', '')
	wm.root.close()!

	sdl.quit()
}

pub fn (wm WM) display_count() u16 {
	return u16(sdl.get_num_video_displays())
}

pub fn (wm WM) active_window_id() u32 {
	if !isnil(wm.active) {
		return Window.map_sdl_window_id_to_shy_window_id(wm.active.id)
	}
	return no_window
}

pub fn (wm WM) active_window() &Window {
	if !isnil(wm.active) {
		return wm.active
	}
	panic('WM: Error getting root window')
}

pub fn (wm WM) root() &Window {
	if !isnil(wm.root) {
		return wm.root
	}
	panic('WM: Error getting root window')
}

pub fn (mut wm WM) init_root_window() !&Window {
	s := wm.shy

	mut mx, mut my := 0, 0
	sdl.get_global_mouse_state(&mx, &my)

	mut display_index := 0

	displays := wm.display_count()

	s.log.gdebug('${@STRUCT}.${@FN}', '${displays} displays available')

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
		s.log.gdebug('${@STRUCT}.${@FN}', 'opening on screen ${display_index} `${dn}` ${dw}x${dh}@${display_mode.refresh_rate}hz')
	}

	// Center the window per default on desktop with a little margin
	mut win_w := int(f32(display_bounds[display_index].w) * 0.90)
	mut win_h := int(f32(display_bounds[display_index].h) * 0.85)
	// mut win_x := int(sdl.windowpos_centered_display(u32(display_index)))
	// mut win_y := int(sdl.windowpos_centered_display(u32(display_index)))
	mut win_x := display_bounds[display_index].x +
		((f32(display_bounds[display_index].w) - win_w) * 0.5)
	mut win_y := display_bounds[display_index].y +
		((f32(display_bounds[display_index].h) - win_h) * 0.5)

	// Force window size to same size as the display the window will be fullscreen on
	if s.config.window.fullscreen {
		win_w = int(display_bounds[display_index].w)
		win_h = int(display_bounds[display_index].h)
		win_x = 0
		win_y = 0
	}

	window_config := WindowConfig{
		...s.config.window
		x: win_x
		y: win_y
		width: win_w
		height: win_h
	}
	win := wm.new_window(window_config)!
	wm.root = win
	return wm.root
}

fn (mut wm WM) new_window(config WindowConfig) !&Window {
	analyse.count('${@MOD}.${@STRUCT}.${@FN}', 1)
	s := wm.shy

	mut window_flags := u32(sdl.WindowFlags.hidden)
	if config.visible {
		window_flags = u32(sdl.WindowFlags.shown)
	}

	if config.resizable {
		s.log.gdebug('${@STRUCT}.${@FN}', 'is resizable')
		window_flags = window_flags | u32(sdl.WindowFlags.resizable)
	}

	if config.fullscreen {
		window_flags = window_flags | u32(sdl.WindowFlags.fullscreen)
	}

	// $if opengl ? {
	window_flags = window_flags | u32(sdl.WindowFlags.opengl) | u32(sdl.WindowFlags.allow_highdpi)
	// }
	// window_flags := u32(sdl.null)
	// window_flags = window_flags | u32(sdl.WindowFlags.fullscreen)

	window := sdl.create_window(config.title.str, int(config.x), int(config.y), int(config.width),
		int(config.height), window_flags)
	if window == sdl.null {
		sdl_error_msg := unsafe { cstring_to_vstring(sdl.get_error()) }
		s.log.gerror('${@STRUCT}.${@FN}', 'SDL: ${sdl_error_msg}')
		return error('Could not create SDL window "${config.title}", SDL says:\n${sdl_error_msg}')
	}

	// }
	// Window ids in Shy is:
	// 0 == "no window". E.g. events can come from no window
	// 1 == the root window aka. the first opened window
	// X > 1 child windows of the root window
	wm.w_id++
	mut win := &Window{
		shy: s
		config: config
		id: wm.w_id
		handle: window
	}
	win.init()!
	return win
}
