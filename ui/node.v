// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module ui

import shy.lib as shy
import shy.vec

pub struct VisualState {
	shy.Rect
pub:
	rotation f32
	scale    f32 = 1.0
	offset   vec.Vec2[f32]
	origin   shy.Anchor
}

@[heap]
pub interface Node {
	id u64
	init() !
	draw(ui &UI)
	event(e Event) ?&Node
	visual_state() VisualState
mut:
	parent &Node
	body   []&Node
}

/*
// parent returns this node's parent `&Node`.
pub fn (n &Node) parent() &Node {
	assert n != unsafe { nil }
	// TODO not possible currently: if isnil(n.parent) { return none }
	return n.parent
}
*/

// reparent sets `parent` to `new_parent` on this `&Node`.
pub fn (n &Node) reparent(new_parent &Node) {
	assert n != unsafe { nil }
	assert new_parent != unsafe { nil }
	unsafe {
		n.parent = new_parent
	}
}

// collect collects all `Node`s matching `filter() == true` into `nodes`.
pub fn (n &Node) collect(mut nodes []&Node, filter fn (n &Node) bool) {
	assert n != unsafe { nil }
	// println('collecting ${ptr_str(i)} ${filter(i)}')
	if filter(n) {
		nodes << n
	}
	for node in n.body {
		assert node != unsafe { nil }
		node.collect(mut nodes, filter)
	}
}

// modify visits all `Node`s in a Breath-First search (BFS),
// calling `func` with each `Node` as an argument.
pub fn (n &Node) modify(func fn (mut n Node)) {
	assert n != unsafe { nil }, 'Node is null'
	mut mn := unsafe { n }
	func(mut mn)
	for mut node in mn.body {
		assert node != unsafe { nil }
		node.modify(func)
	}
}

// visit visits all `Node`s in a Breath-First search (BFS),
// calling `func` with each `Node` as an argument.
pub fn (n &Node) visit(func fn (n &Node)) {
	assert n != unsafe { nil }
	func(n)
	for node in n.body {
		assert node != unsafe { nil }
		node.visit(func)
	}
}
