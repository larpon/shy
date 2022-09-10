// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module shy

import shy.mth
import sdl
import sokol.gfx
import os.font

// Some code found from
// "Minimal sprite rendering example with SDL2 for windowing, sokol_gfx for graphics API using OpenGL 3.3 on MacOS"
// https://gist.github.com/sherjilozair/c0fa81250c1b8f5e4234b1588e755bca

pub fn (b Boot) init() !&WM {
	s := b.shy
	s.log.gdebug('${@STRUCT}.${@FN}', 'hi')
	wm := &WM{
		shy: s
	}
	return wm
}

pub fn (mut wm WM) init() ! {
	mut s := wm.shy

	s.log.gdebug('${@STRUCT}.${@FN}', 'hi')

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
			s.log.gdebug('${@STRUCT}.${@FN}', 'debug on')
			sdl.log_set_all_priority(sdl.LogPriority.debug)
		}
	}

	init_flags := u32(sdl.init_video | sdl.init_gamecontroller | sdl.init_haptic)
	// init_flags := u32(sdl.init_everything)
	res := sdl.init(init_flags)
	if res < 0 {
		sdl_error_msg := unsafe { cstring_to_vstring(sdl.get_error()) }
		s.log.gerror('${@STRUCT}.${@FN}', 'SDL: $sdl_error_msg')
		return error('Could not initialize SDL window, SDL says:\n$sdl_error_msg')
	}

	wm.init_root_window()!
}

pub fn (wm WM) display_count() u16 {
	return u16(sdl.get_num_video_displays())
}

pub fn (wm WM) active_window() &Window {
	if !isnil(wm.active) {
		return wm.active
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
	s := wm.shy

	mut mx := 0
	mut my := 0
	sdl.get_global_mouse_state(&mx, &my)

	mut display_index := 0

	displays := wm.display_count()

	s.log.ginfo('${@STRUCT}.${@FN}', '$displays displays available')

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
		s.log.ginfo('${@STRUCT}.${@FN}', 'opening on screen $display_index `$dn` ${dw}x$dh@${display_mode.refresh_rate}hz')
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
		s.log.ginfo('${@STRUCT}.${@FN}', 'enabling MSAA (Multi-Sample AntiAliasing)')
		sdl.gl_set_attribute(.multisamplebuffers, 1)

		// Setting multi-samples here will result in SDL applying yet another pass of anti-aliasing...
		sdl.gl_set_attribute(.multisamplesamples, s.config.render.msaa)
	}
	// } // end $if opengl

	win_w := int(f32(display_bounds[display_index].w) * 0.75)
	win_h := int(f32(display_bounds[display_index].h) * 0.60)

	x := int(sdl.windowpos_centered_display(u32(display_index))) // display_bounds[display_index].x + display_bounds[display_index].w - win_w
	y := int(sdl.windowpos_centered_display(u32(display_index))) // display_bounds[display_index].y

	window_config := WindowConfig{
		...s.config.window
		x: x
		y: y
		w: win_w
		h: win_h
	}
	win := wm.new_window(window_config)!
	wm.root = win
	return wm.root
}

pub fn (mut wm WM) shutdown() ! {
	wm.shy.log.gdebug('${@STRUCT}.${@FN}', 'bye')
	wm.root.close()!
	// TODO test unsafe { free(wm) }

	sdl.quit()
}

fn (mut wm WM) new_window(config WindowConfig) !&Window {
	s := wm.shy
	mut window_flags := u32(sdl.WindowFlags.hidden)
	if config.visible {
		window_flags = u32(sdl.WindowFlags.shown)
	}

	if config.resizable {
		s.log.ginfo('${@STRUCT}.${@FN}', 'is resizable')
		window_flags = window_flags | u32(sdl.WindowFlags.resizable)
	}

	// $if opengl ? {
	window_flags = window_flags | u32(sdl.WindowFlags.opengl) | u32(sdl.WindowFlags.allow_highdpi)
	// }
	// window_flags := u32(sdl.null)
	// window_flags := u32(sdl.WindowFlags.fullscreen)

	window := sdl.create_window(config.title.str, int(config.x), int(config.y), int(config.w),
		int(config.h), window_flags)
	if window == sdl.null {
		sdl_error_msg := unsafe { cstring_to_vstring(sdl.get_error()) }
		s.log.gerror('${@STRUCT}.${@FN}', 'SDL: $sdl_error_msg')
		return error('Could not create SDL window "$config.title", SDL says:\n$sdl_error_msg')
	}

	// Create a black color as a default pass (default window background color)
	color := s.config.window.color.as_f32()
	pass_action := gfx.create_clear_pass(color.r, color.g, color.b, color.a)
	// g.pass_action = pass_action

	// }
	mut win := &Window{
		shy: s
		id: wm.w_id
		handle: window
		pass_action: pass_action
	}
	win.init()!
	wm.w_id++
	return win
}

