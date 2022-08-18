// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module shy

// Base app skeleton for easy embedding in examples
struct App {
	ShyStruct // Initialized by shy.run<T>(...)
}

pub fn (mut a App) init() ! {}

pub fn (mut a App) quit() {}

pub fn (mut a App) fixed_update(dt f64) {}

pub fn (mut a App) variable_update(dt f64) {}

pub fn (mut a App) frame(dt f64) {}

pub fn (mut a App) event(e Event) {}

// Simple app skeleton for easy embedding in examples
struct EasyApp {
	App
mut:
	easy   &Easy     = shy.null
	draw   &Draw     = shy.null
	mouse  &Mouse    = shy.null
	kbd    &Keyboard = shy.null
	window &Window   = shy.null
}

pub fn (mut a EasyApp) init() ! {
	a.easy = &Easy{
		shy: a.shy
	}
	a.draw = a.shy.api.gfx.draw
	a.mouse = a.shy.api.input.mouse(0)!
	a.kbd = a.shy.api.input.keyboard(0)!
	a.window = a.shy.api.wm.active_window()
}

pub fn (mut a EasyApp) event(e Event) {
	a.on_event(e)
}

fn (mut a EasyApp) on_event(e Event) {
	match e {
		QuitEvent {
			a.shy.shutdown = true
		}
		KeyEvent {
			if e.state == .up {
				return
			}
			key := e.key_code
			match key {
				.escape {
					a.shy.shutdown = true
				}
				else {
					kb := a.kbd
					alt_is_held := (kb.is_key_down(.lalt) || kb.is_key_down(.ralt))
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

// pub fn (mut ea ExampleApp) init()! {
// 	ea.EasyApp.init() !
// }

// Developer app skeleton
struct DevApp {
	EasyApp
}

pub fn (mut a DevApp) event(e Event) {
	a.on_event(e)
	a.EasyApp.on_event(e)
}

pub fn (mut a DevApp) on_event(e Event) {
	mut s := a.shy
	// Handle debug output control here
	if e is KeyEvent {
		key_code := e.key_code
		if e.state == .down {
			kb := a.kbd
			if kb.is_key_down(.comma) {
				if key_code == .s {
					s.log.print_status('STATUS')
					return
				}

				if key_code == .f1 {
					s.log.ginfo(@STRUCT + '.' + 'performance', 'Current FPS $s.fps()')
					return
				}

				if key_code == .f2 {
					s.log.ginfo(@STRUCT + '.' + 'performance', 'Current Performance Count $s.performance_counter()')
					return
				}

				if key_code == .f3 {
					s.log.ginfo(@STRUCT + '.' + 'performance', 'Current Performance Frequency $s.performance_frequency()')
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
