// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module analyse

const hack = init()

fn init() &Analysis {
	$if !shy_analyse ? {
		return unsafe { nil }
	}
	return &Analysis{}
}

[if shy_analyse ?]
struct Analysis {
mut:
	entries map[string]string
}

[if shy_analyse ?]
pub fn count[T](key string, entry T) {
	mut a := unsafe { analyse.hack }
	$if T is int {
		a.entries[key] = '${a.entries[key].int() + entry}'
	} $else $if T is f32 {
		a.entries[key] = '${a.entries[key].f32() + entry}'
	} $else $if T is f64 {
		a.entries[key] = '${a.entries[key].f64() + entry}'
	} $else {
		t := T{}
		panic('${@STRUCT}.${@FN}: ${typeof(t).name} is not supported')
	}
}

[if shy_analyse ?]
pub fn eprintln_report() {
	a := analyse.hack
	eprintln('--- analysis report ---')
	for k, v in a.entries {
		eprintln('${k}: ${v}')
	}
}
