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

@[heap]
struct App {
	embed.ExampleApp
mut:
	a_r &shy.Animator[f32] = shy.null
}

pub fn (mut a App) init() ! {
	a.ExampleApp.init()!
	a.a_r = a.shy.new_animator[f32](
		ease:  ease.Ease{
			kind: .sine // .back
			mode: .in_out
		}
		loops: shy.infinite
		loop:  .pingpong
	)
	if !a.a_r.running {
		a.a_r.init(10, 500, 2500)
		a.a_r.run()
	}
}

pub fn (mut a App) frame(dt f64) {
	a.quick.circle(
		x:      (shy.half * a.window.width)
		y:      (shy.half * a.window.height)
		radius: a.a_r.value()
		stroke: shy.Stroke{
			width: 10
			color: shy.rgba(255, 255, 255, 127)
		}
	)
}
