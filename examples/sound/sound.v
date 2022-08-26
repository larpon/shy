// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module main

import shy

fn main() {
	mut app := &App{}
	shy.run<App>(mut app)!
}

[heap]
struct App {
	shy.ExampleApp
}

[markused]
pub fn (mut a App) init() ! {
	a.ExampleApp.init()! // IMPORTANT Let the embed initialize before us

	// asset_path is a method of the ExampleApp embed to make it easier to get example assets
	sound := a.asset_path('sfx/shy_sound_01.wav')
	a.easy.load_audio('sound 1', sound)!
}

[live; markused]
pub fn (mut a App) frame(dt f64) {
	a.easy.text(
		text: 'Press a key or click in window to play a sound'
	)
}

[markused]
pub fn (mut a App) event(e shy.Event) {
	a.ExampleApp.event(e) // IMPORTANT Let the embed handle it's events before us

	match e {
		shy.MouseButtonEvent, shy.KeyEvent {
			if e.state == .down {
				a.easy.play_audio(
					id: 'sound 1'
				)
			}
		}
		else {}
	}
}
