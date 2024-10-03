// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module export

import os
import shy.vxt
// import vab.cli

pub const available_format_strings = ['zip', 'directory', 'appimage_dir', 'appimage', 'apk', 'aab']

pub fn work_dir() string {
	return os.join_path(os.temp_dir(), 'export')
}

pub fn ensure_cache_dir() !string {
	dir := os.join_path(os.cache_dir(), 'shy', 'export')
	if !os.is_dir(dir) {
		os.mkdir_all(dir)!
	}
	return dir
}

pub enum Variant {
	generic
	steam
	steam_runtime
}

pub enum Format {
	zip          // .zip
	directory    // /path/to/output
	appimage_dir // .AppDir
	appimage     // .AppImage
	android_apk  // .apk
	android_aab  // .aab
}

pub fn (f Format) ext() string {
	return match f {
		.zip {
			'zip'
		}
		.directory {
			''
		}
		.appimage_dir {
			'AppDir'
		}
		.appimage {
			'AppImage'
		}
		.android_apk {
			'apk'
		}
		.android_aab {
			'aab'
		}
	}
}

pub struct Options {
pub:
	// These fields would make little sense to change during a run
	verbosity int
	work_dir  string = work_dir()
	//
	run        bool
	parallel   bool = true // Run, what can be run, in parallel
	compress   bool // Run upx if the host has it installed
	cache      bool // defaults to false in os.args/flag parsing phase
	gl_version string = '3'
pub mut:
	// I/O
	input   string
	output  string
	format  Format
	variant Variant
	is_prod bool
	c_flags []string // flags passed to the C compiler(s)
	v_flags []string // flags passed to the V compiler
	assets  []string // list of (extra) paths to asset (roots) dirs to include
}

// resolve_input returns the resolved path/file of the input.
fn (opt &Options) resolve_input() !string {
	mut input := opt.input
	// If no specific output file is given, we use the input file as a base
	if input == '' {
		return error('${@MOD}.${@FN}: no input given')
	}

	if input in ['.', '..'] {
		input = os.real_path(input)
	}
	return input
}

pub fn (opt &Options) resolve_io() !(string, string, Format) {
	mut input := opt.resolve_input()!
	mut output := opt.output
	// If no specific output file is given, we use the input file as a base
	if output == '' {
		output = input
	}
	mut format := opt.format
	ext := os.file_ext(output).all_after('.').to_lower()
	// If user has explicitly named the output. E.g.: '/tmp/out.apk'
	if ext != '' {
		format = string_to_export_format(ext)!
		return input, output, format
	}
	return input, output + '.' + format.ext(), format
}

pub fn export(opt &Options) ! {
	if vxt.vexe() == '' {
		return error('${@MOD}.${@FN}: No V install could be detected')
	}

	if !os.is_dir(opt.work_dir) {
		os.mkdir_all(opt.work_dir)!
	}

	// Determine output path/file and format.
	input, output, format := opt.resolve_io()!

	resolved_options := Options{
		...opt
		input:  input
		output: output
		format: format
	}

	if opt.verbosity > 0 {
		eprintln('Exporting "${opt.input}" as ${format} to "${output}"...')
	}
	uos := os.user_os()
	match format {
		.zip {
			return error('${@MOD}.${@FN}: zip export is not working yet')
		}
		.directory {
			return error('${@MOD}.${@FN}: directory export is not working yet')
		}
		.appimage, .appimage_dir {
			if uos != 'linux' {
				return error('${@MOD}.${@FN}: AppImage format is only supported on Linux hosts')
			}
			export_appimage(resolved_options)!
		}
		.android_apk, .android_aab {
			export_android(resolved_options)!
		}
	}
}

pub fn string_to_export_format(str string) !Format {
	return match str {
		'zip' {
			.zip
		}
		'directory' {
			.directory
		}
		'appimage' {
			.appimage
		}
		'appimage_dir' {
			.appimage_dir
		}
		'android_apk', 'apk' {
			.android_apk
		}
		'android_aab', 'aab' {
			.android_aab
		}
		else {
			error('${@MOD}.${@FN}: unsupported format "${str}". Available: ${available_format_strings}')
		}
	}
}

// pub struct Dependency{
// 	path string
// 	// { 'so':so, 'path':path, 'realpath':realpath, 'dependants':set([executable]), 'type':'lib' }
// }

struct ResolveDependenciesConfig {
	verbosity    int
	indent       int
	exe          string
	excludes     []string
	skip_resolve []string
	format       Format
}

