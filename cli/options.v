module cli

import os
import shy.vxt
import flag

pub struct Options {
pub:
	// These fields would make little sense to change during a run
	verbosity int    @[only: v; repeats; xdoc: 'Verbosity level 1-3']
	work_dir  string = work_directory @[xdoc: 'Directory to use for temporary work files']
	//
	nocache bool @[xdoc: 'Do not use caching']
	//
	run bool @[ignore]
	// print info and exit
	dump_usage   bool @[long: help; short: h; xdoc: 'Show this help message and exit']
	show_version bool @[long: version; xdoc: 'Output version information and exit']
pub mut:
	// I/O
	input  string @[tail]
	output string @[short: o; xdoc: 'Path to output (dir/file)']
	// additional_args []string // additional_args passed via os.args
	is_prod      bool
	c_flags      []string @[long: cflag; short: c; xdoc: 'Additional flags for the C compiler']
	v_flags      []string @[long: flag; short: f; xdoc: 'Additional flags for the V compiler']
	assets_extra []string @[long: asset; short: a; xdoc: 'Asset dir(s) to include in build']
	libs_extra   []string @[long: libs; short: l; xdoc: 'Lib dir(s) to include in build']
}

// options_from_env returns an `Option` struct filled with flags set via
// the `SHY_FLAGS` env variable otherwise it returns the `defaults` `Option` struct.
pub fn options_from_env(defaults Options) !Options {
	env_flags := os.getenv('SHY_FLAGS')
	if env_flags != '' {
		mut flags := [os.args[0]]
		flags << string_to_args(env_flags)!
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

pub fn (opt &Options) ensure_work_dir() !string {
	return ensure_path(opt.work_dir)
}

// verbosity_print_cmd dumps `cmd` based on `verbosity`.
pub fn (opt &Options) verbosity_print_cmd(cmd []string) {
	if cmd.len > 0 && opt.verbosity > 1 {
		cmd_short := cmd[0].all_after_last(os.path_separator)
		mut output := 'Running ${cmd_short} From: ${os.getwd()}'
		if opt.verbosity > 2 {
			output += '\n' + cmd.join(' ')
		}
		eprintln(output)
	}
}

// uses_gc returns true if a `-gc` flag is found among the passed v flags.
pub fn (opt &Options) uses_gc() bool {
	mut uses_gc := true // V default
	for v_flag in opt.v_flags {
		if v_flag.starts_with('-gc') {
			if v_flag.ends_with('none') {
				uses_gc = false
			}
			break
		}
	}
	return uses_gc
}

// args_to_options returns an `Option` merged from (CLI/Shell) `arguments` using `defaults` as
// values where no value can be obtained from `arguments`.
pub fn args_to_options(arguments []string, defaults Options) !Options {
	mut args := arguments.clone()

	// Indentify special flags in args before passing them on
	mut v_flags := []string{}
	mut cmd_flags := []string{}
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

	mut opt, _ := flag.using(defaults, args)!

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

// shy_v builds `opt.input` as `v` would have done normally, except
// on Windows where it'll orchestrate copying of known dll's to make building
// and running more pleasing.
pub fn (opt &Options) shy_v() ! {
	v_exe := vxt.vexe()
	input := opt.input
	mut v_cmd := [
		v_exe,
	]
	if opt.nocache {
		v_cmd << '-nocache'
	}
	if opt.is_prod {
		v_cmd << '-prod'
	}
	v_cmd << opt.v_flags
	$if !windows {
		if opt.run {
			v_cmd << 'run'
		}
	} $else {
		// On Windows
		mut out_path := input
		if os.is_file(out_path) {
			out_path = os.dir(out_path)
		}
		out_name := os.file_name(input).all_before_last('.') + '.exe'
		out_file := os.join_path(out_path, out_name)
		v_cmd << '-o "${out_file}"'
	}
	v_cmd << input
	opt.verbosity_print_cmd(v_cmd)
	run_or_error(v_cmd)!
	$if windows {
		if opt.run {
			v_compile_opt := VCompileOptions{
				verbosity: opt.verbosity
				cache:     !opt.nocache
				flags:     opt.v_flags
				work_dir:  os.join_path(opt.work_dir, 'v')
				input:     opt.input
			}

			v_meta_dump := v_dump_meta(v_compile_opt)!
			imported_modules := v_meta_dump.imports

			// TODO if is_windows_running_in_virtual_box() // copy the mesa opengl32.dll
			if 'sdl' in imported_modules {
				// Use sdl libs in `thirdparty` if user has followed the install instructions already.
				sdl_mod_thirdparty_path := os.join_path(vxt.vmodules()!, 'sdl', 'thirdparty')
				if os.exists(sdl_mod_thirdparty_path) {
				}
			}
		}
	}
}
