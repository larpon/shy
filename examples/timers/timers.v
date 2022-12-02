// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module main

import shy.lib as shy
import shy.easy
import shy.embed
import time

const (
	info = 'Press "T" or left-click\nto start a new timer'
	wait = 'Wait for it...'
)

fn main() {
	mut app := &App{}
	shy.run[App](mut app,
		window: shy.WindowConfig{
			w: 600
			h: 400
		}
	)!
}

[heap]
struct App {
	embed.ExampleApp
mut:
	info_text  &easy.EasyText = shy.null
	once_text  &easy.EasyText = shy.null
	clock_text &easy.EasyText = shy.null
	since      u64
}

[markused]
pub fn (mut a App) init() ! {
	a.ExampleApp.init()!

	win_size := a.window.size()

	a.once_text = a.easy.new_text(
		x: shy.half * win_size.w
		y: shy.half * win_size.h
		size: 50
		origin: .center
		align: .center
	)

	a.info_text = a.easy.new_text(
		x: shy.half * win_size.w
		y: 10
		origin: .top_center
		align: .center
		text: info
	)

	a.clock_text = a.easy.new_text(
		y: win_size.h
		origin: .bottom_left
		text: 'Local time: ${time.now().format_ss()}'
	)

	a.shy.every(fn [mut a] () {
		a.clock_text.text = 'Local time: ${time.now().format_ss()}'
	}, 1000, shy.infinite)
}

[markused]
pub fn (mut a App) frame(dt f64) {
	win_size := a.window.size()
	a.info_text.x = shy.half * win_size.w
	a.once_text.x = shy.half * win_size.w
	a.once_text.y = shy.half * win_size.h
	a.clock_text.y = win_size.h

	a.info_text.draw()
	a.once_text.draw()
	a.clock_text.draw()
}

[markused]
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
					a.shy.once(fn [mut a] () {
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
				a.shy.once(fn [mut a] () {
					took := a.window.state.frame - a.since
					a.once_text.text = 'Time is up, it took ${took} frames to trigger!\n(since the mouse was clicked)'
				}, 1000)
			}
		}
		else {}
	}
}