fn resolve_dependencies_recursively(mut deps map[string]string, config ResolveDependenciesConfig) ! {
	// Resolving shared object (.so) dependencies on Linux is not as straight forward as
	// one could wish for. Using `objdump` alone gives us only the *names* of the
	// shared objects, not the full path. Using only `ldd` *does* result in resolved lib paths BUT
	// they're done recursively, in some cases by executing the exe/lib - and, on top, it's printed
	// *in one stream* which makes it impossible to know which libs has dependencies on which,
	// further more `ldd` has security issues and problems with cross-compiled binaries.
	// The issues are mostly ignored in our case since we consider the input (v sources -> binary)
	// "trusted" and we do not support V cross-compiled binaries anyway at this point
	// (Not sure AppImages even support it?!).
	//
	// Digging even further and reading source code of programs like `lddtree` will reveal
	// that it's not straight forward to know what `.so` will be loaded by `ld` upon execution
	// due to LD_LIBRARY_PATH mess and misuse etc.
	//
	// So. For now we've chosen a solution using a mix of both `objdump` and `ldd` - it has pitfalls for sure -
	// but how many and how severe - only time will tell. If we are to do this "correctly" it'll need a lot
	// more development time and special-cases (and native V modules for reading ELF binaries etc.) than what
	// is feasible right now; We really just want to be able to collect a bunch of shared object files that
	// a given V executable rely on in-order for us to collect them and package them up, for example, in an AppImage.
	//
	// The strategy is thus the following:
	// 1. Run `objdump` on the exe/so file (had to choose one; readelf lost:
	// https://stackoverflow.com/questions/8979664/readelf-vs-objdump-why-are-both-needed)
	// this gives us the immediate (1st level) dependencies of the app.
	// 2. Run `ldd` on the same exe/so file to obtain the first encountered resolved path(s) to the 1st level exe/so dependency.
	// 3. Do step 1 and 2 for all dependencies, recursively
	// 4. Cross our fingers and assume that 99.99% of cases will end up having happy users.
	// The remaining user pool will hopefully be tech savy enough to fix/extend things themselves.

	verbosity := config.verbosity
	indent := config.indent
	mut root_indents := '  '.repeat(indent) + ' '
	if indent == 0 {
		root_indents = ''
	}
	indents := '  '.repeat(indent + 1) + ' '
	executable := config.exe
	excludes := config.excludes
	skip_resolve := config.skip_resolve

	if verbosity > 0 {
		base := os.file_name(executable)
		eprintln('${root_indents}${base} (include)')
	}
	objdump_cmd := [
		'objdump',
		'-x',
		executable,
	]
	od_res := os.execute(objdump_cmd.join(' '))
	if od_res.exit_code != 0 {
		cmd := objdump_cmd.join(' ')
		return error('${@MOD}.${@FN} "${cmd}" failed:\n${od_res.output}')
	}
	od_lines := od_res.output.split('\n').map(it.trim_space())
	mut exe_deps := []string{}
	for line in od_lines {
		if !line.contains('NEEDED') {
			continue
		}
		parts := line.split(' ').map(it.trim_space()).filter(it != '')
		if parts.len != 2 {
			continue
		}
		so_name := parts[1]
		if so_name in excludes {
			if verbosity > 1 {
				eprintln('${indents}${so_name} (exclude)')
			}
			continue
		}
		exe_deps << so_name
	}

	mut resolved_deps := map[string]string{}

	ldd_cmd := [
		'ldd',
		// '-r',
		executable,
	]
	ldd_res := os.execute(ldd_cmd.join(' '))
	if ldd_res.exit_code != 0 {
		cmd := ldd_cmd.join(' ')
		return error('${@MOD}.${@FN} "${cmd}" failed:\n${ldd_res.output}')
	}
	ldd_lines := ldd_res.output.split('\n').map(it.trim_space())
	for line in ldd_lines {
		if line.contains('statically linked') {
			continue
		}
		if line.contains('not found') {
			// TODO ?? - give error here? add an option to continue?
			continue
		}
		parts := line.split(' ')
		if parts.len == 0 || parts.len < 3 {
			continue
		}
		// dump(parts)
		so_name := parts[0]
		path := parts[2]

		if so_name in exe_deps {
			if existing := resolved_deps[so_name] {
				if existing != path {
					eprintln('${indents}${so_name} Warning: resolved path is ambiguous "${existing}" vs. "${path}"')
				}
				continue
			}
			resolved_deps[so_name] = path
		}

		// if _ := deps[so_name] {
		//  // Could add to "dependants" here for further info
		//	continue
		//}
	}

	for so_name, path in resolved_deps {
		deps[so_name] = path

		if so_name in skip_resolve {
			if verbosity > 1 {
				eprintln('${indents}${so_name} (skip resolve)')
			}
			continue
		}

		conf := ResolveDependenciesConfig{
			...config
			exe:    path
			indent: indent + 1
		}
		resolve_dependencies_recursively(mut deps, conf)!
	}
}

pub fn resolve_dependencies(config ResolveDependenciesConfig) !map[string]string {
	mut deps := map[string]string{}
	if config.verbosity > 0 {
		eprintln('Resolving dependencies for executable "${config.exe}"...')
	}
	resolve_dependencies_recursively(mut deps, config)!
	return deps
}
