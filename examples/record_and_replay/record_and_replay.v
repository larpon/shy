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
	timer time.StopWatch = time.new_stopwatch()
}

[markused]
pub fn (mut a App) init() ! {
	a.ExampleApp.init()!

	a.fa_x = a.shy.new_follow_animator[f32]()
	a.fa_y = a.shy.new_follow_animator[f32]()
}

[markused]
pub fn (mut a App) frame(dt f64) {
	mouse := a.mouse

	a.fa_x.target = mouse.x
	a.fa_y.target = mouse.y

	a.quick.rect(
		x: a.fa_x.value
		y: a.fa_y.value
		origin: .center
	)

	a.quick.text(
		x: a.canvas().width * 0.01
		y: a.canvas().height * 0.01
		origin: .top_left
		text: 'Press "R" key to start recording\nPress "P" to playback the recorded events'
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
		shy.ResetStateEvent {}
		else {}
	}
}
