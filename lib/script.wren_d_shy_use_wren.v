// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module lib

import time
import shy.wraps.wren

pub struct WrenVM {
	ShyStruct
mut:
	vm         &wren.VM = unsafe { nil }
	classes    []WrenClass
	lookup_fns map[string]wren.ForeignMethodFn
}

pub struct WrenClass {
	vm    &wren.VM // = unsafe { nil }
	class &wren.Handle
	name  string // TODO
mut:
	// fields  map[string]&wren.Handle
	methods map[string]&wren.Handle
	fn_ptr  ?wren.ForeignMethodFn
}

pub fn (wc WrenClass) str() string {
	return 'WrenClass{}' // TODO: to allow compiling with `$dbg`
}

fn (w WrenVM) on_frame(dt f64) {
	for wren_class in w.classes {
		if frame_fn_handle := wren_class.methods['frame'] {
			assert !isnil(frame_fn_handle)
			assert !isnil(wren_class.class)
			w.vm.ensure_slots(2)
			w.vm.set_slot_handle(0, wren_class.class)
			w.vm.set_slot_double(1, dt)
			w.vm.call(frame_fn_handle)
		}
	}
}

fn wren_no_fn(vm &wren.VM) {}

pub fn (mut w WrenVM) init() ! {
	w.shy.log.gdebug('${@STRUCT}.${@FN}', '')

	mut config := wren.Configuration{
		// userData: voidptr(w.shy) // Doesn't work?!
	}

	wren.init_configuration(&config)

	config.writeFn = wren_write_fn
	config.errorFn = wren_error_fn

	config.bindForeignClassFn = wren_bind_foreign_class
	config.bindForeignMethodFn = wren_bind_foreign_method

	mut vm := wren.new_vm(&config)
	wren.set_user_data(vm, voidptr(w))
	w.vm = vm

	// TODO: TEST ONLY
	w.eval('shy', shy_in_wren) or { return error('${@STRUCT}.${@FN}: ${err}') }

	// Register handle for the Shy.frame method
	w.vm.ensure_slots(1)
	w.vm.get_variable('shy', 'Shy', 0)

	mut wren_class := WrenClass{
		vm:    w.vm
		class: w.vm.get_slot_handle(0)
	}
	wren_class.methods['frame'] = w.vm.make_call_handle('frame(_)')
	// wren_class.methods['should_update'] = w.vm.make_call_handle('should_update()')
	w.classes << wren_class
}

pub fn (mut w WrenVM) shutdown() ! {
	w.shy.log.gdebug('${@STRUCT}.${@FN}', '')
	for class in w.classes {
		for _, method in class.methods {
			w.vm.release_handle(method)
		}
		w.vm.release_handle(class.class)
	}
	wren.free_vm(w.vm)
}

