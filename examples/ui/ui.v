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

[heap]
pub struct MyUIItem {
	ui.EventArea
}

pub fn (m &MyUIItem) parent() &ui.Node {
	return m.EventArea.parent()
}

pub fn (m &MyUIItem) draw(ui &ui.UI) {
	m.EventArea.draw(ui)
}

pub fn (m &MyUIItem) event(e ui.Event) ?&ui.Node {
	// println('MyUIItem event called ${m.id}')
	return m.EventArea.event(e)
}

[heap]
pub struct MyRect {
	ui.Rectangle
}

pub fn (m &MyRect) parent() &ui.Node {
	return m.Rectangle.parent()
}

pub fn (m &MyRect) draw(ui &ui.UI) {
	m.Rectangle.draw(ui)
}

pub fn (m &MyRect) event(e ui.Event) ?&ui.Node {
	// println('MyRect event called ${m.id}')
	return m.Rectangle.event(e)
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
				x: 50
				y: 50
				width: 50
				height: 50
				body: [
					&ui.Rectangle{
						x: 0
						y: 0
						width: 25
						height: 25
						body: [
							&MyUIItem{
								id: 400
								width: 10
								on_event: [
									fn (n &ui.Node, e ui.Event) bool {
										node := &&MyUIItem(n) // TODO this is a weird V quirk
										assert node.id == n.id
										// println('MyUIItem on_event reached ${node.id}/${n.id}')
										mut mmui := unsafe { node }
										mmui.width++
										// println('${@STRUCT}/MyUIItem on_event was called ${mmui.width}')
										// return true
										return false
									},
								]
							},
						]
					},
				]
			},
			&ui.PointerEventArea{
				id: 100
				x: 50
				y: 50
				width: 500
				height: 500
				/*
				on_event: [
					fn (n &ui.Node, e ui.Event) bool {
						//println('ui.EventArea on_event reached ${n.id}')

						ea := &&ui.EventArea(n)
						assert ea.id == n.id
						mut mea := unsafe { ea }
						println('EventArea ${mea.id} found .x: ${mea.x}')
						// mea.x += 1
						// return true
						return false
					},
				]*/
				on_pointer_event: [
					fn (n &ui.Node, e ui.PointerEvent) bool {
						// println('ui.EventArea on_event reached ${n.id}')

						pea := &&ui.PointerEventArea(n)
						// assert pea.id == n.id
						mut mpea := unsafe { pea }
						// println('PointerEventArea ${mpea.id} found .x: ${mpea.x}')
						// mpea.x += 1
						// return true
						return false
					},
				]
				body: [
					&MyRect{
						id: 420
						x: 300
						y: 300
						width: 6
						height: 6
						on_event: [
							fn (n &ui.Node, e ui.Event) bool {
								// if n is ui.Rectangle {
								// ur := &ui.Rectangle(n)
								mut mr := &&MyRect(n)
								assert mr.id == n.id
								// mut mr := unsafe { n }
								// println('mr.x: ${mr.x}')
								// println('ur.x: ${ur.x} mr.x: ${mr.x}')
								// mr.x += 1
								// return true

								//}
								return false
							},
						]
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
	if handled_by_node := a.ui.event(ui_event) {
		// printing the whole node will make things crash at runtime...
		println('Event was handled by ui.Node.id(${handled_by_node.id})')
	} else {
	}

	// Mutability test
	a.ui.modify(fn (mut n ui.Node) {
		// TODO BUG broken - V doesn't allow for retreiving back the original pointer of a *custom* type implementing ui.Node...
		// The horrible thing is that it only works... sometimes :(
		// mut maybe := ui.cast[MyRect](n)
		mut maybe := &&MyRect(n)
		// println('oi ${maybe}')
		if maybe.id == 420 {
			// println('oi ${maybe}')
			maybe.x += 0.5
			maybe.y += 0.25
		}
		if mut n is ui.Rectangle {
			// mut n := unsafe { node }
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
