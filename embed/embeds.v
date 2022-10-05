// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module embed

import os
import time
import shy.lib as shy
import shy.easy

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

pub fn (mut a App) frame(dt f64) {}

pub fn (mut a App) event(e shy.Event) {}

// Simple app skeleton for easy embedding in e.g. examples
pub struct EasyApp {
	App
mut:
	quick  easy.Quick
	easy   &easy.Easy    = shy.null
	assets &shy.Assets   = shy.null
	draw   &shy.Draw     = shy.null
	mouse  &shy.Mouse    = shy.null
	kbd    &shy.Keyboard = shy.null
	window &shy.Window   = shy.null
}

pub fn (mut a EasyApp) init() ! {
	a.App.init()!
	a.easy = &easy.Easy{
		shy: a.shy
	}
	unsafe {
		a.quick.easy = a.easy
	}
	a.easy.init()!
	a.assets = a.shy.assets()
	a.draw = a.shy.draw()
	api := unsafe { a.shy.api() }
	a.mouse = api.input().mouse(0)!
	a.kbd = api.input().keyboard(0)!
	a.window = api.wm().active_window()
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
						a.shy.log.gerror('${@STRUCT}.${@FN}', '$err')
					}
					a.shy.log.ginfo('${@STRUCT}', 'saved screenshot to "$shot_file"')
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
					s.log.ginfo('${@STRUCT}.${@FN}', 'Current FPS $w.fps()')
					return
				}

				if key_code == .f2 {
					s.log.ginfo('${@STRUCT}.${@FN}', 'Current Performance Count $s.performance_counter()')
					return
				}

				if key_code == .f3 {
					s.log.ginfo('${@STRUCT}.${@FN}', 'Current Performance Frequency $s.performance_frequency()')
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
