// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module lib

import os
import sdl
import time
import shy.mth
import shy.analyse
// import shy.wraps.sokol.gfx

// Some code found from
// "Minimal sprite rendering example with SDL2 for windowing, sokol_gfx for graphics API using OpenGL 3.3 on MacOS"
// https://gist.github.com/sherjilozair/c0fa81250c1b8f5e4234b1588e755bca

// FrameState
struct FrameState {
pub mut:
	resync bool
	//
	fps_frame    u32
	fps_snapshot u32
	frame        u64
	//
	in_frame_call bool
	//
	fps_timer             u64
	update_rate           f64 = defaults.render.update_rate
	update_multiplicity   u8  = defaults.render.update_multiplicity
	lock_framerate        bool
	performance_frequency u64
	snap_frequencies      [5]i64
	fixed_delta_time      f64
	desired_frametime     i64
	vsync_maxerror        i64
	time_averager         [4]i64 // NOTE should be same cap as time_history_count
	// time_history_count u8 = 4
	prev_frame_time   i64
	frame_accumulator i64
}

pub fn (mut fs FrameState) reset() {
	fs.frame = 0
}

struct Stepper {
mut:
	step u16
	rate f64 = 60.0
}

pub fn (mut s Stepper) reset() {
	s.step = 0
	s.rate = 60.0
}

pub fn (mut w Window) step(frames u16, rate f64) {
	w.mode = .step
	w.stepper.step = frames
	w.stepper.rate = rate
}

pub fn (mut w Window) unstep() {
	w.mode = .immediate
	w.stepper.reset()
}

@[params]
pub struct WindowRefreshConfig {
	sleep time.Duration
}

pub fn (mut w Window) refresh(wdc WindowRefreshConfig) {
	if w.mode != .ui {
		return
	}
	analyse.count('${@MOD}.${@STRUCT}(${w.id}).${@FN}', 1)
	w.refresh_config = wdc
	w.is_dirty = true
}

// Credits to @spytheman (https://github.com/spytheman) for his
// invaluable implementation in the `gg` module.
const frame_record_config = new_shy_frame_record_config()

@[heap]
struct FrameRecordConfig {
pub:
	windows       []u64
	exit_on_frame i64 = -1
	frames        []u64
	save_path     string
	save_prefix   string
}

// record_frame records the current frame to a file.
// record_frame acts according to the config specified in `shy.frame_record_config`.
@[if shy_record ?]
fn (mut w Window) record_frame() {
	rc := frame_record_config
	frame := w.state.frame
	valid_window := rc.windows.len == 0 || w.id in rc.windows
	if !valid_window {
		return
	}
	if frame in rc.frames {
		screenshot_file_path := '${rc.save_prefix}${frame}.png'
		$if shy_record_trace ? {
			eprintln('>>> ${@FN} screenshot at frame ${frame} "${screenshot_file_path}"')
		}
		w.screenshot(screenshot_file_path) or { panic(err) }
		w.step(1, w.state.update_rate)
	} else {
		mut next_frame := frame
		for f in rc.frames {
			if f > next_frame {
				next_frame = f
				break
			}
		}
		mut step_frames := u16(next_frame - frame)
		// Prevent dead-lock
		if step_frames <= 0 {
			step_frames = 1
		}
		w.step(step_frames, w.state.update_rate)
	}
	if frame == rc.exit_on_frame {
		$if shy_record_trace ? {
			eprintln('>>> ${@FN} exiting at frame ${frame}')
		}
		exit(0)
	}
}

