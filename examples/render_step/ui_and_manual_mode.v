// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module main

import shy.lib as shy
import shy.embed
import shy.ease

fn main() {
	mut app := &App{}
	shy.run[App](mut app)!
}

@[heap]
pub struct App {
	embed.ExampleApp //
mut:
	a_r &shy.Animator[f32] = shy.null
}

@[markused]
pub fn (mut a App) init() ! {
	a.ExampleApp.init()!

	a.a_r = a.shy.new_animator[f32](
		ease: ease.Ease{
			kind: .sine
			mode: .in_out
		}
	)
	a.a_r.init(90, -5, 500)
	a.a_r.run()

	a.window.mode = .ui
}

@[markused]
pub fn (mut a App) frame(dt f64) {
	a.quick.rect(
		x:        shy.half * a.window.width
		y:        shy.half * a.window.height
		rotation: a.a_r.value() * shy.deg2rad
		origin:   shy.Anchor.center
	)

	win := a.window
	text_manual_render := if a.window.mode == .ui { 'Press "r" to render frame.' } else { '' }
	a.quick.text(
		x:      a.window.width * 0.01
		y:      a.window.height * (1.0 - 0.01)
		origin: shy.Anchor.bottom_left
		text:   '${text_manual_render}
Press "m" to toggle window mode.
Press "a" to set new animator.
Mode: ${win.mode}
Frame: ${win.state.frame}
Update rate ${win.state.update_rate} @hz
FPS: ${win.fps()}'
	)
}

@[markused]
pub fn (mut a App) event(e shy.Event) {
	a.ExampleApp.event(e)
	a.window.refresh()
	match e {
		shy.KeyEvent {
			if e.state == .up {
				return
			}
			key := e.key_code
			match key {
				.r {}
				.a {
					if !a.a_r.running {
						end_value := a.a_r.value()
						a.a_r = a.shy.new_animator[f32](
							ease: ease.Ease{
								kind: .sine
								mode: .in_out
							}
						)

						if end_value < 0 {
							a.a_r.init(-5, 5, 1500)
						} else {
							a.a_r.init(5, -5, 1500)
						}
						a.a_r.run()
					}
				}
				.m {
					a.window.mode = a.window.mode.next()

					a.a_r.running = false
					end_value := a.a_r.value()
					if a.window.mode == .immediate {
						a.a_r = a.shy.new_animator[f32](
							ease:  ease.Ease{
								kind: .sine
								mode: .in_out
							}
							loops: shy.infinite
							loop:  .pingpong
						)
					} else {
						a.a_r = a.shy.new_animator[f32](
							ease:  ease.Ease{
								kind: .sine
								mode: .in_out
							}
							loops: shy.infinite
						)
					}

					if end_value < 0 {
						a.a_r.init(-5, 5, 1500)
					} else {
						a.a_r.init(5, -5, 1500)
					}
					a.a_r.run()
				}
				else {}
			}
		}
		else {}
	}
}
