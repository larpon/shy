// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module shy

import libs.wren

pub struct Wren {
	ShyStruct
mut:
	vm &wren.VM = unsafe { nil }
}

fn wren_no_fn(vm &wren.VM) {}

pub fn (mut w Wren) init() ! {
	w.shy.log.gdebug('${@STRUCT}.${@FN}', 'hi')

	mut config := wren.Configuration{
		// userData: voidptr(w.shy) // Doesn't work?!
	}

	wren.init_configuration(&config)

	config.writeFn = wren_write_fn
	config.errorFn = wren_error_fn

	config.bindForeignClassFn = wren_bind_foreign_class
	config.bindForeignMethodFn = wren_bind_foreign_method

	mut vm := wren.new_vm(&config)
	wren.set_user_data(vm, voidptr(w.shy))
	w.vm = vm

	// TODO TEST ONLY
	w.vm.interpret('main', shy.shy_in_wren)
}

pub fn (mut w Wren) shutdown() ! {
	w.shy.log.gdebug('${@STRUCT}.${@FN}', 'bye')
	wren.free_vm(w.vm)
}

pub fn (mut w Wren) eval(@module string, code string) ! {
	result := wren.interpret(w.vm, @module.str, code.str)
	match result {
		.compile_error {
			return error('Wren compile error')
		}
		.runtime_error {
			return error('Wren runtime error')
		}
		.success {
			return
		}
	}
	return
}

[manualfree]
fn wren_write_fn(vm &wren.VM, const_text &char) {
	msg := unsafe { cstring_to_vstring(const_text) }.trim_space()
	s := &Shy(wren.get_user_data(vm))
	assert !isnil(s), 'Shy is nil in wren_write_fn'
	if msg != '' {
		s.log.custom('WREN', msg)
	}
	// println('Scripts.wren (${ptr_str(s)}) $msg ')
	unsafe { msg.free() }
}

[manualfree]
fn wren_error_fn(vm &wren.VM, error_type wren.ErrorType, const_module &char, const_line int, const_msg &char) {
	mod := unsafe { cstring_to_vstring(const_module) }.trim_space()
	msg := unsafe { cstring_to_vstring(const_msg) }.trim_space()
	s := &Shy(wren.get_user_data(vm))
	assert !isnil(s), 'Shy is nil in wren_error_fn'
	match error_type {
		.compile {
			s.log.gerror('WREN', '$mod line $const_line: $msg')
			// eprintln('Scripts.wren $mod line $const_line: $msg')
		}
		.stack_trace {
			s.log.gerror('WREN', '$mod line $const_line in $msg')
			// eprintln('Scripts.wren $mod line $const_line in $msg')
		}
		.runtime {
			s.log.gerror('WREN', '$mod line $const_line: $msg')
			// eprintln('Scripts.wren $mod line $const_line: $msg')
		}
	}
	unsafe { mod.free() }
	unsafe { msg.free() }
}

const shy_in_wren = '
foreign class Shy {
  // ...
	foreign static log(text)
}

System.print("Shy ?!")
Shy.log("Shy!!")
'

[manualfree]
fn wren_bind_foreign_class(vm &wren.VM, const_module &char, const_class_name &char) wren.ForeignClassMethods {
	methods := wren.ForeignClassMethods{
		allocate: unsafe { nil }
		finalize: unsafe { nil }
	}

	mod := unsafe { cstring_to_vstring(const_module) }
	class := unsafe { cstring_to_vstring(const_class_name) }
	defer {
		// println('${@FN} called')
		unsafe { mod.free() }
		unsafe { class.free() }
	}

	if class == 'Shy' {
		// methods.allocate = fileAllocate;
		// methods.finalize = fileFinalize;
	}

	return methods
}

[manualfree]
fn wren_bind_foreign_method(vm &wren.VM, const_module &char, const_class_name &char, is_static bool, const_signature &char) wren.ForeignMethodFn {
	mod := unsafe { cstring_to_vstring(const_module) }
	class := unsafe { cstring_to_vstring(const_class_name) }
	sig := unsafe { cstring_to_vstring(const_signature) }
	defer {
		// println('${@FN} called')
		unsafe { mod.free() }
		unsafe { class.free() }
		unsafe { sig.free() }
	}

	// Unknown method
	mut func := wren_no_fn
	if class == 'Shy' {
		if is_static && sig == 'log(_)' {
			return wren_fn_shy_log
		}

		if !is_static && sig == 'write(_)' {
			// return wren_no_fn
		}

		if !is_static && sig == 'close()' {
			// return wren_no_fn
		}
	}
	return func
}

fn wren_fn_shy_log(vm &wren.VM) {
	s := &Shy(wren.get_user_data(vm))
	assert !isnil(s), 'Shy is nil'
	msg := vm.get_slot_string(1)
	if msg != '' {
		s.log.custom('WREN', msg)
	}
}
