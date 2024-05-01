// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module lib

import rand
// import shy.lib as shy
// import shy.vec
import shy.mth

pub type SpriteSource = SpriteSheetAtlas | SpriteSheetToml

pub struct SpriteSheetToml {
	// source AssetSource
	toml string
}

pub struct SpriteSheetAtlas {
	// source AssetSource
	atlas string
}

@[params]
pub struct FrameAnimatorConfig {
	// source SpriteSource
	sequences []FrameSequence
	goal      string
	start     string
}

pub fn FrameAnimator.make(config FrameAnimatorConfig) !FrameAnimator {
	mut fa := FrameAnimator{
		config: config
	}
	for sequence in config.sequences {
		fa.add_sequence(sequence)
	}

	// TODO validate start, goal, and config.to

	if config.start != '' {
		fa.set_sequence(fa.sequences[config.start])
		fa.start()
	} else if config.sequences.len > 0 {
		fa.set_sequence(config.sequences[0])
	}
	fa.set_goal_sequence(config.goal)

	return fa
}

pub struct FrameSequence {
pub:
	tag    string
	frames []u32
	to     map[string]f32
	// frame delays in milliseconds
	delay  u32 = 1000
	delays map[u32]u32
mut:
	to_cumulative   map[string]f32
	to_total_weight f32
}

@[noinit]
pub struct FrameAnimator {
pub:
	config FrameAnimatorConfig
mut:
	sequences   map[string]FrameSequence
	sequence    FrameSequence
	elapsed     f64
	delay       u32
	frame_index u32
pub mut:
	paused bool = true
	frame  u32
	tag    string
}

pub fn (mut fa FrameAnimator) start() {
	fa.paused = false
}

pub fn (mut fa FrameAnimator) add_sequence(sequence FrameSequence) {
	assert sequence.tag != '', 'FrameSequence.tag can not be empty'
	assert sequence.frames.len > 0, 'FrameSequence.frames must have at least 1 frame'

	mut cumulative_weight := f32(0)
	mut total_weight := f32(0)
	mut seq := sequence
	for tag, weight in seq.to {
		total_weight += weight

		if weight <= 0 {
			continue
		}

		cumulative_weight += weight
		seq.to_cumulative[tag] = cumulative_weight
	}
	seq.to_total_weight = total_weight
	fa.sequences[seq.tag] = seq
	// TODO if goal sequence is sat and not '', re-calc the goal sequence
}

pub fn (mut fa FrameAnimator) set_sequence(sequence FrameSequence) {
	fa.sequence = sequence
	fa.delay = sequence.delay
	fa.tag = sequence.tag
	fa.frame = if sequence.frames.len > 0 { sequence.frames[0] } else { 0 }
	fa.frame_index = 0
}

pub fn (mut fa FrameAnimator) update(dt f64) {
	if fa.paused {
		return
	}
	// analyse.max('${@MOD}.${@STRUCT}.max_in_use', a.active.len)
	fa.elapsed += dt
	elapsed_ms := fa.elapsed * 1000

	if elapsed_ms <= fa.delay {
		return
	}
	fa.frame_index++
	// We have more frames to go in the sequence
	if fa.frame_index <= fa.sequence.frames.len {
		fa.update_frame()
		return
	}

	// No more frames in this sequence

	// See if we have a sequence we can go to
	if fa.sequence.to.len > 0 {
		r := mth.floor(rand.f32_in_range(0, 0.999) or { 0.5 } * fa.sequence.to_total_weight)

		mut next_sequence := ''
		for tag, weight in fa.sequence.to_cumulative {
			if r < weight {
				next_sequence = tag
				break
			}
		}

		if next_sequence != '' {
			fa.set_sequence(fa.sequences[next_sequence])
			return
		}
	}

	// TODO Move forward via goal sequence
}

fn (mut fa FrameAnimator) update_frame() {
	fa.frame = fa.sequence.frames[fa.frame_index]
	fa.delay = fa.sequence.delay
	if delay := fa.sequence.delays[fa.frame] {
		fa.delay = delay
	}
	fa.elapsed = 0
}

pub fn (mut fa FrameAnimator) set_goal_sequence(goal string) {
	/*

        if(!p.activeSequence) {
//            Qak.debug(Qak.gid+'ItemAnimation','setGoalSequence','no current activeSequence') //¤qakdbg
            return
        }

        if(goalSequence === "") {
//            Qak.debug(Qak.gid+'ItemAnimation','setGoalSequence','goalSequence is blank') //¤qakdbg
            return
        }

        p.sequencePath = []

        var from = p.activeSequence.name
        var to = goalSequence

        var nodes = {}

        // Convert sequence items to nodes format with all costs set to 1
        // NOTE see aid.js for implementation and format
        for(var i in sequences) {
            var s = sequences[i]
            var sto = Aid.clone(s.to)
            for(var k in sto) {
                sto[k] = 1
            }
            nodes[s.name] = sto
        }

        // Calculate fastest route to goal sequence
        var route = Aid.findShortestPath(nodes,from,to)
        if(route === null) {
            Qak.error('ItemAnimation','No path from',from,'to',to,'ignoring goalSequence')
            return
        }

        if(route.length > 1 && route[0] === from) {
//            Qak.debug(Qak.gid+'ItemAnimation','goalSequence','already at',from,'removing from path') //¤qakdbg
            //Qak.info('ItemAnimation','already at',from,'removing from path')
            route.shift()
        }

        /* // TODO This is fucking up situations where goalSequence is set during initialization
        if(route.length > 0 && route[0] === goalSequence) {
            Qak.info('ItemAnimation','already at goalSequence',goalSequence)
            goalSequenceReached()
            goalSequence = ""
            return
        }*/

//        Qak.debug(Qak.gid+'ItemAnimation','goalSequence',route.join(' -> ')) //¤qakdbg
        p.sequencePath = route
        if(!r.running)
            r.setRunning(true)
	*/
}

pub struct Graph {
	paths map[string]map[string]f32
}

// make returns a new, stack allocated, Graph instance.
// Node input format:
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
pub fn Graph.make(nodes map[string]map[string]f32) Graph {
	return Graph{
		paths: nodes
	}
}

// find_shortest_path returns an array containing the shortest path between `nodes[0]` to `nodes[nodes.len-1]`, using
// `Graph.paths` as the source of all possible routes determined by weights.
//
// TODO optimize and test
// Dijkstra's algorithm
// https://github.com/andrewhayward/dijkstra
// https://raw.githubusercontent.com/andrewhayward/dijkstra/master/graph.js
// MIT Licence: https://github.com/andrewhayward/dijkstra/blob/master/LICENSE
//
// Example call: findShortestPath(nodes,'name1','name4')
// Ouput: [ 'name1', 'name3', 'name4' ]
pub fn (mut g Graph) find_shortest_path(nodes []string) ?[]string {
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

pub fn (g &Graph) extract_shortest(predecessors map[string]string, end string) []string {
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

pub fn (g &Graph) find_paths(start string, end string) ?map[string]string {
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