// RenderState
struct RenderState {
mut:
	resync bool
	//
	fps_frame    u32
	fps_snapshot u32
	frame        u64
	//
	in_frame_call bool
	//
	fps_timer           u64
	update_rate         f64 = 60.0
	update_multiplicity u8
	lock_framerate      bool

	performance_frequency u64
	fixed_deltatime       f64
	desired_frametime     i64

	vsync_maxerror i64
	// time_60hz i64

	snap_frequencies [5]i64

	time_averager      [4]i64 // NOTE should be same cap as time_history_count
	time_history_count u8 = 4
	prev_frame_time    i64
	frame_accumulator  i64
}

// Window
pub struct Window {
	ShyStruct
pub:
	id u32
mut:
	ready    bool
	parent   &Window = null
	children []&Window
	state    RenderState
	fonts    Fonts
	// SDL / GL
	handle     &sdl.Window
	gl_context sdl.GLContext
	// sokol
	pass_action gfx.PassAction
	gfx_context gfx.Context
}

pub fn (w &Window) begin() {
	// TODO multi window support
	width, height := w.drawable_size()
	gfx.begin_default_pass(&w.pass_action, width, height)
}

[inline]
pub fn (w Window) fps() u32 {
	return w.state.fps_snapshot
}

pub fn (mut w Window) render_init() {
	s := w.shy

	w.state.fps_timer = u64(0)
	run_config := s.config.run
	// update_rate         = f64(59.95) // TODO
	// update_rate         = f64(120)
	update_rate := run_config.update_rate // f64(60)
	w.state.update_rate = update_rate // f64(60)
	w.state.update_multiplicity = run_config.update_multiplicity // int(1)
	w.state.lock_framerate = run_config.lock_framerate // false
	w.state.time_history_count = run_config.time_history_count // 4

	// V implementation of:
	// https://medium.com/@tglaiel/how-to-make-your-game-run-at-60fps-24c61210fe75
	// https://gafferongames.com/post/fix_your_timestep/
	// compute how many ticks one update should be

	performance_frequency := s.performance_frequency()
	w.state.performance_frequency = performance_frequency
	w.state.fixed_deltatime = f64(1.0) / update_rate
	w.state.desired_frametime = i64(performance_frequency / update_rate)

	// These are to snap deltaTime to vsync values if it's close enough
	w.state.vsync_maxerror = i64(performance_frequency * f64(0.0002))
	time_60hz := i64(performance_frequency / 60) // since this is about snapping to common vsync values
	// time_60hz := i64(performance_frequency / update_rate)
	w.state.snap_frequencies = [
		time_60hz, /* 60fps */
		time_60hz * 2, /* 30fps */
		time_60hz * 3, /* 20fps */
		time_60hz * 4, /* 15fps */
		(time_60hz + 1) / 2, /* 120fps */
		/*
		//120hz, 240hz, or higher need to round up, so that adding 120hz twice guaranteed is at least the same as adding time_60hz once
		// (time_60hz+2)/3,  //180fps //that's where the +1 and +2 come from in those equations
		// (time_60hz+3)/4,  //240fps //I do not want to snap to anything higher than 120 in my engine, but I left the math in here anyway
		*/
	]!

	// time_history_count := 4
	// mut time_averager := [time_history_count]i64{init: desired_frametime}
	//
	// This is for delta time averaging
	// Time averaging could, arguably, be done using a ring buffer.
	// w.state.time_averager := []i64{len: int(time_history_count), cap: int(time_history_count), init: desired_frametime}

	w.state.resync = true
	w.state.prev_frame_time = i64(s.performance_counter())
	w.state.frame_accumulator = 0
}