fn new_shy_frame_record_config() &FrameRecordConfig {
	$if shy_record ? {
		mut window_ids := os.getenv_opt('SHY_RECORD_WINDOW') or { '' }.split_any(',').filter(it != '').map(it.u64())
		window_ids.sort()
		exit_on_frame := os.getenv_opt('SHY_EXIT_ON_FRAME') or { '-1' }.i64()
		mut frames := os.getenv('SHY_RECORD_FRAMES').split_any(',').filter(it != '').map(it.u64())
		frames.sort()
		dir := os.getenv_opt('SHY_RECORD_DIR') or { os.join_path(os.temp_dir(), 'shy') }
		prefix := os.join_path_single(dir, os.file_name(os.executable()).all_before('.') + '_')
		return &FrameRecordConfig{
			windows:       window_ids
			exit_on_frame: exit_on_frame
			frames:        frames
			save_path:     dir
			save_prefix:   prefix
		}
	} $else {
		return &FrameRecordConfig{}
	}
}

pub enum WindowRenderMode {
	immediate
	ui
	step
}

pub fn (wm WindowRenderMode) next() WindowRenderMode {
	return match wm {
		.immediate { .ui }
		.ui { .step }
		.step { .immediate }
	}
}

// Window
@[heap]
pub struct Window {
	ShyStruct
	Rect
	config WindowConfig
pub:
	id u32
mut:
	ready          bool
	is_dirty       bool    = true // TODO
	parent         &Window = null
	children       []&Window
	anims          &Anims  = null
	timers         &Timers = null
	stepper        Stepper
	refresh_config WindowRefreshConfig
	// SDL / GL
	handle     &sdl.Window = null
	gl_context sdl.GLContext
	// id of GFX/Context this window has been given
	gfx u32
pub mut:
	state FrameState
	mode  WindowRenderMode
}

fn Window.map_sdl_window_id_to_shy_window_id(sdl_window_id u32) u32 {
	// In SDL2 a `windowID == 0` is "no window", Shy also uses that convention
	// See the const lib.no_window
	return sdl_window_id
}

pub fn (w &Window) find_window(window_id u32) ?&Window {
	if w.id == window_id {
		return w
	}
	for win in w.children {
		if win_found := win.find_window(window_id) {
			return win_found
		}
	}
	return none
}

pub fn (mut w Window) begin_frame() {
	// Make *this* window's context the current
	w.set_current()
}

// title returns the title of the window
pub fn (w &Window) title() string {
	c_str := sdl.get_window_title(w.handle)
	return unsafe { cstring_to_vstring(c_str) }
}

// set_title sets the title of the window.
pub fn (mut w Window) set_title(title string) {
	sdl.set_window_title(w.handle, title.str)
}

// set_icon sets the icon of window.
pub fn (mut w Window) set_icon(source AssetSource) ! {
	// TODO https://caedesnotes.wordpress.com/2015/04/13/how-to-integrate-your-sdl2-window-icon-or-any-image-into-your-executable/

	// stbi -> SDL2 surface loading see:
	// https://github.com/DanielGibson/Snippets/blob/master/SDL_stbimage.h#L248
	// SDL_WM_SetIcon(SDL_LoadBMP("icon.bmp"), NULL);
	// SDL_SetWindowIcon(SDL_Window * window, SDL_Surface * icon)

	mut assets := w.shy.assets()

	mut asset := assets.load(
		source: source
	)!

	/*
	image := asset.to[Image](ImageOptions{
		source: source
	})!*/

	// TODO surface should be freed when program ends... :( ...
	// That's a bit yuk if we want to keep Assets agnostic from SDL2
	mut surf := asset.to_sdl_surface(ImageOptions{
		source: source
	})!

	sdl.set_window_icon(w.handle, surf)
	unsafe { shy_free(surf) }
}

@[inline]
pub fn (w Window) fps() u32 {
	return w.state.fps_snapshot
}

