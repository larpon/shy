// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module shy

import libs.wren

pub struct Wren {
	ShyStruct
mut:
	vm      &wren.VM = unsafe { nil }
	handles []WrenClass
}

pub struct WrenClass {
	vm    &wren.VM // = unsafe { nil }
	class &wren.Handle
mut:
	fields  map[string]&wren.Handle
	methods map[string]&wren.Handle
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
	w.eval('shy', shy.shy_in_wren) or { return error('${@STRUCT}.${@FN}: $err') }
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

/*
// TODO needs plenty of love we need to be able to register as a foreign class
// and do all the V -> C -> Wren and vice versa.
// https://wren.io/embedding/calling-wren-from-c.html
// https://wren.io/embedding/calling-c-from-wren.html
[params]
pub struct WrenConvertConfig {
	mod string = 'main'
}

pub fn (mut w Wren) to_wren_code<T>() string {
	// TODO hotcode / shutdown guard
	// mut _ := T{}

	mut code := ''
	class_name := T.name

	code += 'foreign class $class_name {'

	mut f_get_set := ''

	// TODO embedded structs and reference fields???
	// $for field in T.fields {
	// 	f_get_set += '\t$field.name { _$field.name }\n'
	// 	f_get_set += '\t$field.name=(value){ _$field.name = value }\n'
	// }

	mut methods := ''
	$for method in T.methods {
		//println(method)
		methods += '\tforeign '+'${method.name}('
		mut args := ''
		t_args := method.args
		for arg in t_args {
			args += '$arg.name,'
		}
		methods += args.trim_right(',') + ')\n'
	}
	return code + '\n' + f_get_set + methods + '}'
	// println(wren_class.handles) // NOTE CRASH
}

pub fn (mut w Wren) to_wren<T>(config WrenConvertConfig) ! {
	// TODO hotcode / shutdown guard
	// mut _ := T{}

	name := T.name

	code := w.to_wren_code<T>()
	println(code)
	w.eval(config.mod,code) !
	w.vm.ensure_slots(1)
	w.vm.get_variable(config.mod, name, 0)

	mut wren_class := WrenClass{
		vm: w.vm
		class: w.vm.get_slot_handle(0)
	}
	$for field in T.fields {
		// println(field.name)

		// mut wren_sig := field.name+'('
		// args := '_,'.repeat(method.args.len)
		// wren_sig += args.trim_right(',') + ')'
		// wren_class.methods << w.vm.make_call_handle(wren_sig)
	}
	$for method in T.methods {
		//println(method)
		wren_sig := method.name+'('+'_,'.repeat(method.args.len).trim_right(',') + ')'
		wren_class.methods[method.name] = w.vm.make_call_handle(wren_sig)
	}
	// println(wren_class.handles) // NOTE CRASH
}
*/

[manualfree]
fn wren_write_fn(vm &wren.VM, const_text &char) {
	msg := wren_c2v_string(const_text).trim_space()
	s := &Shy(wren.get_user_data(vm))
	assert !isnil(s), 'Shy is nil in wren_write_fn'
	if msg != '' {
		s.log.custom('WREN', msg)
	}
	// println('Scripts.wren (${ptr_str(s)}) $msg ')
	unsafe { msg.free() }
}

/*
fn wren_c2v_const_string(ch_ptr &char) string {
	if !isnil(ch_ptr) {
		return unsafe { tos3(ch_ptr) }.trim_space()
	}
	return ''
}
*/

fn wren_c2v_string(ch_ptr &char) string {
	if !isnil(ch_ptr) {
		return unsafe { cstring_to_vstring(ch_ptr) }
	}
	return ''
}

[manualfree]
fn wren_error_fn(vm &wren.VM, error_type wren.ErrorType, const_module &char, const_line int, const_msg &char) {
	mod := wren_c2v_string(const_module).trim_space()
	msg := wren_c2v_string(const_msg).trim_space()
	s := &Shy(wren.get_user_data(vm))
	assert !isnil(s), 'Shy is nil in wren_error_fn'
	match error_type {
		.compile {
			s.log.gerror('WREN COMPILE', '$mod line $const_line: $msg')
			// eprintln('Scripts.wren $mod line $const_line: $msg')
		}
		.stack_trace {
			s.log.gerror('WREN', '$mod line $const_line in $msg')
			// eprintln('Scripts.wren $mod line $const_line in $msg')
		}
		.runtime {
			s.log.gerror('WREN RUNTIME', '$mod line $const_line: $msg')
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
// System.print("Shy ?!")
// Shy.log("Shy!!")
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
