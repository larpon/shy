// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module main

import shy.lib as shy
import shy.easy
import shy.embed

fn main() {
	mut app := &App{}
	shy.run[App](mut app)!
}

[heap]
struct App {
	embed.ExampleApp
mut:
	sound &easy.EasySound = shy.null
}

[markused]
pub fn (mut a App) init() ! {
	a.ExampleApp.init()!

	a.sound = a.easy.new_sound(
		path: a.ExampleApp.asset('sfx/shy.wav')
		// Allows for repeating the sound on top of itself `max_repeats` amount of times.
		// NOTE consumes memory for each repeat instance.
		max_repeats: 4
	)!
}

[markused]
pub fn (mut a App) frame(dt f64) {
	is_looping_str := if a.sound.is_looping() { 'looping' } else { 'not looping' }
	is_playing_str := if a.sound.is_playing() { 'playing' } else { 'not playing' }
	a.quick.text(
		text: 'Press a key, touch or click in window to play a sound\nPress "L" to loop (currently ${is_looping_str})\nSound is ${is_playing_str}'
	)
}

[markused]
pub fn (mut a App) event(e shy.Event) {
	a.ExampleApp.event(e)

	match e {
		shy.KeyEvent {
			if e.state == .down {
				match e.key_code {
					.l {
						a.sound.loop = !a.sound.loop
					}
					else {}
				}
				a.sound.play()
			}
		}
		shy.MouseButtonEvent {
			if e.state == .down {
				a.sound.play()
			}
		}
		else {}
	}
}
