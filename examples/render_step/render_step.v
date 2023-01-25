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

[heap]
struct App {
	embed.ExampleApp //
mut:
	a_r &shy.Animator[f32] = shy.null
	a_s &shy.Animator[f32] = shy.null
}

[markused]
pub fn (mut a App) init() ! {
	a.ExampleApp.init()!
	a.a_r = a.shy.new_animator[f32](
		ease: ease.Ease{
			kind: .sine
			mode: .in_out
		}
		recycle: true
		loops: shy.infinite
		loop: .pingpong
	)
	a.a_s = a.shy.new_animator[f32](
		ease: ease.Ease{
			kind: .back
			mode: .in_out
		}
		recycle: true
		loops: shy.infinite
		loop: .pingpong
	)
	a.window.step(1, 60)
}

[markused]
pub fn (mut a App) frame(dt f64) {
	if !a.a_r.running {
		a.a_r.init(-5, 5, 1500)
		a.a_r.run()
	}
	if !a.a_s.running {
		a.a_s.init(0.8, 1.1, 1500)
		a.a_s.run()
	}

	a.quick.rect(
		x: shy.half * a.canvas.width
		y: shy.half * a.canvas.height
		rotation: a.a_r.value() * shy.deg2rad
		scale: a.a_s.value()
		origin: .center
	)

	win := a.window
	a.quick.text(
		x: a.canvas.width * 0.01
		y: a.canvas.height * (1.0 - 0.01)
		origin: .bottom_left
		text: 'Press "s" to step 135 frames, hold "s+shift" to go out of step mode.
Mode: ${win.mode}
Frame: ${win.state.frame}
Update rate ${win.state.update_rate}@hz
FPS: ${win.fps()}'
	)
}

[markused]
pub fn (mut a App) event(e shy.Event) {
	a.ExampleApp.event(e)
	match e {
		shy.KeyEvent {
			if e.state == .up {
				return
			}
			key := e.key_code
			shift_held := a.kbd.is_key_down(.lshift) || a.kbd.is_key_down(.rshift)
			match key {
				.s {
					if !shift_held {
						a.window.step(135, 60)
					} else {
						a.window.unstep()
					}
				}
				else {}
			}
		}
		else {}
	}
}
