// Copyright(C) 2019 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license file distributed with this software package
//
module main

import os
import flag
// import shy.vxt
import shy.cli
import shy.export

pub const exe_version = '0.0.1' // version()

pub const exe_name = os.file_name(os.executable())
pub const exe_short_name = os.file_name(os.executable()).replace('.exe', '')
pub const exe_dir = os.dir(os.real_path(os.executable()))
pub const exe_args_description = 'input
or:    [options] input'

pub const exe_description = 'export exports both plain V applications and shy-based applications.
The exporter is based on the shy.export module.

export can compile, package and deploy V apps for production use on a wide range of platforms like:
Linux, macOS, Windows, Android and HTML5 (WASM).

The following does the same as if they were passed to the "v" compiler:

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
	verbosity int
	work_dir  string = export.work_dir()
	//
	run        bool
	parallel   bool = true // Run, what can be run, in parallel
	cache      bool // defaults to false in os.args/flag parsing phase
	gl_version string = '2'
	format     string
	// Detected environment
	dump_usage bool
pub mut:
	// I/O
	input           string
	output          string
	additional_args []string // additional_args passed via os.args
	is_prod         bool = true
	c_flags         []string // flags passed to the C compiler(s)
	v_flags         []string // flags passed to the V compiler
	assets_extra    []string // list of (extra) paths to assets dirs to include
	libs_extra      []string
}

// options_from_env returns an `Option` struct filled with flags set via
// the `SHY_EXPORT_FLAGS` env variable otherwise it returns the `defaults` `Option` struct.
pub fn options_from_env(defaults Options) !Options {
	env_flags := os.getenv('SHY_EXPORT_FLAGS')
	if env_flags != '' {
		mut flags := [os.args[0]]
		flags << cli.string_to_args(env_flags)!
		opts, _ := args_to_options(flags, defaults)!
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
pub fn (opt &Options) validate_env() ! {
}

// args_to_options returns an `Option` merged from (CLI/Shell) `arguments` using `defaults` as
// values where no value can be obtained from `arguments`.
pub fn args_to_options(arguments []string, defaults Options) !(Options, &flag.FlagParser) {
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

	mut fp := flag.new_flag_parser(args)
	fp.application(exe_short_name)
	fp.version(exe_version)
	fp.description(exe_description)
	fp.arguments_description(exe_args_description)

	fp.skip_executable()

	mut verbosity := fp.int_opt('verbosity', `v`, 'Verbosity level 1-3') or { defaults.verbosity }
	if ('-v' in args || 'verbosity' in args) && verbosity == 0 {
		verbosity = 1
	}

	mut opt := Options{
		assets_extra: fp.string_multi('assets', `a`, 'Asset dir(s) to include in build')
		libs_extra: fp.string_multi('libs', `a`, 'Lib dir(s) to include in build')
		v_flags: fp.string_multi('flag', `f`, 'Additional flags for the V compiler')
		c_flags: fp.string_multi('cflag', `c`, 'Additional flags for the C compiler')
		gl_version: fp.string('gl', 0, defaults.gl_version, 'GL(ES) version to use from any of 2,3,es2,es3')
		//
		run: 'run' in cmd_flags
		format: fp.string('format', 0, 'zip', 'Format of output (default is a .zip)')
		dump_usage: fp.bool('help', `h`, defaults.dump_usage, 'Show this help message and exit')
		cache: !fp.bool('nocache', 0, defaults.cache, 'Do not use build cache')
		//
		output: fp.string('output', `o`, defaults.output, 'Path to output (dir/file)')
		//
		verbosity: verbosity
		parallel: !fp.bool('no-parallel', 0, false, 'Do not run tasks in parallel.')
		//
		work_dir: defaults.work_dir
	}

	opt.additional_args = fp.finalize() or {
		return error('${@FN}: flag parser failed finalizing: ${err}')
	}

	// Validate format
	if opt.format != '' {
		export.string_to_export_format(opt.format)!
	}

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

	return opt, fp
}

pub fn (opt &Options) to_export_options() export.Options {
	format := export.string_to_export_format(opt.format) or { export.Format.zip }
	mut gl_version := opt.gl_version

	opts := export.Options{
		verbosity: opt.verbosity
		work_dir: opt.work_dir
		parallel: opt.parallel
		cache: opt.cache
		gl_version: gl_version
		format: format
		input: opt.input
		output: opt.output
		is_prod: opt.is_prod
		c_flags: opt.c_flags
		v_flags: opt.v_flags
		assets: opt.assets_extra
	}
	return opts
}

fn main() {
	// Collect user flags in an extended manner.
	// Start with defaults -> merge over SHY_EXPORT_FLAGS -> merge over cmdline flags -> merge .shy entries.
	mut opt := Options{}
	mut fp := &flag.FlagParser(unsafe { nil })

	opt = options_from_env(opt) or {
		eprintln('Error while parsing `SHY_EXPORT_FLAGS`: ${err}')
		eprintln('Use `${exe_short_name} -h` to see all flags')
		exit(1)
	}

	opt, fp = args_to_options(os.args, opt) or {
		eprintln('Error while parsing `os.args`: ${err}')
		eprintln('Use `${exe_short_name} -h` to see all flags')
		exit(1)
	}

	if opt.dump_usage {
		println(fp.usage())
		exit(0)
	}

	// All flags after this requires an input argument
	if fp.args.len == 0 {
		eprintln('No arguments given')
		eprintln('Use `export -h` to see all flags')
		exit(1)
	}

	// TODO
	if opt.additional_args.len > 1 {
		if opt.additional_args[0] == 'xxx' {
			// xxx_arg := opt.additional_args[1]
			exit(1)
		}
	}

	input := fp.args.last()
	opt.input = input

	cli.validate_input(opt.input) or {
		eprintln('${err}')
		exit(1)
	}

	opt.extend_from_dot_shy() or {
		eprintln('Error while parsing `.shy`: ${err}')
		eprintln('Use `${exe_short_name} -h` to see all flags')
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
