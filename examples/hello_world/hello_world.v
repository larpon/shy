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
	a.easy.text(
		text: 'Hello Shy World!'
	)
}