pub fn (mut w Window) render<T>(mut ctx T) {
	if !w.ready {
		return
	}
	s := w.shy

	w.state.fps_frame++
	w.state.frame++

	now := s.ticks()

	// count fps in 1 sec (1000 ms)
	if now >= w.state.fps_timer + 1000 {
		w.state.fps_timer = now
		w.state.fps_snapshot = w.state.fps_frame // - 1
		w.state.fps_frame = 0
	}

	// Make this window's context the current
	w.make_current()

	// Clear the window
	w.begin()

	// frame timer
	current_frame_time := i64(s.performance_counter())
	mut delta_time := current_frame_time - w.state.prev_frame_time
	w.state.prev_frame_time = current_frame_time

	desired_frametime := w.state.desired_frametime

	// handle unexpected timer anomalies (overflow, extra slow frames, etc)
	// ignore extra-slow frames
	if delta_time > desired_frametime * 8 {
		delta_time = desired_frametime
	}
	if delta_time < 0 {
		delta_time = 0
	}

	// vsync time snapping
	for snap in w.state.snap_frequencies {
		if mth.abs(delta_time - snap) < w.state.vsync_maxerror {
			// eprintln('Snaping at $i')
			delta_time = snap
			break
		}
	}
	// Delta time averaging
	// for i := 0; i < time_history_count - 1; i++ {
	for i in 0 .. w.state.time_history_count - 1 {
		w.state.time_averager[i] = w.state.time_averager[i + 1]
	}
	w.state.time_averager[w.state.time_history_count - 1] = delta_time
	delta_time = 0
	// for i := 0; i < time_history_count; i++ {
	for i in 0 .. w.state.time_history_count {
		delta_time += w.state.time_averager[i]
	}
	delta_time /= w.state.time_history_count

	// add to the accumulator
	w.state.frame_accumulator += delta_time

	// spiral of death protection
	if w.state.frame_accumulator > desired_frametime * 8 {
		w.state.resync = true
	}

	// Timer resync if requested
	// Typical good after level load or similar
	if w.state.resync {
		w.state.frame_accumulator = 0
		delta_time = desired_frametime
		w.state.resync = false
	}

	fixed_deltatime := w.state.fixed_deltatime
	// UNLOCKED FRAMERATE, INTERPOLATION ENABLED
	if !w.state.lock_framerate {
		mut consumed_delta_time := delta_time

		for w.state.frame_accumulator >= desired_frametime {
			// eprintln('(unlocked) s.fixed_update( $fixed_deltatime )')
			ctx.fixed_update(fixed_deltatime)

			if consumed_delta_time > desired_frametime {
				// cap variable update's dt to not be larger than fixed update,
				// and interleave it (so game state can always get animation frames it needs)

				// eprintln('(unlocked) 1 ctx.variable_update( $fixed_deltatime )')
				ctx.variable_update(fixed_deltatime)

				consumed_delta_time -= desired_frametime
			}
			w.state.frame_accumulator -= desired_frametime
		}

		c_dt := f64(consumed_delta_time) / s.performance_frequency()
		// eprintln('(unlocked) 2 ctx.variable_update( $c_dt )')
		ctx.variable_update(c_dt)

		f_dt := f64(w.state.frame_accumulator) / desired_frametime
		// eprintln('(unlocked) ctx.frame( $f_dt )')
		w.state.in_frame_call = true
		ctx.frame(f_dt)
	} else { // LOCKED FRAMERATE, NO INTERPOLATION
		for w.state.frame_accumulator >= desired_frametime * w.state.update_multiplicity {
			for i := 0; i < w.state.update_multiplicity; i++ {
				// eprintln('(locked) ctx.fixed_update( $fixed_deltatime )')
				ctx.fixed_update(fixed_deltatime)

				// eprintln('(locked) ctx.variable_update( $fixed_deltatime )')
				ctx.variable_update(fixed_deltatime)
				w.state.frame_accumulator -= desired_frametime
			}
		}

		// eprintln('(locked) ctx.frame( 1.0 )')
		w.state.in_frame_call = true
		ctx.frame(1.0)
	}

	w.end()
	w.state.in_frame_call = false

	s.api.gfx.end()
	s.api.gfx.commit()

	// display() / swap buffers
	w.swap()

	for mut cw in w.children {
		cw.render<T>(mut ctx)
	}
}

