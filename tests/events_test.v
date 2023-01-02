// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
import shy.lib as shy

fn test_pushing_max_number_of_events() {
	s := &shy.Shy{}
	mut events := &shy.Events{
		shy: s
	}
	events.init()!

	max_events := 10000
	for i in 0 .. max_events {
		eprintln('Pushing event number ${i + 1}')
		e := shy.Event(shy.MouseMotionEvent{
			timestamp: s.ticks()
			window: shy.null
		})
		events.push(e)!
		assert true
	}

	eprintln('Pushing one too many events')
	e := shy.Event(shy.MouseMotionEvent{
		timestamp: s.ticks()
		window: shy.null
	})
	events.push(e) or { assert true }

	events.shutdown()!
}