pub fn (mut w WrenVM) eval(@module string, code string) ! {
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
pub fn (mut w WrenVM) register_lookup_fn<T>(fn_ptr wren.ForeignMethodFn)! {
	class_name := T.name
	w.lookup_fns[class_name] = fn_ptr
}
*/

pub fn (mut w WrenVM) register_class[T](fn_name string, fn_ptr wren.ForeignMethodFn) ! {
	class_name := T.name

	/*
	TODO: not currently possible
	fn_ptr := fn (vm &wren.VM) {
		s := &Shy(vm.get_user_data())
		assert !isnil(s), 'Shy is nil'
		assert !isnil(s.app()), 'App is nil'
		//app := &T(s.app())
		value := vm.get_slot_string(1)
		ffn := T.$('call_in_wren')
		ffn(value)

		// $for method in app.methods {
		// 	if method.name == mname {
		// 		method(value)
		// 	}
		// }
	}
	*/

	w.lookup_fns[class_name + '.' + class_name + '.' + fn_name] = fn_ptr
	// w.register_lookup_fn<T>(fn_ptr)!

	mut code := ''

	code += 'class ${class_name} {
	construct new(){}'

	mut f_get_set := ''
	mut methods := ''

	method_name := fn_name
	methods += '\tforeign ' + '${method_name}('
	mut args := 'msg'
	methods += args.trim_right(',') + ')\n'
	code += '\n' + f_get_set + methods + '}'

	// println('$code')

	w.eval(class_name, code)!
	// println('WTF?!')
	w.vm.ensure_slots(1)
	w.vm.get_variable(class_name, class_name, 0)

	mut wren_class := WrenClass{
		vm:    w.vm
		name:  class_name
		class: w.vm.get_slot_handle(0)
	}

	wren_sig := method_name + '(' + '_' + ')'
	wren_class.methods[fn_name] = w.vm.make_call_handle(wren_sig)
	wren_class.fn_ptr = fn_ptr

	// println('Registered $wren_class.name')

	w.classes << wren_class
}

pub fn (mut w WrenVM) eval2[T](wren_code string) ! {
	class_name := T.name
	w.eval(class_name, wren_code)!
}

pub fn wren_lookup_user(vm &wren.VM, mod string, class string, is_static bool, sig string) wren.ForeignMethodFn {
	w := unsafe { &WrenVM(vm.get_user_data()) }
	assert !isnil(w), 'WrenVM is nil'
	// s := &Shy(w.shy)
	// assert !isnil(s), 'Shy is nil'
	// assert !isnil(s.app), 'App is nil'
	// a := &App(s.app)
	// value := vm.get_slot_string(1)
	// a.call_in_wren(value)
	// println('Oi')
	if func := w.lookup_fns['${mod}.${class}.' + sig.all_before('(')] {
		return func
	}

	/*
	for wren_class in s.scripts().wren().classes {
		println('Ahoy m:$mod $class $sig wren_class.name:$wren_class.name')
		if wren_class.name == '' {
			continue
		}
		if mod == wren_class.name {
			println('Ahoy 2')
			println('Found $mod $class $sig in classes')
			return wren_class.fn_ptr
		}
	}*/
	println('Nothing found')
	return wren_no_fn
}

fn wren_fn_user_call(vm &wren.VM) {
	w := unsafe { &WrenVM(vm.get_user_data()) }
	assert !isnil(w), 'WrenVM is nil'
	s := &Shy(w.shy)
	assert !isnil(s), 'Shy is nil'
	// wt := vm.get_slot_type(0)
	// s.log.custom('WREN', '$wt')
	msg := vm.get_slot_string(1)
	if msg != '' {
		s.log.custom('WREN', msg)
	}
}

/*
// TODO: needs plenty of love we need to be able to register as a foreign class
// and do all the V -> C -> Wren and vice versa.
// https://wren.io/embedding/calling-wren-from-c.html
// https://wren.io/embedding/calling-c-from-wren.html
[params]
pub struct WrenConvertConfig {
	mod string = 'main'
}

pub fn (mut w WrenVM) to_wren_code<T>() string {
	// TODO: hotcode / shutdown guard
	// mut _ := T{}

	mut code := ''
	class_name := T.name

	code += 'foreign class $class_name {'

	mut f_get_set := ''

	// TODO: embedded structs and reference fields???
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
	// println(wren_class.classes) // NOTE: CRASH
}

pub fn (mut w WrenVM) to_wren<T>(config WrenConvertConfig) ! {
	// TODO: hotcode / shutdown guard
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
	// println(wren_class.methods) // NOTE: CRASH
}
*/

@[manualfree]
fn wren_write_fn(vm &wren.VM, const_text &char) {
	msg := wren_c2v_string(const_text).trim_space()

	w := unsafe { &WrenVM(vm.get_user_data()) }
	assert !isnil(w), 'WrenVM is nil'
	s := w.shy
	assert !isnil(s), 'Shy is nil'
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

@[manualfree]
fn wren_error_fn(vm &wren.VM, error_type wren.ErrorType, const_module &char, const_line int, const_msg &char) {
	mod := wren_c2v_string(const_module).trim_space()
	msg := wren_c2v_string(const_msg).trim_space()
	w := unsafe { &WrenVM(vm.get_user_data()) }
	assert !isnil(w), 'WrenVM is nil'
	s := w.shy
	assert !isnil(s), 'Shy is nil'
	match error_type {
		.compile {
			s.log.gerror('WREN COMPILE', '${mod} line ${const_line}: ${msg}')
			// eprintln('Scripts.wren $mod line $const_line: $msg')
		}
		.stack_trace {
			s.log.gerror('WREN', '${mod} line ${const_line} in ${msg}')
			// eprintln('Scripts.wren $mod line $const_line in $msg')
		}
		.runtime {
			s.log.gerror('WREN RUNTIME', '${mod} line ${const_line}: ${msg}')
			// eprintln('Scripts.wren $mod line $const_line: $msg')
		}
	}
	unsafe { mod.free() }
	unsafe { msg.free() }
}

const shy_in_wren = '
foreign class Shy {
	static add_app(app) {
		if (__apps == null) { __apps = [] }
		__apps.add(app)
	}
	static can_update() {
		return __apps != null && __apps.count != 0
	}
	foreign static log(text)
	foreign static sleep(ms)
	static frame(dT) {
		if (!can_update()) return
		for (app in __apps) {
		  	app.frame(dT)
		}

	}
	static fixed_update(dT) {}
	static variable_update(dT) {}

}

class ShyApp {
	init {}
	shutdown {}
	frame(dT) {}
	fixed_update(dT) {}
	variable_update(dT) {}
}

// System.print("Shy ?!")
// Shy.log("Shy!!")
'

@[manualfree]
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

@[manualfree]
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

	println('Wren is looking up ${mod} ${class} ${sig}')

	// Unknown method
	mut func := wren_no_fn
	if class == 'Shy' {
		if is_static && sig == 'log(_)' {
			return wren_fn_shy_log
		}
		if is_static && sig == 'sleep(_)' {
			return wren_fn_shy_sleep
		}

		if !is_static && sig == 'write(_)' {
			// return wren_no_fn
		}

		if !is_static && sig == 'close()' {
			// return wren_no_fn
		}
	}
	func = wren_lookup_user(vm, mod, class, is_static, sig)
	return func
}

fn wren_fn_shy_log(vm &wren.VM) {
	w := unsafe { &WrenVM(vm.get_user_data()) }
	assert !isnil(w), 'WrenVM is nil'
	s := w.shy
	assert !isnil(s), 'Shy is nil'
	// wt := vm.get_slot_type(0)
	// s.log.custom('WREN', '$wt')
	msg := vm.get_slot_string(1)
	if msg != '' {
		s.log.custom('WREN', msg)
	}
}

fn wren_fn_shy_sleep(vm &wren.VM) {
	w := unsafe { &WrenVM(vm.get_user_data()) }
	assert !isnil(w), 'WrenVM is nil'
	s := w.shy
	assert !isnil(s), 'Shy is nil'
	sleep_ms := int(vm.get_slot_double(1))
	if sleep_ms > 0 {
		time.sleep(sleep_ms * time.millisecond)
	}
}
