// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module main

import shy.lib as shy
import shy.easy
import shy.embed
import time

const info = 'Press "T" or left-click\nto start a new timer'
const wait = 'Wait for it...'

fn main() {
	mut app := &App{}
	shy.run[App](mut app,
		window: shy.WindowConfig{
			width:  600
			height: 400
		}
	)!
}

@[heap]
pub struct App {
	embed.ExampleApp
mut:
	info_text  &easy.Text = shy.null
	once_text  &easy.Text = shy.null
	clock_text &easy.Text = shy.null
	since      u64
}

pub fn (mut a App) init() ! {
	a.ExampleApp.init()!

	size := a.window.size()

	a.once_text = a.easy.new_text(
		x:      shy.half * size.width
		y:      shy.half * size.height
		size:   50
		origin: shy.Anchor.center
		align:  .center
	)

	a.info_text = a.easy.new_text(
		x:      shy.half * size.width
		y:      10
		origin: shy.Anchor.top_center
		align:  .center
		text:   info
	)

	a.clock_text = a.easy.new_text(
		y:      size.height
		origin: shy.Anchor.bottom_left
		text:   'Local time: ${time.now().format_ss()}'
	)

	a.shy.every(fn (t &shy.Timer) {
		mut a := t.shy.app[App]()
		a.clock_text.text = 'Local time: ${time.now().format_ss()}'
	}, 1000, shy.infinite)
}

pub fn (mut a App) frame(dt f64) {
	size := a.window.size()
	a.info_text.x = shy.half * size.width
	a.once_text.x = shy.half * size.width
	a.once_text.y = shy.half * size.height
	a.clock_text.y = size.height

	a.info_text.draw()
	a.once_text.draw()
	a.clock_text.draw()
}

pub fn (mut a App) event(e shy.Event) {
	a.ExampleApp.event(e)

	match e {
		shy.KeyEvent {
			if e.state == .up {
				return
			}
			key := e.key_code
			match key {
				.t {
					a.info_text.text = '${info}\nLast timer started at frame ${a.window.state.frame}\n(via "T" on the keyboard)'
					a.once_text.text = '${wait}'
					a.since = a.window.state.frame
					a.shy.once(fn (t &shy.Timer) {
						mut a := t.shy.app[App]()
						took := a.window.state.frame - a.since
						a.once_text.text = 'Time is up, it took ${took} frames to trigger!\n(since "T" was pressed on the keyboard)'
					}, 1000)
				}
				else {}
			}
		}
		shy.MouseButtonEvent {
			if e.state == .down {
				a.info_text.text = '${info}\nLast timer started at frame ${a.window.state.frame}\n(via mouse click)'
				a.once_text.text = '${wait}'
				a.since = a.window.state.frame
				a.shy.once(fn (t &shy.Timer) {
					mut a := t.shy.app[App]()
					took := a.window.state.frame - a.since
					a.once_text.text = 'Time is up, it took ${took} frames to trigger!\n(since the mouse was clicked)'
				}, 1000)
			}
		}
		else {}
	}
}
