// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module cli

import os
import shy.vxt

pub const exe_version = version()
pub const exe_name = os.file_name(os.executable())
pub const exe_short_name = os.file_name(os.executable()).replace('.exe', '')
pub const exe_dir = os.dir(os.real_path(os.executable()))
pub const exe_description = 'Usage: shy [options] input
or:    shy <sub-command> [options] input

Description: shy is a module and tool made with love.
It is primarily aimed at V developers roaming the creative corners of coding.

shy can compile, package and deploy V apps for a wide range of platforms like:
Linux, macOS, Windows, Android and HTML5 (WASM).

The following does the same as if they were passed to the `v` command:

Flags:
  -autofree, -gc <type>, -g, -cg, -prod, -showcc

Sub-commands:
  run                       Run the V code
  export                    Export shy based project
  doctor                    Display useful info about the system'

pub const exe_git_hash = shy_commit_hash()
pub const work_directory = shy_tmp_work_dir()
pub const cache_directory = shy_cache_dir()
pub const rip_vflags = ['-autofree', '-gc', '-g', '-cg', '-prod', 'run', '-showcc']
pub const subcmds = ['complete', 'doctor', 'export', 'test-cleancode']
pub const accepted_input_files = ['.v']

pub const shy_env_vars = [
	'SHY_FLAGS',
	'VEXE',
	'VMODULES',
]

// check_essentials ensures that the work environment has all needed dependencies
// and meet all required needs.
pub fn check_essentials(exit_on_error bool) {
	// Validate V install
	if vxt.vexe() == '' {
		eprintln('No V install could be detected')
		eprintln('Please install V from https://github.com/vlang/v')
		eprintln('or provide a valid path to V via VEXE env variable')
		if exit_on_error {
			exit(1)
		}
	}
}

// dot_shy_path returns the path to the `.shy` file next to `file_or_dir_path` if found, an empty string otherwise.
pub fn dot_shy_path(file_or_dir_path string) string {
	if os.is_dir(file_or_dir_path) {
		if os.is_file(os.join_path(file_or_dir_path, '.shy')) {
			return os.join_path(file_or_dir_path, '.shy')
		}
	} else {
		if os.is_file(os.join_path(os.dir(file_or_dir_path), '.shy')) {
			return os.join_path(os.dir(file_or_dir_path), '.shy')
		}
	}
	return ''
}

// launch_cmd launches an external command.
pub fn launch_cmd(args []string, no_use_cache bool) ! {
	mut cmd := args[0]
	tool_args := args[1..]
	if cmd.starts_with('test-') {
		cmd = cmd.all_after('test-')
	}
	v := vxt.vexe()
	mut tool_src := os.join_path(exe_dir, 'cmd', cmd)
	tool_exe := tool_src + '.exe'
	if !os.is_dir(tool_src) {
		if os.is_file(tool_src + '.v') {
			tool_src += '.v'
		} else {
			return error('${@MOD}.${@FN}: could not find source for "${cmd}"')
		}
	}
	if os.is_executable(v) {
		hash_file := os.join_path(exe_dir, 'cmd', '.' + cmd + '.hash')

		mut hash := ''
		if os.is_file(hash_file) {
			hash = os.read_file(hash_file) or { '' }
		}
		if hash != exe_git_hash || no_use_cache {
			v_cmd := [
				v,
				'-o',
				tool_exe,
				tool_src,
			]
			res := os.execute(v_cmd.join(' '))
			if res.exit_code < 0 {
				return error('${@MOD}.${@FN} failed compiling "${cmd}": ${res.output}')
			}
			if res.exit_code == 0 {
				os.write_file(hash_file, exe_git_hash) or {}
			} else {
				vcmd := v_cmd.join(' ')
				return error('${@MOD}.${@FN} "${vcmd}" failed:\n${res.output}')
			}
		}
	}
	if os.is_executable(tool_exe) {
		os.setenv('SHY_EXE', os.join_path(exe_dir, exe_name), true)
		$if windows {
			exit(os.system('${os.quoted_path(tool_exe)} ${args}'))
		} $else $if js {
			// no way to implement os.execvp in JS backend
			exit(os.system('${tool_exe} ${args}'))
		} $else {
			os.execvp(tool_exe, args) or { return err }
		}
		exit(2)
	}
	exec := (tool_exe + ' ' + tool_args.join(' ')).trim_right(' ')
	v_message := if !os.is_executable(v) { ' (v was not found)' } else { '' }
	return error('${@MOD}.${@FN} failed executing "${exec}"${v_message}')
}

// string_to_args converts `input` string to an `os.args`-like array.
// string_to_args preserves strings delimited by both `"` and `'`.
pub fn string_to_args(input string) ![]string {
	mut args := []string{}
	mut buf := ''
	mut in_string := false
	mut delim := u8(` `)
	for ch in input {
		if ch in [`"`, `'`] {
			if !in_string {
				delim = ch
			}
			in_string = !in_string && ch == delim
			if !in_string {
				if buf != '' && buf != ' ' {
					args << buf
				}
				buf = ''
				delim = ` `
			}
			continue
		}
		buf += ch.ascii_str()
		if !in_string && ch == ` ` {
			if buf != '' && buf != ' ' {
				args << buf[..buf.len - 1]
			}
			buf = ''
			continue
		}
	}
	if buf != '' && buf != ' ' {
		args << buf
	}
	if in_string {
		return error('${@FN}: could not parse input, missing closing string delimiter `${delim.ascii_str()}`')
	}
	return args
}

// validate_input validates `input` for use with shy.
pub fn validate_input(input string) ! {
	input_ext := os.file_ext(input)

	accepted_input_ext := input_ext in accepted_input_files
	if !(os.is_dir(input) || accepted_input_ext) {
		return error('input should be a V file or a directory containing V sources')
	}
	if accepted_input_ext {
		if !os.is_file(input) {
			return error('input should be a V file or a directory containing V sources')
		}
	}
}