/*
pub fn (w &Window) commit() {
	gfx.commit()
}
*/
pub fn (mut w Window) end() {
	w.fonts.on_frame_end()
}

pub fn (w &Window) swap() {
	// w.shy.gfx.commit()
	sdl.gl_swap_window(w.handle)
}

pub fn (w Window) is_root() bool {
	return w.id == 0
}

pub fn (mut w Window) new_window(config WindowConfig) !&Window {
	win := w.shy.api.wm.new_window(config)!
	unsafe {
		win.parent = w
	}
	w.children << win
	return win
}

pub fn (w &Window) make_current() {
	unsafe {
		w.shy.api.wm.active = w
	}
	sdl.gl_make_current(w.handle, w.gl_context)
	gfx.activate_context(w.gfx_context)
}

pub fn (mut w Window) init() ! {
	w.shy.log.gdebug('${@STRUCT}.${@FN}', 'hi')
	s := w.shy

	// $if opengl ? {
	gl_context := sdl.gl_create_context(w.handle)
	if gl_context == sdl.null {
		sdl_error_msg := unsafe { cstring_to_vstring(sdl.get_error()) }
		s.log.gerror('${@STRUCT}.${@FN}', 'SDL: $sdl_error_msg')
		return error('Could not create OpenGL context, SDL says:\n$sdl_error_msg')
	}
	w.gl_context = gl_context

	sdl.gl_make_current(w.handle, w.gl_context)
	// $if opengl ? {
	match s.config.render.vsync {
		.off {
			if sdl.gl_set_swap_interval(0) < 0 {
				sdl_error_msg := unsafe { cstring_to_vstring(sdl.get_error()) }
				s.log.gerror('${@STRUCT}.${@FN}', 'SDL: $sdl_error_msg')
				return error('Could not set OpenGL swap interval:\n$sdl_error_msg')
			}
		}
		.on {
			if sdl.gl_set_swap_interval(1) < 0 {
				sdl_error_msg := unsafe { cstring_to_vstring(sdl.get_error()) }
				s.log.gerror('${@STRUCT}.${@FN}', 'SDL: $sdl_error_msg')
				return error('Could not set OpenGL swap interval:\n$sdl_error_msg')
			}
		}
		.adaptive {
			if sdl.gl_set_swap_interval(-1) < 0 {
				sdl_error_msg := unsafe { cstring_to_vstring(sdl.get_error()) }
				s.log.gerror('${@STRUCT}.${@FN}', 'SDL: $sdl_error_msg')
				return error('Could not set OpenGL swap interval:\n$sdl_error_msg')
			}
		}
	}
	s.log.ginfo('${@STRUCT}.${@FN}', 'vsync=$s.config.render.vsync')
	// }

	w.gfx_context = gfx.setup_context()

	// Change all contexts to this window's
	w.make_current()

	// Init subsystem's for this context setup
	// TODO does this work ????
	w.shy.api.gfx.init_subsystems()!

	// TODO Initialize font drawing sub system
	w.fonts.init(FontsConfig{
		shy: s
		// prealloc_contexts: 8
		preload: {
			'system': font.default()
		}
	})! // fonts.b.v

	w.render_init()

	w.ready = true
}

pub fn (mut w Window) close() ! {
	w.ready = false
	w.shy.log.gdebug('${@STRUCT}.${@FN}', 'bye')
	w.shutdown()!
}

pub fn (mut w Window) shutdown() ! {
	w.shy.log.gdebug('${@STRUCT}.${@FN}', 'bye')
	for mut window in w.children {
		window.close()!
	}

	w.make_current()

	w.fonts.shutdown()!

	w.shy.api.gfx.shutdown_subsystems()!

	gfx.discard_context(w.gfx_context)
	// $if opengl ? {
	sdl.gl_delete_context(w.gl_context)
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

pub fn (w &Window) height() int {
	mut height := 0
	sdl.get_window_size(w.handle, sdl.null, &height)
	return height
}

pub fn (w &Window) width() int {
	mut width := 0
	sdl.get_window_size(w.handle, &width, sdl.null)
	return width
}

pub fn (w &Window) drawable_size() (int, int) {
	mut width := 0
	mut height := 0
	// $if opengl ? {
	sdl.gl_get_drawable_size(w.handle, &width, &height)
	// }
	return width, height
}
