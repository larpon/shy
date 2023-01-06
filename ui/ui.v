// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module ui

import shy.lib as shy
import shy.easy

pub type ID = int | string | u64

// pub const no_node = &Node(Item{}) // TODO

// new returns a new UI instance located on the heap.
pub fn new(config UIConfig) !&UI {
	mut u := &UI{
		shy: config.shy
		easy: config.easy
		root: config.root
	}
	u.init()!
	return u
}

[params]
pub struct UIConfig {
	shy  &shy.Shy
	easy &easy.Easy
	root &Node
}

[heap; noinit]
pub struct UI {
	shy.ShyStruct
mut:
	dt   f64
	easy &easy.Easy
	root &Node // = shy.null
	//
	// uiid u64
	// id_map map[u64]u64
}

// init initializes the UI.
fn (mut u UI) init() ! {
	u.root.parent = shy.null

	// Traverse the tree, root to leaves, set all `parent` fields
	u.visit(fn (mut n Node) {
		for mut node in n.body {
			node.parent = unsafe { n }
		}
	})
}

// pub fn id(cid ID) !u64 {
// 	//unsafe { u.uiid++ }
// 	sb := cid.str().bytes()
//
// 	// unsafe { u.id_map[1] = u.uiid }
// 	beid := binary.big_endian_u64(sha256.sum(sb))
// 	println(sha256.sum(sb).len)
// 	println(beid)
// 	return beid //u.uiid
// }

// collect collects all nodes where `filter(node)` returns `true`.
pub fn (u UI) collect(filter fn (n &Node) bool) []&Node {
	mut nodes := []&Node{}
	if u.root == unsafe { nil } {
		return nodes
	}
	u.root.collect(mut nodes, filter)
	return nodes
}

// visit traverses the scene graph via BFS (Breath-First search).
// visit allows modifying the visited `Node` via `func`.
pub fn (mut u UI) visit(func fn (mut n Node)) {
	if u.root == unsafe { nil } {
		return
	}
	func(mut u.root)
	for mut node in u.root.body {
		node.visit(func)
	}
}

// pub fn (u UI) new[T](t T) &T {
// 	return &T{
// 		...t
// 	}
// }

// find returns `T` with an id matching `n_id` or `none`.
pub fn (u &UI) find[T](n_id u64) ?&T {
	if u.root == unsafe { nil } {
		return none
	}
	// TODO lookup from cache first
	nodes := u.collect(fn [n_id] (n &Node) bool {
		if n.id == n_id {
			// println('${n_id}')
			return true
		}
		return false
	})
	if nodes.len > 0 {
		node := nodes[0]
		if node is T {
			return node
		}
	}
	return none
}

// shutdown shutdown the UI.
pub fn (mut u UI) shutdown() ! {
	// TODO memory leak en-masse
	// u.root.free()
	// unsafe { free(u.root) }
}

// draw draws the current frame of the UI's state.
pub fn (u &UI) draw(dt f64) {
	unsafe {
		u.dt = dt
	}
	u.root.draw(u)
}

// event sends `event` to relevant node event handlers in the UI.
pub fn (u &UI) event(e Event) ?&Node {
	// Start event bubbling
	return u.root.event(e)
}

pub type OnEventFn = fn (event Event) bool

// Item is the base type for all UI elements.
// By embedding `Item` in a struct - the struct fulfills
// the `Node` interface required for a type to be an UI item.
pub struct Item {
	shy.Rect
pub:
	id u64
mut:
	parent   &Node = unsafe { nil } // TODO crash and burn
	body     []&Node
	on_event []OnEventFn
}

// parent returns this `Item`'s parent.
pub fn (i &Item) parent() &Node {
	assert i != unsafe { nil }
	// TODO not possible currently: if isnil(i.parent) { return none }
	return i.parent
}

// draw draws the `Item` and/or any child nodes.
pub fn (i &Item) draw(ui &UI) {
	for child in i.body {
		child.draw(ui)
	}
}

// event sends an `Event` any child nodes and/or it's own listeners.
pub fn (i &Item) event(e Event) ?&Node {
	// By sending the event on to the children nodes
	// it's effectively *bubbling* the event upwards in the
	// tree / scene graph
	for child in i.body {
		if node := child.event(e) {
			return node
		}
	}
	for on_event in i.on_event {
		assert !isnil(on_event)
		// If `on_event` returns true, it means
		// a listener on *this* item has accepted the event
		if on_event(e) {
			return i
		}
	}
	return none
}

/*
fn (mut i Item) free() {
	for child in i.body {
		child.free()
		unsafe { free(child) }
	}
	i.body.clear()
	i.body.free()
}*/

pub struct Rectangle {
	Item
}

// parent returns the parent Node.
pub fn (r &Rectangle) parent() &Node {
	return r.Item.parent()
}

// draw draws the `Item` and/or any child nodes.
pub fn (r &Rectangle) draw(ui &UI) {
	// println('${@STRUCT}.${@FN} ${ptr_str(r)}')
	// println('${@STRUCT}.${@FN} ${r}')
	er := ui.easy.rect(
		x: r.x
		y: r.y
		width: r.width
		height: r.height
	)
	er.draw()

	r.Item.draw(ui)
}

// event sends an `Event` any child nodes and/or it's own listeners.
pub fn (r &Rectangle) event(e Event) ?&Node {
	return r.Item.event(e)
}

pub struct EventArea {
	Item
}

// parent returns the parent Node.
pub fn (ea &EventArea) parent() &Node {
	return ea.Item.parent()
}

// draw draws the `Item` and/or any child nodes.
pub fn (ea &EventArea) draw(ui &UI) {
	ea.Item.draw(ui)
}

// event sends an `Event` any child nodes and/or it's own listeners.
pub fn (ea &EventArea) event(e Event) ?&Node {
	return ea.Item.event(e)
}
