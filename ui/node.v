// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module ui

// import shy.lib as shy

pub interface Node {
	id u64
	draw(ui &UI)
	event(e Event) ?&Node
mut:
	parent &Node
	body []&Node
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

// visit visits all `Node`s in a Breath-First search (BFS),
// calling `func` with each `Node` as an argument.
pub fn (n &Node) visit(func fn (mut n Node)) {
	assert n != unsafe { nil }
	mut mn := unsafe { n }
	func(mut mn)
	for mut node in mn.body {
		assert node != unsafe { nil }
		node.visit(func)
	}
}

// parent returns this node's parent `&Node`.
pub fn (n &Node) parent() &Node {
	assert n != unsafe { nil }
	// TODO not possible currently: if isnil(n.parent) { return none }
	return n.parent
}
