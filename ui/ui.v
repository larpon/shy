// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module ui

import shy.lib as shy
import shy.easy

pub type ID = int | string | u64

// pub const no_node = &Node(Item{}) // TODO

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

[noinit]
pub struct UI {
	shy.ShyStruct
mut:
	dt   f64
	easy &easy.Easy
	root &Node // = shy.null
	//
	// uiid u64
	// id_map map[u64]u64
	event_listeners []&Node
}

fn (mut u UI) init() ! {
	u.root.parent = shy.null

	// Traverse the tree via BFS and set all `parent` fields
	u.visit(fn [mut u] (mut n Node) {
		for mut node in n.body {
			node.parent = unsafe { n }
		}

		if mut n is EventArea {
			u.event_listeners << n
		}
	})
}

/*
pub fn id(cid ID) !u64 {
	//unsafe { u.uiid++ }
	sb := cid.str().bytes()

	// unsafe { u.id_map[1] = u.uiid }
	beid := binary.big_endian_u64(sha256.sum(sb))
	println(sha256.sum(sb).len)
	println(beid)
	return beid //u.uiid
}*/

pub fn (mut u UI) collect(filter fn (n &Node) bool) []&Node {
	mut nodes := []&Node{}
	if u.root == unsafe { nil } {
		return nodes
	}
	u.root.collect(mut nodes, filter)
	return nodes
}

pub fn (mut u UI) visit(func fn (mut n Node)) {
	if u.root == unsafe { nil } {
		return
	}
	func(mut u.root)
	for mut node in u.root.body {
		node.visit(func)
	}
}

/*
pub fn (u UI) new[T](t T) &T {
	return &T{
		...t
	}
}
*/

pub fn (mut u UI) shutdown() ! {
	// TODO memory leak en-masse
	// u.root.free()
	// unsafe { free(u.root) }
}

pub fn (u &UI) draw(dt f64) {
	unsafe {
		u.dt = dt
	}
	u.root.draw(u)
}

pub fn (u &UI) event(e Event) ?&Node {
	for el in u.event_listeners {
		if node := el.event(e) {
			return node
		}
	}
	return none
}

pub struct Item {
	shy.Rect
pub:
	id u64
mut:
	parent &Node // = unsafe { nil } // TODO crash and burn
	body   []&Node
}

pub fn (i &Item) parent() &Node {
	assert i != unsafe { nil }
	return i.parent
}

pub fn (i &Item) draw(ui &UI) {
	for child in i.body {
		child.draw(ui)
	}
}

pub fn (i &Item) event(e Event) ?&Node {
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

pub fn (r &Rectangle) parent() &Node {
	return r.Item.parent()
}

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

pub fn (r &Rectangle) event(e Event) ?&Node {
	return none
}

pub struct EventArea {
	Item
}

pub fn (ea &EventArea) parent() &Node {
	return ea.Item.parent()
}

pub fn (ea &EventArea) draw(ui &UI) {
	ea.Item.draw(ui)
}

pub fn (ea &EventArea) event(e Event) ?&Node {
	match e {
		KeyEvent {
			match e.key_code {
				.l {
					return ea
				}
				else {}
			}
		}
		else {}
	}
	return none
}
