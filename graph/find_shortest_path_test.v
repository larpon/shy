// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
import shy.graph

fn test_find_shortest_path() {
	// nodes := map[string]map[string]f32{}
	mut nodes := {
		'start': {
			'1': f32(0.5)
			'2': 5.5
		}
		'1':     {
			'2': f32(0.5)
		}
		'2':     {
			'1': f32(0.5)
			'3': 1.0
			'5': 7
		}
		'3':     {
			'2': f32(5.5)
			'4': 3
		}
		'4':     {
			'1':   f32(5.5)
			'end': 3
		}
		'5':     {
			'start': f32(3)
		}
		'end':   {
			'4': f32(3)
		}
	}

	mut g := graph.make_dijkstra_string_key(nodes)
	p1 := g.find_shortest_path(['start', 'end'])?

	assert p1 == ['start', '1', '2', '3', '4', 'end']

	nodes = {
		'start': {
			'1': f32(0.5)
			'2': 5.5
		}
		'1':     {
			'2':   f32(0.5)
			'2.5': 3.5
		}
		'2':     {
			'1': f32(0.5)
			'3': 1.0
			'5': 7
		}
		'2.5':   {
			'1':   f32(0.5)
			'3':   1.0
			'end': 1
		}
		'3':     {
			'2': f32(5.5)
			'4': 3
		}
		'4':     {
			'1':   f32(5.5)
			'end': 3
		}
		'5':     {
			'start': f32(3)
		}
		'end':   {
			'4': f32(3)
		}
	}

	g = graph.make_dijkstra_string_key(nodes)
	p2 := g.find_shortest_path(['start', 'end'])?

	assert p2 == ['start', '1', '2.5', 'end']

	nodes = {
		'start': {
			'1': f32(0.5)
		}
		'1':     {
			'2': f32(0.5)
		}
		'end':   {}
	}

	g = graph.make_dijkstra_string_key(nodes)
	if _ := g.find_shortest_path(['start', 'end']) {
		assert false
	} else {
		// Should fail, no route to 'end'
		assert true
	}

	nodes = {
		'start': {
			'1': f32(0.5) // non-existing target key
		}
		'end':   {
			'start': f32(1.0)
		}
	}

	g = graph.make_dijkstra_string_key(nodes)
	assert !g.is_valid()
}
