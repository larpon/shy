// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module export

import flag

pub struct AndroidOptions {
pub:
	// These fields would make little sense to change during a run
	verbosity int @[only: v; repeats; xdoc: 'Verbosity level 1-3']
	work_dir  string // TODO:
	//
	run      bool @[ignore]
	nocache  bool @[xdoc: 'Do not use caching'] // defaults to false in os.args/flag parsing phase
	parallel bool = true @[long: 'no-parallel']                        // Run, what can be run, in parallel
	// echo and exit
	dump_usage   bool @[long: help; short: h; xdoc: 'Show this help message and exit']
	show_version bool @[long: version; xdoc: 'Output version information and exit']
pub mut:
	// I/O
	input   string
	output  string
	is_prod bool
	c_flags []string // flags passed to the C compiler(s)
	v_flags []string // flags passed to the V compiler
	assets  []string // list of (extra) paths to asset (roots) dirs to include
}

pub fn args_to_android_options(args []string) !AndroidOptions {
	opt, _ := flag.to_struct[AndroidOptions](args, skip: 1)!
	return opt
}

pub fn android(opt AndroidOptions) !Result {
	// mut gl_version := opt.gl_version
	// match opt.format {
	// 	.android_apk, .android_aab {
	// 		if gl_version in ['3', '2'] {
	// 			mut auto_gl_version := 'es2'
	// 			if gl_version == '3' {
	// 				auto_gl_version = 'es3'
	// 			}
	// 			if opt.verbosity > 0 {
	// 				eprintln('Auto adjusting OpenGL version for Android from ${gl_version} to ${auto_gl_version}')
	// 			}
	// 			gl_version = auto_gl_version
	// 		}
	// 	}
	// 	else {}
	// }
	// adjusted_options := Options{
	// 	...opt
	// 	gl_version: gl_version
	// }
	// if opt.verbosity > 3 {
	eprintln('--- ${@MOD}.${@FN} ---')
	// eprintln(adjusted_options)
	//}
	return Result{
		output: ''
	}
}
