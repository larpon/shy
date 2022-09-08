// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module main

import shy.shy

fn main() {
	mut app := &App{}
	shy.run<App>(mut app)!
}

[heap]
struct App {
	shy.ExampleApp
}

[markused]
pub fn (mut a App) frame(dt f64) {
	mx := a.mouse.x
	my := a.mouse.y
	mut buttons := ['', '', '']!
	if a.mouse.is_button_down(.left) {
		buttons[0] = 'left'
	}
	if a.mouse.is_button_down(.middle) {
		buttons[1] = 'middle'
	}
	if a.mouse.is_button_down(.right) {
		buttons[2] = 'right'
	}
	a.easy.text(
		x: mx + 10
		y: my + 20
		text: 'Shy Mouse at $mx,$my\n$buttons'
	)
}
