// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module solid

// Base app skeleton for easy embedding in examples
struct App {
mut:
	solid &Solid = unsafe { nil } // Initialized by solid.run<T>(...)
}

pub fn (mut a App) init() ! {}

pub fn (mut a App) quit() {}

pub fn (mut a App) fixed_update(dt f64) {}

pub fn (mut a App) variable_update(dt f64) {}

pub fn (mut a App) frame(dt f64) {}

pub fn (mut a App) event(e Event) {}

// Simple app skeleton for easy embedding in examples
struct BasicApp {
	App
}

pub fn (mut a BasicApp) event(e Event) {
	a.on_event(e)
}

fn (mut a BasicApp) on_event(e Event) {
	match e {
		QuitEvent {
			a.solid.shutdown = true
		}
		KeyEvent {
			if e.state == .up {
				return
			}
			key := e.key_code
			match key {
				.escape {
					a.solid.shutdown = true
				}
				else {
					alt_is_held := (a.solid.key_is_down(.lalt) || a.solid.key_is_down(.ralt))
					if key == .f || key == .f11 || (key == .@return && alt_is_held) {
						mut win := a.solid.wm.active_window()
						win.toggle_fullscreen()
					}
				}
			}
		}
		// MouseMotionEvent {
		// 	a.solid.api.mouse.show()
		// }
		else {}
	}
}

// Example app skeleton for all the examples
struct ExampleApp {
	BasicApp
}

// Developer app skeleton
struct DevApp {
	BasicApp
}

pub fn (mut a DevApp) event(e Event) {
	a.on_event(e)
	a.BasicApp.on_event(e)
}

pub fn (mut a DevApp) on_event(e Event) {
	mut s := a.solid
	// Handle debug output control here
	if e is KeyEvent {
		key_code := e.key_code
		if e.state == .down {
			if s.key_is_down(.comma) {
				if key_code == .s {
					s.log.print_status('STATUS')
					return
				}

				if key_code == .f1 {
					s.log.ginfo(@STRUCT + '.' + 'performance', 'Current FPS $s.fps()')
					return
				}

				if key_code == .f2 {
					s.log.ginfo(@STRUCT + '.' + 'performance', 'Current Performance Count $s.api.performance_counter()')
					return
				}

				if key_code == .f3 {
					s.log.ginfo(@STRUCT + '.' + 'performance', 'Current Performance Frequency $s.api.performance_frequency()')
					return
				}

				// Log print control
				if s.key_is_down(.l) {
					s.log.on(.log)

					if key_code == .f {
						s.log.toggle(.flood)
						return
					}
					if key_code == .minus || s.key_is_down(.minus) {
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
