// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module shy

/*
pub enum ScriptLanguages {
	wren
}
*/

[heap]
pub struct Scripts {
	ShyStruct
pub mut: // TODO better public access control
	wren &Wren = unsafe { nil }
}

pub fn (mut sc Scripts) init() ! {
	mut s := sc.shy
	s.log.gdebug('${@STRUCT}.${@FN}', 'hi')

	sc.wren = &Wren{
		shy: s
	}
	sc.wren.init()!
}

pub fn (mut sc Scripts) shutdown() ! {
	// mut s := sc.shy
	sc.shy.log.gdebug('${@STRUCT}.${@FN}', 'bye')

	sc.wren.shutdown()!
	unsafe { free(sc.wren) }
}
