// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module main

import shy.lib as shy
import shy.embed

fn main() {
	mut app := &App{}
	shy.run[App](mut app)!
}

@[heap]
pub struct App {
	embed.ExampleApp
}

pub fn (mut a App) frame(dt f64) {
	a.quick.text(
		text: 'Hello Shy World!'
	)
}
