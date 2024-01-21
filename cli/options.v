module cli

import os
import shy.vxt
import flag

pub struct Options {
pub:
	// These fields would make little sense to change during a run
	verbosity int
	work_dir  string = work_directory
	//
	run        bool
	parallel   bool = true // Run, what can be run, in parallel
	cache      bool // defaults to false in os.args/flag parsing phase
	gl_version string = '3'
	// Detected environment
	dump_usage bool
pub mut:
	// I/O
	input           string
	output          string
	additional_args []string // additional_args passed via os.args
	is_prod         bool
	c_flags         []string // flags passed to the C compiler(s)
	v_flags         []string // flags passed to the V compiler
	assets_extra    []string // list of (extra) paths to assets dirs to include
	libs_extra      []string
}

// options_from_env returns an `Option` struct filled with flags set via
// the `SHY_FLAGS` env variable otherwise it returns the `defaults` `Option` struct.
pub fn options_from_env(defaults Options) !Options {
	env_flags := os.getenv('SHY_FLAGS')
	if env_flags != '' {
		mut flags := [os.args[0]]
		flags << string_to_args(env_flags)!
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
	fp.version(version_full())
	fp.description(exe_description)
	fp.arguments_description(exe_args_description)

	fp.skip_executable()

	mut verbosity := fp.int_opt('verbosity', `v`, 'Verbosity level 1-3') or { defaults.verbosity }
	if ('-v' in args || 'verbosity' in args) && verbosity == 0 {
		verbosity = 1
	}

	mut opt := Options{
		assets_extra: fp.string_multi('assets', `a`, 'Asset dir(s) to include in build')
		libs_extra: fp.string_multi('libs', `l`, 'Lib dir(s) to include in build')
		v_flags: fp.string_multi('flag', `f`, 'Additional flags for the V compiler')
		c_flags: fp.string_multi('cflag', `c`, 'Additional flags for the C compiler')
		gl_version: fp.string('gl', 0, defaults.gl_version, 'GL(ES) version to use from any of 2,3,es2,es3')
		//
		run: 'run' in cmd_flags
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

// shy_v builds `opt.input` as `v` would have done normally, except
// on Windows where it'll orchestrate copying of known dll's to make building
// and running more pleasing.
pub fn (opt &Options) shy_v() ! {
	v_exe := vxt.vexe()
	input := opt.input
	mut v_cmd := [
		v_exe,
	]
	if !opt.cache {
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
				cache: opt.cache
				flags: opt.v_flags
				work_dir: os.join_path(opt.work_dir, 'v')
				input: opt.input
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
