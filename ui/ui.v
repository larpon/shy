// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module ui

import shy.lib as shy
import shy.easy

pub type ID = int | string | u64

// new returns a new UI instance located on the heap.
pub fn new(config UIConfig) !&UI {
	mut u := &UI{
		shy:   config.shy
		easy:  config.easy
		root:  config.root
		theme: config.theme
	}
	u.init()!
	return u
}

@[params]
pub struct UIConfig {
pub:
	shy   &shy.Shy
	easy  &easy.Easy
	root  &Node
	theme Theme
}

// UI is the base struct of a logical tree/collection of UI items
// making up *one complete User Interface* for *one application*.
// It holds the pointer to the root node of the tree/scene graph making
// up the UI, from which any other node can be visited.
@[heap; noinit]
pub struct UI {
	shy.ShyStruct
mut:
	dt   f64
	easy &easy.Easy
	root &Node // = shy.null
	//
	theme Theme
	//
	// uiid u64
	// id_map map[u64]u64
}

// init initializes the UI.
fn (mut u UI) init() ! {
	u.root.parent = shy.null
	eprintln('[WIP] UI module is still subject to change, use at own risk :)')
	// Traverse the tree, root to leaves, set all `parent` fields.
	u.modify(fn (mut n Node) {
		for mut node in n.body {
			node.parent = unsafe { n }
		}
	})
	if u.root != unsafe { nil } {
		u.root.init(u)!
	}
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

// modify traverses the complete tree/scene graph via BFS (Breath-First search).
// modify allows modifying the visited `Node` via `func`.
pub fn (mut u UI) modify(func fn (mut n Node)) {
	if u.root == unsafe { nil } {
		return
	}
	func(mut u.root)
	for mut node in u.root.body {
		node.modify(func)
	}
}

// visit traverses the complete tree/scene graph via BFS (Breath-First search).
// visit allows modifying the visited `Node` via `func`.
pub fn (mut u UI) visit(func fn (n &Node)) {
	if u.root == unsafe { nil } {
		return
	}
	func(u.root)
	for node in u.root.body {
		node.visit(func)
	}
}

// pub fn (u UI) new[T](t T) &T {
// 	return &T{
// 		...t
// 	}
// }

// find returns `T` whos `id` field is matching `n_id`, otherwise `none`.
// find is currently not `pub` since it can not find types outside the `ui` module :(.
fn (u &UI) find[T](n_id u64) ?&T {
	if u.root == unsafe { nil } {
		return none
	}
	// TODO this can be made faster, e.g. lookup from cache
	nodes := u.collect(fn [n_id] (n &Node) bool {
		// println('${@FN}@${n.id} == ${n_id}?')
		if n.id == n_id {
			// println('${cast_node.id} == ${n_id}')
			return true
		}
		return false
	})
	if nodes.len > 0 {
		node := nodes[0]
		if node is T {
			return &T(node)
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

// update calls `update` on the UI's root node.
pub fn (mut u UI) update() {
	u.root.update()
}

// draw draws the current frame of the UI's state.
pub fn (mut u UI) draw(dt f64) {
	unsafe {
		u.dt = dt
	}
	// TODO surround in a separate render pass?
	u.root.draw()
}

// event sends `event` to relevant node event handlers in the UI.
pub fn (mut u UI) event(e Event) ?&Node {
	// Start event bubbling
	return u.root.event(e)
}
