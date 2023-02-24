module cli

import os
import shy.vxt

fn shy_commit_hash() string {
	mut hash := ''
	git_exe := os.find_abs_path_of_executable('git') or { '' }
	if git_exe != '' {
		mut git_cmd := 'git -C "${exe_dir}" rev-parse --short HEAD'
		$if windows {
			git_cmd = 'git.exe -C "${exe_dir}" rev-parse --short HEAD'
		}
		res := os.execute(git_cmd)
		if res.exit_code == 0 {
			hash = res.output
		}
	}
	return hash.trim_space()
}

fn shy_tmp_work_dir() string {
	return os.join_path(os.temp_dir(), exe_name.replace(' ', '_').replace('.exe', '').to_lower())
}

fn shy_cache_dir() string {
	return os.join_path(os.cache_dir(), exe_name.replace(' ', '_').replace('.exe', '').to_lower())
}

fn version_full() string {
	return '${exe_version} ${exe_git_hash}'
}

fn version() string {
	mut v := '0.0.0'
	vmod := @VMOD_FILE
	if vmod.len > 0 {
		if vmod.contains('version:') {
			v = vmod.all_after('version:').all_before('\n').replace("'", '').replace('"',
				'').trim_space()
		}
	}
	return v
}

// run_subcommand runs any sub-command detected in `args`.
pub fn run_subcommand(args []string) ! {
	nocache := args.contains('--nocache')
	for subcmd in subcmds {
		if subcmd in args {
			// First encountered known sub-command is executed on the spot.
			launch_cmd(args[args.index(subcmd)..], nocache)!
			exit(0)
		}
	}
}

// run runs `cmd`. Any exit codes < 0 is returned as 1, for normalization purposes.
pub fn run(cmd []string) os.Result {
	res := os.execute(cmd.join(' '))
	if res.exit_code < 0 {
		return os.Result{1, res.output}
	}
	return res
}

// run_or_error runs `cmd` and returns it's output.
pub fn run_or_error(cmd []string) !string {
	res := run(cmd)
	if res.exit_code != 0 {
		return error('${cmd.join(' ')} failed with return code ${res.exit_code}:\n${res.output}')
	}
	return res.output
}

// verbosity_print_cmd dumps `cmd` based on `verbosity`.
pub fn verbosity_print_cmd(cmd []string, verbosity int) {
	if cmd.len > 0 && verbosity > 1 {
		cmd_short := cmd[0].all_after_last(os.path_separator)
		mut output := 'Running ${cmd_short} From: ${os.getwd()}'
		if verbosity > 2 {
			output += '\n' + cmd.join(' ')
		}
		eprintln(output)
	}
}

// is_windows_running_in_virtual_box returns `true` if the host system is
// Windows and it is running under VirtualBox.
pub fn is_windows_running_in_virtual_box() bool {
	mut cmd := ''
	$if windows {
		cmd = 'WMIC COMPUTERSYSTEM GET MODEL'
	}
	if cmd != '' {
		res := os.execute(cmd)
		if res.exit_code == 0 {
			return res.output.contains('VirtualBox')
		}
	}
	return false
}

pub fn ensure_path(path string) !string {
	if !os.is_dir(path) {
		os.mkdir_all(path)!
	}
	return path
}

pub struct VCompileOptions {
pub:
	verbosity int // level of verbosity
	cache     bool
	work_dir  string // temporary work directory
	input     string
	flags     []string // flags to pass to the v compiler
}

// uses_gc returns true if a `-gc` flag is found among the passed v flags.
pub fn (opt VCompileOptions) uses_gc() bool {
	mut uses_gc := true // V default
	for v_flag in opt.flags {
		if v_flag.starts_with('-gc') {
			if v_flag.ends_with('none') {
				uses_gc = false
			}
			break
		}
	}
	return uses_gc
}

pub struct VMetaInfo {
pub:
	imports []string
	c_flags []string
}

// v_dump_meta returns the information dumped by
// -dump-modules and -dump-c-flags.
pub fn v_dump_meta(opt VCompileOptions) !VMetaInfo {
	err_sig := @MOD + '.' + @FN
	os.mkdir_all(opt.work_dir) or {
		return error('${err_sig}: failed making directory "${opt.work_dir}". ${err}')
	}

	vexe := vxt.vexe()

	uses_gc := opt.uses_gc()

	// Dump modules and C flags to files
	v_cflags_file := os.join_path(opt.work_dir, 'v.cflags')
	os.rm(v_cflags_file) or {}
	v_dump_modules_file := os.join_path(opt.work_dir, 'v.modules')
	os.rm(v_dump_modules_file) or {}

	mut v_cmd := [
		vexe,
	]
	if !uses_gc {
		v_cmd << '-gc none'
	}
	if !opt.cache {
		v_cmd << '-nocache'
	}
	v_cmd << opt.flags
	v_cmd << [
		'-dump-modules "${v_dump_modules_file}"',
		'-dump-c-flags "${v_cflags_file}"',
	]
	v_cmd << opt.input

	verbosity_print_cmd(v_cmd, opt.verbosity)
	v_dump_res := run_or_error(v_cmd)!
	if opt.verbosity > 3 {
		eprintln(v_dump_res)
	}

	// Read in the dumped cflags
	cflags := os.read_file(v_cflags_file) or {
		flat_cmd := v_cmd.join(' ')
		return error('${err_sig}: failed reading C flags to "${v_cflags_file}". ${err}\nCompile output of `${flat_cmd}`:\n${v_dump_res}')
	}

	// Parse imported modules from dump
	mut imported_modules := os.read_file(v_dump_modules_file) or {
		flat_cmd := v_cmd.join(' ')
		return error('${err_sig}: failed reading module dump file "${v_dump_modules_file}". ${err}\nCompile output of `${flat_cmd}`:\n${v_dump_res}')
	}.split('\n').filter(it != '')
	imported_modules.sort()
	if opt.verbosity > 2 {
		eprintln('Imported modules: ${imported_modules}')
	}

	return VMetaInfo{
		imports: imported_modules
		c_flags: cflags.split('\n')
	}
}
