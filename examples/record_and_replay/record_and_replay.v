// Copyright(C) 2023 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module main

import shy.lib as shy
import shy.embed
import time

fn main() {
	mut app := &App{}
	shy.run[App](mut app)!
}

[heap]
struct App {
	embed.ExampleApp
mut:
	fa_x  &shy.FollowAnimator[f32] = shy.null
	fa_y  &shy.FollowAnimator[f32] = shy.null
	a_r   &shy.Animator[f32]       = shy.null
	timer time.StopWatch = time.new_stopwatch()
	text  string
}

[markused]
pub fn (mut a App) init() ! {
	a.ExampleApp.init()!

	a.fa_x = a.shy.new_follow_animator[f32]()
	a.fa_y = a.shy.new_follow_animator[f32]()

	a_config := shy.AnimatorConfig{
		/*
		ease: ease.Ease{
			kind: .sine
			mode: .in_out
			// custom_fn: custom_ease
		}*/
		// recycle: true
		loops: shy.infinite
		loop: .pingpong
	}

	a.a_r = a.shy.new_animator[f32](a_config)

	if !a.a_r.running {
		a.a_r.init(0, 360, 5000)
		a.a_r.run()
	}
}

[markused]
pub fn (mut a App) frame(dt f64) {
	mouse := a.mouse

	rotation := f32(a.a_r.value()) * shy.deg2rad

	a.fa_x.target = mouse.x
	a.fa_y.target = mouse.y

	a.text = 'Press "R" key to start recording
Press "P" to playback the recorded events
rect.x ${a.fa_x.value}
rect.y ${a.fa_y.value}'

	a.quick.rect(
		x: a.fa_x.value
		y: a.fa_y.value
		rotation: rotation
		origin: .center
	)

	a.quick.text(
		x: a.canvas().width * 0.01
		y: a.canvas().height * 0.01
		origin: .top_left
		text: a.text
	)
}

[markused]
pub fn (mut a App) event(e shy.Event) {
	a.ExampleApp.event(e)

	match e {
		shy.KeyEvent {
			if e.state == .up {
				match e.key_code {
					.r {
						mut events := a.shy.events()
						events.record()
					}
					.p {
						mut events := a.shy.events()
						events.play_back()
					}
					else {}
				}
			}
		}
		shy.MouseButtonEvent {
			if e.state == .down {
			}
		}
		shy.RecordEvent {}
		else {}
	}
}
