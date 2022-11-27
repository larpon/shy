// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module main

import shy.lib as shy
import shy.embed
import shy.ease
import time

fn main() {
	mut app := &App{}
	shy.run[App](mut app)!
}

[heap]
struct App {
	embed.ExampleApp
mut:
	a_x   &shy.Animator[f32]       = shy.null
	a_y   &shy.Animator[f32]       = shy.null
	a_r   &shy.Animator[f32]       = shy.null
	a_s   &shy.Animator[f32]       = shy.null
	fa_x  &shy.FollowAnimator[f32] = shy.null
	fa_y  &shy.FollowAnimator[f32] = shy.null
	timer time.StopWatch = time.new_stopwatch()
}

[markused]
pub fn (mut a App) init() ! {
	a.ExampleApp.init()!

	a.a_x = a.shy.new_animator[f32](
		ease: ease.Ease{
			kind: .sine
			mode: .in_out
			// custom_fn: custom_ease
		}
		loops: shy.infinite
		loop: .pingpong
	)

	a.a_y = a.shy.new_animator[f32](
		ease: ease.Ease{
			kind: .sine
			mode: .in_out
		}
		loops: shy.infinite
		loop: .pingpong
	)

	a.a_r = a.shy.new_animator[f32](
		ease: ease.Ease{
			kind: .sine // .back
			mode: .in_out
		}
		loops: shy.infinite
		loop: .pingpong
	)

	a.a_s = a.shy.new_animator[f32](
		ease: ease.Ease{
			kind: .back
			mode: .in_out
		}
		loops: shy.infinite
		loop: .pingpong
	)

	a.fa_x = a.shy.new_follow_animator[f32](multiply: 1.5)
	a.fa_y = a.shy.new_follow_animator[f32](multiply: 1.5)
}

[markused]
pub fn (mut a App) frame(dt f64) {
	win := a.window
	mouse := a.mouse
	mut text := a.easy.text()

	a.fa_x.target = mouse.x
	a.fa_y.target = mouse.y

	text.x = a.a_x.value() + a.fa_x.value() + 10
	text.y = a.a_y.value() + a.fa_y.value() + 10
	text.rotation = a.a_r.value()
	text.scale = a.a_s.value()
	text.text = 'Hello Shy Animated World!'
	text.draw()

	if !a.a_x.running {
		a.timer.start()
		a.a_x.init(0, 50, 2000)
		a.a_x.run()
	}

	if !a.a_y.running {
		a.a_y.init(0, 50, 3000)
		a.a_y.run()
	}
	if !a.a_r.running {
		a.a_r.init(-5, 5, 1500)
		a.a_r.run()
	}
	if !a.a_s.running {
		a.a_s.init(0.8, 1.1, 1500)
		a.a_s.run()
	}

	a.quick.rect(
		x: shy.half * win.width()
		y: shy.half * win.height()
		rotation: a.a_r.value() * shy.deg2rad
		scale: a.a_s.value()
		origin: .center
	)

	es := a.timer.elapsed().seconds()
	a.quick.text(
		x: f32(win.width()) * 0.01
		y: f32(win.height()) * (1.0 - 0.01)
		origin: .bottom_left
		text: 'Animation running for ${es:.1f} seconds
Frame: ${win.state.frame}
follow at ${a.fa_x.value():.1f},${a.fa_y.value():.1f} running: ${a.fa_x.running}
text at ${text.x:.1f},${text.y:.1f} x.t ${a.a_x.t():.4f} ${win.state.update_rate} @hz
FPS: ${win.fps()}'
	)
}
