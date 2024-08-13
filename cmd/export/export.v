// Copyright(C) 2019 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license file distributed with this software package
//
module main

import os
import flag
// import shy.vxt
import shy.cli
import shy.export

pub const exe_version = '0.0.2' // version()

pub const exe_name = os.file_name(os.executable())
pub const exe_short_name = os.file_name(os.executable()).replace('.exe', '')
pub const exe_dir = os.dir(os.real_path(os.executable()))
pub const exe_args_description = 'input
or:    [options] input'

pub const exe_description = 'export exports both plain V applications and shy-based applications.
The exporter is based on the `shy.export` module.

export can compile, package and deploy V apps for production use on a
wide range of platforms like:
Linux, macOS, Windows, Android and HTML5 (WASM).

The following does the same as if they were passed to the v compiler:

Flags:
  -autofree, -gc <type>, -g, -cg, -showcc

Sub-commands:
  run                       Run the output package after successful export'

pub const rip_vflags = ['-autofree', '-gc', '-g', '-cg', 'run', '-showcc']
pub const accepted_input_files = ['.v']

pub const export_env_vars = [
	'SHY_FLAGS',
	'SHY_EXPORT_FLAGS',
	'VEXE',
	'VMODULES',
]

/*
pub fn run(args []string) os.Result {
	return os.execute(args.join(' '))
}*/
pub struct Options {
pub:
	// These fields would make little sense to change during a run
	verbosity int    @[only: v; repeats; xdoc: 'Verbosity level 1-3']
	work_dir  string = export.work_dir() @[xdoc: 'Directory to use for temporary work files']
	//
	run         bool   @[ignore]
	no_parallel bool   @[xdoc: 'Do not run tasks in parallel'] // Run, what can be run, in parallel
	nocache     bool   @[xdoc: 'Do not use caching']           // defaults to false in os.args/flag parsing phase
	gl_version  string = '3' @[only: gl; xdoc: 'GL(ES) version to use from any of 3,es3']
	format      string = 'zip' @[xdoc: 'Format of output (default is a .zip)']
	// echo and exit
	dump_usage   bool @[long: help; short: h; xdoc: 'Show this help message and exit']
	show_version bool @[long: version; xdoc: 'Output version information and exit']
mut:
	unmatched_args []string @[ignore] // args that could not be matched
pub mut:
	// I/O
	input        string   @[tail]
	output       string   @[short: o; xdoc: 'Path to output (dir/file)']
	is_prod      bool = true     @[ignore]
	c_flags      []string @[long: cflag; short: c; xdoc: 'Additional flags for the C compiler'] // flags passed to the C compiler(s)
	v_flags      []string @[long: flag; short: f; xdoc: 'Additional flags for the V compiler']  // flags passed to the V compiler
	assets_extra []string @[long: asset; short: a; xdoc: 'Asset dir(s) to include in build']    // list of (extra) paths to assets dirs to include
	libs_extra   []string @[long: libs; short: l; xdoc: 'Lib dir(s) to include in build']
}

// options_from_env returns an `Option` struct filled with flags set via
// the `SHY_EXPORT_FLAGS` env variable otherwise it returns the `defaults` `Option` struct.
pub fn options_from_env(defaults Options) !Options {
	env_flags := os.getenv('SHY_EXPORT_FLAGS')
	if env_flags != '' {
		mut flags := [os.args[0]]
		flags << cli.string_to_args(env_flags)!
		opts := args_to_options(flags, defaults)!
		return opts
	}
	return defaults
}

// extend_from_dot_shy will merge the `Options` with any content
// found in any `.shy` config files.
pub fn (mut opt Options) extend_from_dot_shy() ! {
	// Look up values in input .shy file next to input if no flags or defaults was set
	// TODO use TOML format here
	// dot_shy_file := dot_shy_path(opt.input)
	// dot_shy := os.read_file(dot_shy_file) or { '' }
}

// validate_env ensures that `Options` meet all runtime requirements.
pub fn (opt &Options) validate_env() ! {}

