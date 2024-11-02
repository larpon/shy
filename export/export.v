// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module export

import os
import shy.paths

pub const supported_exporters = ['zip', 'dir', 'android', 'appimage', 'wasm']!

pub struct ExportOptions {
pub:
	// These fields would make little sense to change during a run
	verbosity int    @[short: v; xdoc: 'Verbosity level 1-3']
	work_dir  string = os.join_path(paths.tmp_work(), 'export', 'appimage') @[ignore]
	//
	run      bool @[ignore]
	parallel bool = true @[long: 'no-parallel'; xdoc: 'Do not run tasks in parallel.']
	cache    bool = true @[long: 'no-cache'; xdoc: 'Do not use cache']
	// echo and exit
	dump_usage   bool @[long: help; short: h; xdoc: 'Show this help message and exit']
	show_version bool @[long: version; xdoc: 'Output version information and exit']
pub mut:
	// I/O
	input  string @[tail]
	output string @[short: o; xdoc: 'Path to output (dir/file)']
	// variant Variant
	c_flags []string @[long: 'cflag'; short: c; xdoc: 'Additional flags for the C compiler']
	v_flags []string @[long: 'flag'; short: f; xdoc: 'Additional flags for the V compiler']
	assets  []string @[short: a; xdoc: 'Asset dir(s) to include in build']
mut:
	supported_v_flags SupportedVFlags @[ignore] // export supports a selected range of V flags, these are parsed and dealt with separately
}

// verbose prints `msg` to STDOUT if `AppImageOptions.verbosity` level is >= `verbosity_level`.
pub fn (eo &ExportOptions) verbose(verbosity_level int, msg string) {
	if eo.verbosity >= verbosity_level {
		println(msg)
	}
}

pub fn (opt ExportOptions) is_debug_build() bool {
	return opt.supported_v_flags.v_debug || opt.supported_v_flags.c_debug || '-cg' in opt.v_flags
		|| '-g' in opt.v_flags
}

pub struct Result {
pub:
	output string
}

struct SupportedVFlags {
pub:
	autofree           bool
	gc                 string
	v_debug            bool @[long: g]
	c_debug            bool @[long: cg]
	prod               bool
	showcc             bool
	skip_unused        bool
	no_bounds_checking bool
}

fn (svf &SupportedVFlags) as_v_flags() []string {
	mut v_flags := []string{}
	if svf.autofree {
		v_flags << '-autofree'
	}
	if svf.gc != '' {
		v_flags << '-gc ${svf.gc}'
	}
	if svf.v_debug {
		v_flags << '-g'
	}
	if svf.c_debug {
		v_flags << '-cg'
	}
	if svf.prod {
		v_flags << '-prod'
	}
	if svf.showcc {
		v_flags << '-showcc'
	}
	if svf.skip_unused {
		v_flags << '-skip-unused'
	}
	if svf.no_bounds_checking {
		v_flags << '-no-bounds-checking'
	}
	return v_flags
}

pub fn ensure_cache_dir() !string {
	dir := os.join_path(paths.cache(), 'export')
	paths.ensure(dir)!
	return dir
}