pub fn (mut w Window) render_init() {
	s := w.shy

	w.state.fps_timer = u64(0)
	render_config := w.config.render
	// update_rate         = f64(59.95) // TODO
	// update_rate         = f64(120)
	update_rate := render_config.update_rate // f64(60)
	w.state.update_rate = update_rate // f64(60)
	w.state.update_multiplicity = render_config.update_multiplicity // int(1)
	w.state.lock_framerate = render_config.lock_framerate // false
	// w.state.time_history_count = render_config.time_history_count // 4

	// V implementation of:
	// https://medium.com/@tglaiel/how-to-make-your-game-run-at-60fps-24c61210fe75
	// https://gafferongames.com/post/fix_your_timestep/
	// compute how many ticks one update should be

	performance_frequency := s.performance_frequency()
	w.state.performance_frequency = performance_frequency
	w.state.fixed_delta_time = f64(1.0) / update_rate
	w.state.desired_frametime = i64(performance_frequency / update_rate)

	// These are to snap deltaTime to vsync values if it's close enough
	w.state.vsync_maxerror = i64(performance_frequency * f64(0.0002))
	time_60hz := i64(performance_frequency / 60) // since this is about snapping to common vsync values
	// time_60hz := i64(performance_frequency / update_rate)
	w.state.snap_frequencies = [
		time_60hz, // 60fps
		time_60hz * 2, // 30fps
		time_60hz * 3, // 20fps
		time_60hz * 4, // 15fps
		(time_60hz + 1) / 2, // 120fps
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

	$if shy_record ? {
		w.step(1, w.state.update_rate)
	}
}

// render renders one frame
pub fn (mut w Window) tick_and_render[T](mut ctx T) {
	if !w.ready {
		return
	}
	mut s := w.shy

	w.state.fps_frame++
	w.state.frame++

	now := s.ticks()

	// count fps in 1 sec (1000 ms)
	if w.mode == .immediate && now >= w.state.fps_timer + 1000 {
		w.state.fps_timer = now
		w.state.fps_snapshot = w.state.fps_frame // - 1
		w.state.fps_frame = 0
	}

	// frame timer
	current_frame_time := i64(s.performance_counter())
	mut delta_time := current_frame_time - w.state.prev_frame_time
	w.state.prev_frame_time = current_frame_time

	desired_frametime := w.state.desired_frametime

	// handle unexpected timer anomalies (overflow, extra slow frames, etc)
	// ignore extra slow frames
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
	time_history_count := w.state.time_averager.len
	for i in 0 .. time_history_count - 1 {
		w.state.time_averager[i] = w.state.time_averager[i + 1]
	}
	w.state.time_averager[time_history_count - 1] = delta_time
	delta_time = 0
	// for i := 0; i < time_history_count; i++ {
	for i in 0 .. time_history_count {
		delta_time += w.state.time_averager[i]
	}
	delta_time /= time_history_count

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

	fixed_delta_time := w.state.fixed_delta_time

	// TODO the rendering internals is messy, should be cleaned up
	// It is also here the rendering is decoupled from the game ticks
	// via the opportunity to call `fixed_update` and `variable_update`
	// at what ever intervals one wishes. Manual control of this process
	// is implemented in in the `.step` mode below.

	// Mode implementations:
	//
	// `.ui` non-immediate mode / GUI mode
	// rendering is only done if w.refresh() is called.
	// All this should probably also be in the stepper?
	// Make Shy orchestrate the update of each window instead?
	if w.mode == .ui {
		fixed_dt := 1 / w.state.update_rate

		w.state.fps_frame--
		w.state.frame--

		if w.refresh_config.sleep == 0 {
			w.begin_frame()
			ctx.frame_begin()
		}

		// do_sleep := !w.is_dirty
		if w.is_dirty {
			w.state.fps_frame++
			w.state.frame++

			if w.refresh_config.sleep > 0 {
				w.begin_frame()
				ctx.frame_begin()
			}

			if now >= w.state.fps_timer + 1000 {
				w.state.fps_timer = now
				w.state.fps_snapshot = w.state.fps_frame // - 1
				w.state.fps_frame = 0
			}

			w.fixed_update(fixed_dt)
			ctx.fixed_update(fixed_dt)
			w.variable_update(fixed_dt)
			ctx.variable_update(fixed_dt)

			if w.refresh_config.sleep > 0 {
				w.state.in_frame_call = true
				s.scripts().on_frame(1.0) // TODO remove me again
				ctx.frame(1.0)
				ctx.frame_end()
				w.end_frame()
			}
			w.is_dirty = false
		}

		if w.refresh_config.sleep == 0 {
			w.state.in_frame_call = true
			s.scripts().on_frame(1.0) // TODO remove me again
			ctx.frame(1.0)
			ctx.frame_end()
			w.end_frame()
		}

		if w.refresh_config.sleep > 0 {
			time.sleep(w.refresh_config.sleep) // TODO ??
		}
	} else {
		w.begin_frame()
		ctx.frame_begin()
		if w.mode == .immediate {
			// UNLOCKED FRAMERATE, INTERPOLATION ENABLED
			if !w.state.lock_framerate {
				mut consumed_delta_time := delta_time

				for w.state.frame_accumulator >= desired_frametime {
					// eprintln('(unlocked) s.fixed_update( $fixed_delta_time )')
					w.fixed_update(fixed_delta_time)
					ctx.fixed_update(fixed_delta_time)

					if consumed_delta_time > desired_frametime {
						// cap variable update's dt to not be larger than fixed update,
						// and interleave it (so game state can always get the animation frames it needs)

						// eprintln('(unlocked) 1 ctx.variable_update( $fixed_delta_time )')
						w.variable_update(fixed_delta_time)
						ctx.variable_update(fixed_delta_time)

						consumed_delta_time -= desired_frametime
					}
					w.state.frame_accumulator -= desired_frametime
				}

				c_dt := f64(consumed_delta_time) / s.performance_frequency()
				// eprintln('(unlocked) 2 ctx.variable_update( $c_dt )')
				w.variable_update(c_dt)
				ctx.variable_update(c_dt)

				f_dt := f64(w.state.frame_accumulator) / desired_frametime
				// eprintln('(unlocked) ctx.frame( $f_dt )')
				w.state.in_frame_call = true
				s.scripts().on_frame(f_dt) // TODO remove me again
				ctx.frame(f_dt)
			} else { // LOCKED FRAMERATE, NO INTERPOLATION
				for w.state.frame_accumulator >= desired_frametime * w.state.update_multiplicity {
					for i := 0; i < w.state.update_multiplicity; i++ {
						// eprintln('(locked) ctx.fixed_update( $fixed_delta_time )')
						w.fixed_update(fixed_delta_time)
						ctx.fixed_update(fixed_delta_time)

						// eprintln('(locked) ctx.variable_update( $fixed_delta_time )')
						w.variable_update(fixed_delta_time)
						ctx.variable_update(fixed_delta_time)
						w.state.frame_accumulator -= desired_frametime
					}
				}

				// eprintln('(locked) ctx.frame( 1.0 )')
				w.state.in_frame_call = true
				s.scripts().on_frame(1.0) // TODO remove me again
				ctx.frame(1.0)
			}
		} else {
			// MANUAL STEPPING via Window.step(...)
			if w.mode == .step {
				// w.state.fps_frame = u32(w.stepper.rate)
				w.state.frame--

				fixed_dt := 1 / w.stepper.rate
				// rate_sim_sleep := i64((fixed_dt * 1000 * 1000) / (w.children.len + 1))

				if w.stepper.step > 0 {
					// time.sleep(rate_sim_sleep * time.microsecond) // TODO ??

					w.stepper.step--
					w.state.frame++

					w.fixed_update(fixed_dt)
					ctx.fixed_update(fixed_dt)
					w.variable_update(fixed_dt)
					ctx.variable_update(fixed_dt)
				}
				w.state.in_frame_call = true
				s.scripts().on_frame(1.0) // TODO remove me again
				ctx.frame(1.0)
			}
		}
		ctx.frame_end()
		w.end_frame()
	}

	for mut cw in w.children {
		cw.tick_and_render[T](mut ctx)
	}
}

fn (mut w Window) variable_update(dt f64) {
	w.timers.update(dt)
	w.anims.update(dt)
	if w.mode == .ui {
		if w.timers.active() || w.anims.active() {
			w.refresh(w.refresh_config)
		}
	}
}

fn (mut w Window) fixed_update(dt f64) {}

pub fn (mut w Window) end_frame() {
	w.record_frame() // NOTE Compiled out unless using `-d shy_record`
	w.state.in_frame_call = false

	w.shy.api.gfx.commit()

	// display() / swap buffers for this window/GL context's frame
	w.swap()
}

pub fn (w &Window) swap() {
	sdl.gl_swap_window(w.handle)
	analyse.count('${@MOD}.${@STRUCT}(${w.id}).${@FN}', 1)
}

pub fn (w Window) is_root() bool {
	return w.id == root_window_id
}

pub fn (mut w Window) new_window(config WindowConfig) !&Window {
	win := w.shy.api.wm.new_window(config)!
	unsafe {
		win.parent = w
	}
	w.children << win
	return win
}

pub fn (w &Window) set_current() {
	unsafe {
		w.shy.api.wm.active = w
	}
	sdl.gl_make_current(w.handle, w.gl_context)
	unsafe {
		w.shy.api.gfx.activate_context(w.gfx)
	}
}

pub fn (mut w Window) init() ! {
	w.shy.log.gdebug('${@STRUCT}.${@FN}', '')
	mut s := w.shy

	// $if opengl ? {
	// SDL_GL_SetAttribute(SDL_GL_ACCELERATED_VISUAL, HARDWARE_RENDERING);

	$if wasm32_emscripten {
		// Compile with:
		// -sUSE_WEBGL2=1 // Remember WebGL2 = GL ES 3
		// -D SOKOL_GLES3
		sdl.gl_set_attribute(.context_profile_mask, int(sdl.GLprofile.es))
		sdl.gl_set_attribute(.context_major_version, 3)
		sdl.gl_set_attribute(.context_minor_version, 0)
	} $else $if android {
		sdl.gl_set_attribute(.context_profile_mask, int(sdl.GLprofile.es))
		// sdl.gl_set_attribute(.context_major_version, 2)
		sdl.gl_set_attribute(.context_major_version, 3)
	} $else {
		sdl.gl_set_attribute(.context_flags, int(sdl.GLcontextFlag.forward_compatible_flag))
		sdl.gl_set_attribute(.context_profile_mask, int(sdl.GLprofile.core))
		sdl.gl_set_attribute(.context_major_version, 4)
		sdl.gl_set_attribute(.context_minor_version, 1)
	}
	sdl.gl_set_attribute(.doublebuffer, 1)
	sdl.gl_set_attribute(.depth_size, 24)
	sdl.gl_set_attribute(.stencil_size, 8)
	//

	if s.config.render.msaa > 0 {
		s.log.gdebug('${@STRUCT}.${@FN}', 'enabling MSAA (Multi-Sample AntiAliasing)')
		sdl.gl_set_attribute(.multisamplebuffers, 1)

		// Setting multi-samples here will result in SDL applying yet another pass of anti-aliasing...
		sdl.gl_set_attribute(.multisamplesamples, s.config.render.msaa)
	}

	gl_context := sdl.gl_create_context(w.handle)
	if gl_context == sdl.null {
		sdl_error_msg := unsafe { cstring_to_vstring(sdl.get_error()) }
		s.log.gerror('${@STRUCT}.${@FN}', 'SDL: ${sdl_error_msg}')
		return error('Could not create OpenGL context, SDL says:\n${sdl_error_msg}')
	}
	w.gl_context = gl_context

	sdl.gl_make_current(w.handle, w.gl_context)

	$if !shy_no_vsync ? {
		s.log.gdebug('${@STRUCT}.${@FN}', 'vsync=${w.config.render.vsync}')
		w.set_vsync(w.config.render.vsync) or {
			return error('${err}\nuse: -d shy_no_vsync to disable setting the swap interval on start up.')
		}
	}
	// } // end $if opengl

	// Initialize main graphics system if it's not already initialized
	if !s.api.gfx.ready {
		// if w.id == 0 {
		s.api.gfx.init()!
	}

	// Change all contexts to this window's
	unsafe {
		w.shy.api.wm.active = w
	}
	w.gfx = w.shy.api.gfx.make_context()!

	// Set this window's graphics context as the current
	w.set_current()

	w.anims = &Anims{
		shy: s
	}
	w.anims.init()!

	w.timers = &Timers{
		shy: s
	}
	w.timers.init()!

	w.render_init()

	w.Rect.x, w.Rect.y = w.position()
	w.Rect.width, w.Rect.height = w.wh()

	// NOTE: pure function `on_window_event` used instead of closure (w.on_event) for better support on platforms that does not support closures
	w.shy.api.events.on_event(on_window_event)

	w.ready = true
}

pub fn (mut w Window) close() ! {
	w.ready = false
	w.shy.log.gdebug('${@STRUCT}.${@FN}', '')
	w.shutdown()!
}

pub fn (mut w Window) reset() ! {
	w.shy.log.gdebug('${@STRUCT}.${@FN}', '')
	for mut window in w.children {
		window.reset()!
	}
	w.state.reset()
	w.stepper.reset()
	w.anims.reset()!
	w.timers.reset()!
}

pub fn (mut w Window) shutdown() ! {
	w.shy.log.gdebug('${@STRUCT}.${@FN}', '')
	for mut window in w.children {
		window.close()!
	}
	w.anims.shutdown()!
	unsafe { shy_free(w.anims) }

	w.timers.shutdown()!
	unsafe { shy_free(w.timers) }

	w.set_current()

	w.shy.api.gfx.shutdown_context(w.gfx)!

	// NOTE Last window shuts down the graphics module
	if w.id == root_window_id {
		w.shy.api.gfx.shutdown()!
	}

	sdl.gl_delete_context(w.gl_context)
	// }
	sdl.destroy_window(w.handle)
}

fn on_window_event(s &Shy, e Event) bool {
	if e !is WindowResizeEvent && e !is WindowMoveEvent {
		return false
	}
	mut api := unsafe { s.api() }
	match e {
		WindowResizeEvent, WindowMoveEvent {
			if mut w := api.wm().find_window(e.window_id) {
				return w.on_event(e)
			}
			return false
		}
		else {
			return false
		}
	}
	return false
}

fn (mut w Window) on_event(e Event) bool {
	if e !is WindowResizeEvent && e !is WindowMoveEvent {
		return false
	}
	match e {
		WindowResizeEvent {
			if e.window_id == w.id {
				w.Rect.width = e.width
				w.Rect.height = e.height
			}
			return false
		}
		WindowMoveEvent {
			if e.window_id == w.id {
				w.Rect.x = e.x
				w.Rect.y = e.y
			}
			return false
		}
		else {
			return false
		}
	}
	return false
}

pub fn (mut w Window) set_vsync(vsync VSync) ! {
	w.shy.log.gdebug('${@STRUCT}.${@FN}', '')
	match vsync {
		.off {
			if sdl.gl_set_swap_interval(0) < 0 {
				sdl_error_msg := unsafe { cstring_to_vstring(sdl.get_error()) }
				w.shy.log.gerror('${@STRUCT}.${@FN}', 'SDL: ${sdl_error_msg}')
				return error('Could not set OpenGL swap interval (vsync .off). SDL error: ${sdl_error_msg}')
			}
		}
		.on {
			if sdl.gl_set_swap_interval(1) < 0 {
				sdl_error_msg := unsafe { cstring_to_vstring(sdl.get_error()) }
				w.shy.log.gerror('${@STRUCT}.${@FN}', 'SDL: ${sdl_error_msg}')
				return error('Could not set OpenGL swap interval (vsync .on). SDL error: ${sdl_error_msg}')
			}
		}
		.adaptive {
			if sdl.gl_set_swap_interval(-1) < 0 {
				sdl_error_msg := unsafe { cstring_to_vstring(sdl.get_error()) }
				w.shy.log.gerror('${@STRUCT}.${@FN}', 'SDL: ${sdl_error_msg}')
				return error('Could not set OpenGL swap interval (vsync .adaptive). SDL error: ${sdl_error_msg}')
			}
		}
	}
}

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

pub fn (w &Window) x() int {
	mut x := 0
	sdl.get_window_position(w.handle, &x, sdl.null)
	return x
}

pub fn (w &Window) y() int {
	mut y := 0
	sdl.get_window_position(w.handle, sdl.null, &y)
	return y
}

pub fn (w &Window) position() (int, int) {
	mut x, mut y := 0, 0
	sdl.get_window_position(w.handle, &x, &y)
	return x, y
}

pub fn (w &Window) wh() (int, int) {
	mut width, mut height := 0, 0
	sdl.get_window_size(w.handle, &width, &height)
	return width, height
}

pub fn (w &Window) size() Size {
	mut width, mut height := 0, 0
	sdl.get_window_size(w.handle, &width, &height)
	return Size{
		width:  width
		height: height
	}
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

pub fn (w &Window) canvas() Canvas {
	mut width := 0
	mut height := 0

	// $if wasm32_emscripten ? {
	// 	if w.state.frame % 100 == 0
	// 		&& C.emscripten_get_canvas_element_size(c'#canvas', &width, &height) == .success {
	// 		println('WH: ${w.wh()}')
	// 		//sdl.set_window_size(w.handle, width, height)
	// 		// sdl.gl_delete_context(w.gl_context)
	// 		// gl_context := sdl.gl_create_context(w.handle)
	// 		// if gl_context == sdl.null {
	// 		// 	sdl_error_msg := unsafe { cstring_to_vstring(sdl.get_error()) }
	// 		// 	w.shy.log.gerror('${@STRUCT}.${@FN}', 'SDL: ${sdl_error_msg}')
	// 		// 	panic('Could not create OpenGL context, SDL says:\n${sdl_error_msg}')
	// 		// }
	// 		// mut mw := unsafe{ w}
	// 		// mw.gl_context = gl_context
	// 	}
	// }

	// mut linked_version := sdl.Version{}
	// sdl.get_version(mut linked_version)
	// if linked_version.minor_version >= 26 {
	// TODO on SDL2 >= 2.26.0 void SDL_GetWindowSizeInPixels(SDL_Window * window, int *w, int *h);
	//	sdl.get_window_size_in_pixels(w.handle, &width, &height);
	//} else {
	// $if opengl ? {
	sdl.gl_get_drawable_size(w.handle, &width, &height)
	// }
	//}
	ww, wh := w.wh()
	dw, dh := width, height
	mut factor_x := f32(1)
	mut factor_y := f32(1)
	if ww != dw || wh != dh {
		factor_x = f32(dw) / ww
		factor_y = f32(dh) / wh
	}
	return Canvas{
		width:    width
		height:   height
		factor:   mth.min(f32(dw) / ww, f32(dh) / wh)
		factor_x: factor_x
		factor_y: factor_y
	}
}

@[deprecated: 'use Window.canvas().wh() instead']
@[deprecated_after: '2024-08-30']
pub fn (w &Window) drawable_wh() (int, int) {
	return w.canvas().wh()
}

@[deprecated: 'use Window.canvas().size() instead']
@[deprecated_after: '2024-08-30']
pub fn (w &Window) drawable_size() Size {
	return w.canvas().size()
}

@[deprecated: 'use Window.canvas().factor_xy() instead']
@[deprecated_after: '2024-08-30']
pub fn (w &Window) draw_factor_xy() (f32, f32) {
	return w.canvas().factor_xy()
}

@[deprecated: 'use Window.canvas().factor instead']
@[deprecated_after: '2024-08-30']
pub fn (w &Window) draw_factor() f32 {
	return w.canvas().factor
}
