module graph

// make_dijkstra_string_key returns a new, stack allocated, DijkstraStringKeyGraph instance.
// `nodes` are expected to be of the form:
//
// ```v
//  nodes = {
//      'name1': {
//          'name2': f32(<weight>),
//          'name3': <weight>
//      },
//      'name2': {
//          'name1': f32(<weight>),
//          'name3': <weight>
//      },
//      'name3': {
//          'name1': f32(<weight>),
//          'name2': <weight>,
//          'name4': <weight>
//      },
//      'name4': {
//          'name1': f32(<weight>),
//          'name2': <weight>
//      }
//  }
// ```
pub fn make_dijkstra_string_key(nodes map[string]map[string]f32) DijkstraStringKeyGraph {
	mut dsk := DijkstraStringKeyGraph{
		paths: nodes
	}
	dsk.assert_validate()
	return dsk
}

@[noinit]
pub struct DijkstraStringKeyGraph {
	paths map[string]map[string]f32
}

@[if validate_input ?]
pub fn (g DijkstraStringKeyGraph) assert_validate() {
	assert g.is_valid()
}

pub fn (g DijkstraStringKeyGraph) is_valid() bool {
	valid_targets := g.paths.keys()
	for k, m in g.paths {
		for target, _ in m {
			if target !in valid_targets {
				dijkstra_debug('target ${target} in ${k} does not exist in nodes input')
				return false
			}
		}
	}
	return true
}

// find_shortest_path returns an array containing the shortest path between `nodes[0]` to `nodes[nodes.len-1]`, using
// `DijkstraStringKeyGraph.paths` as the source of all possible routes determined by weights.
//
// TODO optimize, memory allocations makes it not-so-suitable for a game. Most could probably be
// calculated when the sequences are sat/change the first time.
//
// Dijkstra's algorithm
// https://github.com/andrewhayward/dijkstra
// https://raw.githubusercontent.com/andrewhayward/dijkstra/master/graph.js
// MIT Licence: https://github.com/andrewhayward/dijkstra/blob/master/LICENSE
//
// Example call: findShortestPath(nodes,'name1','name4')
// Ouput: [ 'name1', 'name3', 'name4' ]
pub fn (mut g DijkstraStringKeyGraph) find_shortest_path(nodes []string) ?[]string {
	mut mut_nodes := nodes.reverse()
	mut start := mut_nodes.pop()
	mut end := ''
	mut predecessors := map[string]string{}
	mut path := []string{}
	// mut shortest := []string{}

	for mut_nodes.len > 0 {
		end = mut_nodes.pop()
		predecessors = g.find_paths(start, end)?

		mut shortest := g.extract_shortest(predecessors, end)
		if mut_nodes.len > 0 {
			shortest.delete_last()
			path << shortest
		} else {
			path << shortest
			return path
		}
		start = end
	}
	return none
}

pub fn (g &DijkstraStringKeyGraph) extract_shortest(predecessors map[string]string, end string) []string {
	mut nodes := []string{}
	mut u := end
	for u != '' {
		nodes << u

		if n := predecessors[u] {
			u = n
		} else {
			u = ''
		}
	}
	nodes.reverse_in_place()
	return nodes
}

fn dijkstra_compare_fn_string_as_float(a &string, b &string) int {
	if a.f32() < b.f32() {
		return -1
	} else if a.f32() > b.f32() {
		return 1
	}
	return 0
}

@[if dijkstra_debug ?]
fn dijkstra_debug(s string) {
	eprint(s)
}

pub fn (g &DijkstraStringKeyGraph) find_paths(start string, end string) ?map[string]string {
	mut costs := map[string]f32{}
	mut open := {
		'0.0000': [start]
	}
	mut predecessors := map[string]string{}
	mut keys := []string{}

	costs[start] = 0

	for open.len > 0 {
		keys = open.keys()
		if keys.len == 0 {
			break
		}
		keys.sort_with_compare(dijkstra_compare_fn_string_as_float)

		key := keys[0]
		mut bucket := open[key].reverse()
		node := bucket.pop()
		current_cost := key.f32()

		if bucket.len == 0 {
			open.delete(key)
		}
		dijkstra_debug('open: ${open}\ncosts: ${costs}')
		if adjacent_nodes := g.paths[node] {
			for k, v in adjacent_nodes {
				cost := v
				total_cost := cost + current_cost
				vd4 := '${v:.4f}'
				dijkstra_debug('vd4: ${vd4}')
				if v_cost := costs[k] {
					if v_cost > total_cost {
						costs[k] = total_cost
						open[vd4] = [k]
						predecessors[k] = node
					}
				} else {
					costs[k] = total_cost
					open[vd4] = [k]
					predecessors[k] = node
				}
			}
		}
	}

	if _ := costs[end] {
		dijkstra_debug('r none')
		return predecessors
	}
	dijkstra_debug('r predecessors ${predecessors}')
	return none
}