// args_to_options returns an `Option` merged from (CLI/Shell) `arguments` using `defaults` as
// values where no value can be obtained from `arguments`.
pub fn args_to_options(arguments []string, defaults Options) !Options {
	mut args := arguments.clone()

	mut v_flags := []string{}
	mut cmd_flags := []string{}
	// Indentify special flags in args before FlagParser ruin them.
	// E.g. the -autofree flag will result in dump_usage being called for some weird reason???
	for special_flag in rip_vflags {
		if special_flag in args {
			if special_flag == '-gc' {
				gc_type := args[(args.index(special_flag)) + 1]
				v_flags << special_flag + ' ${gc_type}'
				args.delete(args.index(special_flag) + 1)
			} else if special_flag.starts_with('-') {
				v_flags << special_flag
			} else {
				cmd_flags << special_flag
			}
			args.delete(args.index(special_flag))
		}
	}

	mut opt, unmatched_args := flag.using(defaults, args, skip: 1)!

	// Validate format
	if opt.format != '' {
		export.string_to_export_format(opt.format)!
	}

	mut unmatched := unmatched_args.clone()
	for unmatched_arg in defaults.unmatched_args {
		if unmatched_arg !in unmatched {
			unmatched << unmatched_arg
		}
	}
	opt.unmatched_args = unmatched

	mut c_flags := []string{}
	c_flags << opt.c_flags
	for c_flag in defaults.c_flags {
		if c_flag !in c_flags {
			c_flags << c_flag
		}
	}
	opt.c_flags = c_flags

	v_flags << opt.v_flags
	for v_flag in defaults.v_flags {
		if v_flag !in v_flags {
			v_flags << v_flag
		}
	}
	opt.v_flags = v_flags

	return opt
}

pub fn (opt &Options) to_export_options() export.Options {
	format := export.string_to_export_format(opt.format) or { export.Format.zip }
	mut gl_version := opt.gl_version

	opts := export.Options{
		verbosity:  opt.verbosity
		work_dir:   opt.work_dir
		parallel:   !opt.no_parallel
		cache:      !opt.nocache
		gl_version: gl_version
		format:     format
		input:      opt.input
		output:     opt.output
		is_prod:    opt.is_prod
		c_flags:    opt.c_flags
		v_flags:    opt.v_flags
		assets:     opt.assets_extra
	}
	return opts
}

fn main() {
	args := os.args[1..]

	// Collect user flags in an extended manner.
	mut opt := Options{}

	/* TODO: (lmp) fix this .shy should be used first, then from env then flags... right?
	opt = extend_from_dot_shy() or {
		eprintln('Error while parsing `.shy`: ${err}')
		eprintln('Use `${cli.exe_short_name} -h` to see all flags')
		exit(1)
	}
	*/

	opt = options_from_env(opt) or {
		eprintln('Error while parsing `SHY_EXPORT_FLAGS`: ${err}')
		eprintln('Use `${exe_short_name} -h` to see all flags')
		exit(1)
	}

	opt = args_to_options(args, opt) or {
		eprintln('Error while parsing `os.args`: ${err}')
		eprintln('Use `${exe_short_name} -h` to see all flags')
		exit(1)
	}

	if args.len == 1 {
		eprintln('No arguments given')
		eprintln('Use `shy export -h` to see all flags')
		exit(1)
	}

	if opt.show_version {
		println('${exe_short_name} ${exe_version}')
		exit(0)
	}

	if opt.dump_usage {
		println(flag.to_doc[Options](
			name:        'shy ${exe_short_name}'
			version:     '${exe_version}'
			description: exe_description
			// options:     flag.DocOptions{
			// 	compact: true
			// }
		)!)
		exit(0)
	}

	// All flags after this requires an input argument
	if opt.input == '' {
		dump(opt)
		eprintln('No input given')
		eprintln('See `shy export -h` for help')
		exit(1)
	}

	// Validate environment after options and input has been resolved
	opt.validate_env() or { panic(err) }

	// input_ext := os.file_ext(opt.input)
	if opt.verbosity > 2 {
		dump(opt)
	}

	// TODO
	if opt.unmatched_args.len > 1 {
		eprintln('Unknown args: ${opt.unmatched_args}')
		exit(1)
	}

	// Validate environment after options and input has been resolved
	opt.validate_env() or {
		eprintln('${err}')
		exit(1)
	}

	// input_ext := os.file_ext(opt.input)
	if opt.verbosity > 3 {
		eprintln('--- ${exe_short_name} ---')
		eprintln(opt)
	}

	export_opts := opt.to_export_options()
	export.export(export_opts) or {
		eprintln('Error while exporting `${export_opts.input}`: ${err}')
		exit(1)
	}
}
