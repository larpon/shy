// Copyright(C) 2023 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module main

import shy.lib as shy
import shy.embed
import time

const init_text_part = 'Recording events...\n'

fn main() {
	mut app := &App{}
	shy.run[App](mut app)!
}

@[heap]
pub struct App {
	embed.ExampleApp
mut:
	fa_x  &shy.FollowAnimator[f32] = shy.null
	fa_y  &shy.FollowAnimator[f32] = shy.null
	a_r   &shy.Animator[f32]       = shy.null
	timer time.StopWatch           = time.new_stopwatch()
	text  string
}

pub fn (mut a App) init() ! {
	a.ExampleApp.init()!

	mut events := a.shy.events()
	events.record()

	a.text = '${init_text_part}Press "P" to playback recorded events'

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
		loop:  .pingpong
	}

	a.a_r = a.shy.new_animator[f32](a_config)

	if !a.a_r.running {
		a.a_r.init(0, 360, 5000)
		a.a_r.run()
	}
}

pub fn (mut a App) frame(dt f64) {
	mouse := a.mouse

	rotation := f32(a.a_r.value()) * shy.deg2rad

	a.fa_x.target = mouse.x
	a.fa_y.target = mouse.y

	text := a.text + '
rect.x ${a.fa_x.value}
rect.y ${a.fa_y.value}'

	a.quick.rect(
		x:        a.fa_x.value
		y:        a.fa_y.value
		rotation: rotation
		origin:   shy.Anchor.center
	)

	a.quick.text(
		x:      a.window.width * 0.01
		y:      a.window.height * 0.01
		origin: shy.Anchor.top_left
		text:   text
	)
}

pub fn (mut a App) event(e shy.Event) {
	a.ExampleApp.event(e)

	match e {
		shy.KeyEvent {
			if e.state == .up {
				match e.key_code {
					.r {
						mut events := a.shy.events()
						if events.state == .normal {
							events.record()
						}
					}
					.p {
						if !a.text.contains('"R"') {
							a.text = 'Press "R" to record events\n' +
								a.text.replace(init_text_part, '')
						}
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
