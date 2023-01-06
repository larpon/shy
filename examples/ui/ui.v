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

[heap]
struct App {
	embed.ExampleApp //
mut:
	ui &ui.UI = shy.null
}

struct MyUIItem {
	ui.EventArea
}

fn (m &MyUIItem) parent() &ui.Node {
	return m.EventArea.parent()
}

fn (m &MyUIItem) draw(ui &ui.UI) {
	m.EventArea.draw(ui)
}

fn (m &MyUIItem) event(e ui.Event) ?&ui.Node {
	return m.EventArea.event(e)
}

[markused]
pub fn (mut a App) init() ! {
	a.ExampleApp.init()!

	a.window.mode = .ui

	root := &ui.Rectangle{
		id: 42
		width: 100
		height: 100
		body: [
			&ui.Rectangle{
				id: 43
				x: 50
				y: 50
				width: 50
				height: 50
				body: [
					&ui.Rectangle{
						id: 142
						x: 0
						y: 0
						width: 25
						height: 25
						body: [
							&MyUIItem{
								on_event: [
									fn (e ui.Event) bool {
										// println('MyUIItem on_event was called')
										return true
									},
								]
							},
						]
					},
				]
			},
			&ui.EventArea{
				id: 100
				x: 50
				y: 50
				width: 50
				height: 50
				on_event: [
					fn [mut a] (e ui.Event) bool {
						ea := a.ui.find[ui.EventArea](100) or { return false }
						mut mea := unsafe { ea }
						// println('EventArea ${mea.id} found')
						mea.x += 1
						return true
					},
				]
			},
		]
	}
	a.ui = ui.new(
		shy: a.shy
		easy: a.easy
		root: root
	)!
}

[markused]
pub fn (mut a App) frame(dt f64) {
	// win := a.window
	a.ui.draw(dt)
}

[markused]
pub fn (mut a App) event(e shy.Event) {
	a.ExampleApp.event(e)
	a.window.refresh() // In case we're running in UI mode signal that we want the screen to be re-drawn on next frame.

	ui_event := ui.shy_to_ui_event(e) or { panic('${@STRUCT}.${@FN}: ${err}') }
	if _ := a.ui.event(ui_event) {
		// printing the whole node will make things crash at runtime...
		// println('Event was handled by ui.Node.id(${handled_by_node.id})')
	} else {
	}

	// Mutability test
	a.ui.visit(fn (mut n ui.Node) {
		if mut n is ui.Rectangle {
			if n.id == 42 {
				if n.x == 200 {
					n.x = 0
				} else {
					n.x = 200
				}
			}
			// pid := n.parent() or { 0 }.id
			// pid := n.parent().id
			if n.id == 43 {
				// ppid := n.parent() or { 0 }.id
				// ppid := n.parent().id
				// println('${pid} vs. ${ppid}')
			}
		}
	})

	/*
	rects := a.ui.collect(fn (n &ui.Node) bool {
		if n is ui.Rectangle {
			//i := n as ui.Item
			//println('n is $n')
			return true
		}
// 		if n is ui.EventArea {
// 			//i := n as ui.Item
// 			//println('n is $n')
// 			return true
// 		}

		return false
	})

	mut rs := []&ui.Rectangle{cap: rects.len}
	for n in rects {
		//mut rect := unsafe { r as ui.Rectangle }
		//println('-'.repeat(30))
		//println(r)
		if n is ui.Rectangle {
			//mut r := n as ui.Rectangle
			mut r := unsafe { n }
			rs << r
// 			if r.id == 42 {
// 				//println(n)
// 				r.x = 200
// 				//r.draw(a.ui)
// 			}
		}
	}

	for mut r in rs {
		if r.id == 42 {
			r.x = 200
		}
	}*/
}
