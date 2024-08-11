// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module main

import shy.lib as shy
import shy.embed
import shy.ui

fn main() {
	mut app := &App{}
	shy.run[App](mut app)!
}

@[heap]
struct App {
	embed.ExampleApp //
mut:
	ui &ui.UI = shy.null
}

@[markused]
pub fn (mut a App) init() ! {
	a.ExampleApp.init()!

	a.window.mode = .ui

	root := &ui.Rectangle{
		width:  a.window.width
		height: a.window.height
		fills:  .body
		body:   [
			&ui.Button{
				x:      50
				y:      50
				width:  50
				height: 50
				label:  'Hello World'
			},
		]
	}
	a.ui = ui.new(
		shy:  a.shy
		easy: a.easy
		root: root
	)!
}

@[markused]
pub fn (mut a App) update(dt f64) {
	a.ui.update()
}

@[markused]
pub fn (mut a App) frame(dt f64) {
	// win := a.window
	a.ui.draw(dt)
}

@[markused]
pub fn (mut a App) event(e shy.Event) {
	a.ExampleApp.event(e)
	a.window.refresh() // In case we're running in UI mode signal that we want the screen to be re-drawn on next frame.

	ui_event := ui.shy_to_ui_event(e) or { panic('${@STRUCT}.${@FN}: ${err}') }
	if handled_by_node := a.ui.event(ui_event) {
		// BUG: printing the whole node will make things crash at runtime...
		println('Event was handled by ui.Node.id(${handled_by_node.id})')
	}
}
