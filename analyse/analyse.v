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

// count adds the `key` entry to the report, if not already there, and
// increase it's value by `amount`.
[if shy_analyse ?]
pub fn count[T](key string, amount T) {
	mut a := unsafe { analyse.hack } // TODO
	$if T is int {
		a.entries[key] = '${a.entries[key].int() + amount}'
	} $else $if T is f32 {
		a.entries[key] = '${a.entries[key].f32() + amount}'
	} $else $if T is f64 {
		a.entries[key] = '${a.entries[key].f64() + amount}'
	} $else {
		t := T{}
		panic('${@STRUCT}.${@FN}: ${typeof(t).name} is not supported')
	}
}

// eprintln_report prints the report via `eprintln`.
[if shy_analyse ?]
pub fn eprintln_report() {
	a := analyse.hack
	eprintln('--- analysis report ---')
	for k, v in a.entries {
		eprintln('${k}: ${v}')
	}
}
