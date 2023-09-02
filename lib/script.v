// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module lib

/*
pub enum ScriptLanguages {
	wren
}
*/

[heap]
pub struct Scripts {
	ShyStruct
mut:
	wren_vms []&WrenVM
}

pub fn (sc Scripts) new_wren_vm() !&WrenVM {
	mut wvm := &WrenVM{
		shy: sc.shy
	}
	wvm.init()!
	return wvm
}

pub fn (mut sc Scripts) reset() ! {
	sc.shy.log.gdebug('${@STRUCT}.${@FN}', '')
}

pub fn (mut sc Scripts) init() ! {
	sc.shy.assert_api_init()
	sc.shy.log.gdebug('${@STRUCT}.${@FN}', '')
}

fn (sc Scripts) on_frame(dt f64) {
	for wvm in sc.wren_vms {
		mut vm := unsafe { wvm }
		vm.on_frame(dt)
	}
}

[manualfree]
pub fn (mut sc Scripts) shutdown() ! {
	sc.shy.assert_api_shutdown()
	sc.shy.log.gdebug('${@STRUCT}.${@FN}', '')

	for mut wvm in sc.wren_vms {
		wvm.shutdown()!
		unsafe { free(wvm) }
	}
}
