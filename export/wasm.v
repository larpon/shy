// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module export

import os
import flag
import shy.paths
import shy.cli

pub const wasm_exporter_version = '0.0.1'
pub const wasm_fn_description = 'shy export wasm
exports both plain V applications and shy-based applications to HTML5/WASM that can run in a browser.
'

pub enum WasmFormat {
	emscripten
}

pub struct WasmOptions {
	ExportOptions
pub:
	work_dir string     = os.join_path(paths.tmp_work(), 'export', 'wasm') @[ignore]
	format   WasmFormat = .emscripten
	s_flags  []string
}

fn (wo WasmOptions) help_or_docs() ?Result {
	if wo.show_version {
		return Result{
			output: 'shy export wasm ${wasm_exporter_version}'
		}
	}

	if wo.dump_usage {
		export_doc := flag.to_doc[ExportOptions](
			name:        'shy export wasm'
			version:     '${wasm_exporter_version}'
			description: wasm_fn_description
		) or { return none }

		wasm_doc := flag.to_doc[WasmOptions](
			options: flag.DocOptions{
				show: .flags | .flag_type | .flag_hint | .footer
			}
		) or { return none }

		return Result{
			output: '${export_doc}\n${wasm_doc}'
		}
	}
	return none
}

pub fn args_to_wasm_options(arguments []string) !WasmOptions {
	// Parse out all V flags supported (-gc none, -skip-unused, etc.)
	// Flags that could not be parsed are returned as `args` (unmatched) via the the `.relaxed` mode.
	supported_v_flags, args := flag.to_struct[SupportedVFlags](arguments,
		skip:  1
		style: .v
		mode:  .relaxed
	)!

	export_options, unmatched := flag.to_struct[ExportOptions](args)!
	options, no_match := flag.to_struct[WasmOptions](unmatched)!
	if no_match.len > 0 {
		return error('Unrecognized argument(s): ${no_match}')
	}
	return WasmOptions{
		...options
		ExportOptions: ExportOptions{
			...export_options
			supported_v_flags: supported_v_flags
		}
	}
}

pub fn wasm(opt WasmOptions) !Result {
	if result := opt.help_or_docs() {
		return result
	}

	if opt.input == '' {
		return error('${@MOD}.${@FN}: no input')
	}

	// Resolve and sanitize input and output
	input, output, format := opt.resolve_io()!

	paths.ensure(opt.work_dir)!

	match format {
		.emscripten {
			opt.verbose(1, 'Exporting to ${format}')
		}
	}

	// shy_root="$(pwd)"
	// pro="$HOME/Projects/puzzle_vibes"
	// v -skip-unused -gc none -d wasm32_emscripten -os wasm32_emscripten -o /tmp/shyem/vc_src.c $pro
	//
	// emcc -flto -fPIC -fvisibility=hidden --preload-file $shy_root/assets@/ --preload-file $pro/assets@/ -sEXPORTED_FUNCTIONS="['_malloc', '_main']" -sSTACK_SIZE=1mb -sERROR_ON_UNDEFINED_SYMBOLS=0 -sASSERTIONS=1 -sUSE_WEBGL2=1 -sUSE_SDL=2 -sNO_EXIT_RUNTIME=1 -sALLOW_MEMORY_GROWTH=1 -O0 -g -D_DEBUG_ -D_DEBUG -D SOKOL_GLES3 -D SOKOL_NO_ENTRY -D MINIAUDIO_IMPLEMENTATION -D _REENTRANT -I "$shy_root/thirdparty/stb" -I "$shy_root/thirdparty/fontstash" -I "$shy_root/thirdparty/sokol" -I "$shy_root/thirdparty/sokol/util" -I "$shy_root/wraps/miniaudio/c/miniaudio" -I "$shy_root/shy" -Wno-enum-conversion -Wno-unused-value $shy_root/thirdparty/stb/stbi.c /tmp/shyem/vc_src.c -lm -lpthread -ldl -o /tmp/shyem/vc_src.html
	//

	// build_dir := os.join_path(opt.work_dir, 'build')

	v_c_file := os.join_path(opt.work_dir, 'v', 'wasm.c')

	mut v_flags := opt.v_flags.clone()
	v_flags << ['-skip-unused', '-gc none', '-d wasm32_emscripten']
	v_to_c_opt := VCompileOptions{
		verbosity: opt.verbosity
		cache:     opt.cache
		input:     input
		output:    v_c_file
		os:        'wasm32_emscripten'
		v_flags:   v_flags
	}

	v_meta_dump := compile_v_to_c(v_to_c_opt) or {
		return IError(CompileError{
			kind: .v_to_c
			err:  err.msg()
		})
	}

	v_cflags := v_meta_dump.c_flags
	imported_modules := v_meta_dump.imports

	// v_thirdparty_dir := os.join_path(vxt.home(), 'thirdparty')
	//
	// uses_gc := opt.uses_gc()
	//
	//
	// TODO: cache check?
	//
	// TODO: Remove any previous builds??
	v_c_deps := os.join_path(paths.tmp_work(), 'export', 'v', 'cdeps')
	v_c_c_opt := VCCompileOptions{
		verbosity: opt.verbosity
		cache:     opt.cache
		parallel:  opt.parallel
		is_prod:   opt.supported_v_flags.prod
		cc:        'emcc'
		// c_flags:   v_cflags
		work_dir: v_c_deps
		v_meta:   v_meta_dump
	}

	vicd := compile_v_c_dependencies(v_c_c_opt) or {
		return IError(CompileError{
			kind: .c_to_o
			err:  err.msg()
		})
	}
	mut o_files := vicd.o_files.clone()
	mut a_files := vicd.a_files.clone()

	dump(o_files)

	mut cflags := opt.c_flags.clone()
	mut sflags := opt.s_flags.clone()
	mut includes := []string{}
	mut defines := []string{}
	mut ldflags := []string{}

	// Grab any external C flags
	for line in v_cflags {
		if line.contains('.tmp.c') || line.ends_with('.o"') {
			continue
		}
		if line.starts_with('-D') {
			defines << line
		}
		if line.starts_with('-I') {
			if line.contains('/usr/') {
				continue
			}
			includes << line
		}
		if line.starts_with('-l') {
			if line.contains('-lgc') {
				// not used / compiled in
				continue
			}
			if line.contains('-lSDL') {
				// different via -sUSE_SDL=X
				continue
			}
			ldflags << line
		}
	}

	// sflags << '-sEXPORTED_FUNCTIONS="[\'_malloc\', \'_main\']" -sSTACK_SIZE=1mb -sERROR_ON_UNDEFINED_SYMBOLS=0 -sASSERTIONS=1 -sUSE_WEBGL2=1 -sNO_EXIT_RUNTIME=1 -sALLOW_MEMORY_GROWTH=1'
	sflags << ['-sEXPORTED_FUNCTIONS="[\'_malloc\',\'_main\']"', '-sSTACK_SIZE=1mb',
		'-sERROR_ON_UNDEFINED_SYMBOLS=0', '-sASSERTIONS=1', '-sUSE_WEBGL2=1', '-sNO_EXIT_RUNTIME=1',
		'-sALLOW_MEMORY_GROWTH=1']
	// sflags << ['-sWASM=1']
	if 'sdl' in imported_modules {
		sflags << '-sUSE_SDL=2'
	}

	sflags << '--preload-file ${input}/assets@/' // TODO:
	sflags << '--preload-file /home/lmp/Projects/vdev/shy/assets@/' // TODO:

	custom_shell_file := os.join_path(os.home_dir(), '.vmodules', 'shy', 'platforms',
		'wasm', 'emscripten', 'shell_minimal.html')
	if os.is_file(custom_shell_file) {
		sflags << '--shell-file ${custom_shell_file}'
	}

	ldflags << '-ldl' // TODO:
	// for asset in opt.assets {
	// 	sflags << '--preload-file ${asset}@/'
	// }
	// --preload-file $shy_root/assets@/ --preload-file $pro/assets@/
	//
	// -I "$shy_root/shy"
	// -Wno-enum-conversion -Wno-unused-value
	// -lm
	// -lpthread
	// -ldl
	// -o /tmp/shyem/vc_src.html

	// ... still a bit of a mess
	is_debug_build := opt.is_debug_build()
	if opt.supported_v_flags.prod {
		cflags << ['-Os']
	} else {
		cflags << ['-O0']
		if is_debug_build {
			cflags << '-g -D_DEBUG_ -D_DEBUG -gsource-map'
		}
	}
	// -flto
	cflags << ['-fPIC', '-fvisibility=hidden']
	//, '-ffunction-sections', '-fdata-sections', '-ferror-limit=1']

	// cflags << ['-Wall', '-Wextra']

	cflags << ['-Wno-unused-parameter'] // sokol_app.h

	// TODO V compile warnings - here to make the compiler(s) shut up :/
	cflags << ['-Wno-unused-variable', '-Wno-unused-result', '-Wno-unused-function',
		'-Wno-unused-label']
	cflags << ['-Wno-missing-braces', '-Werror=implicit-function-declaration']
	cflags << ['-Wno-enum-conversion', '-Wno-unused-value', '-Wno-pointer-sign',
		'-Wno-incompatible-pointer-types']

	// if uses_gc {
	// 	includes << '-I"' + os.join_path(v_thirdparty_dir, 'libgc', 'include') + '"'
	// }

	opt.verbose(1, 'Compiling C output' + if opt.parallel { ' in parallel' } else { '' })

	// Cross compile v.c to v.o lib files
	o_file := os.join_path('/tmp', output, '${output}.html') // TODO:
	paths.ensure(os.dir(o_file))!
	// Compile .o
	cco := CCompileOptions{
		verbosity: opt.verbosity
		cache:     opt.cache
		parallel:  opt.parallel
		input:     v_c_file
		output:    o_file
		cc:        'emcc'
		c_flags:   [
			cflags.join(' '),
			sflags.join(' '),
			includes.join(' '),
			defines.join(' '),
			o_files.join(' '),
			ldflags.join(' '),
		]
	}

	// jobs << job_util.ShellJob{
	// 	cmd: build_cmd
	// }

	c_cmd := cco.cmd()
	opt.verbose(3, 'Running `${c_cmd.join(' ')}`...')
	v_dump_res := cli.run_or_error(c_cmd) or {
		return IError(CompileError{
			kind: .c_to_o
			err:  err.msg()
		})
	}

	opt.verbose(4, v_dump_res)

	// job_util.run_jobs(jobs, opt.parallel, opt.verbosity) or {
	// 	return IError(CompileError{
	// 		kind: .c_to_o
	// 		err:  err.msg()
	// 	})
	// }

	return Result{
		output: ''
	}
}

// resolve_input returns the resolved path/file of the input.
fn (opt WasmOptions) resolve_input() !string {
	mut input := opt.input.trim_right(os.path_separator)
	// If no specific output file is given, we use the input file as a base
	if input == '' {
		return error('${@MOD}.${@FN}: no input given')
	}
	if input in ['.', '..'] || os.is_dir(input) {
		input = os.real_path(input)
	}
	return input
}

// resolve_output returns output according to what `input` contains.
fn (opt WasmOptions) resolve_output(input string) !string {
	// Resolve output
	mut output_file := ''
	// Generate from defaults: [-o <output>] <input>
	default_file_name := input.all_after_last(os.path_separator).replace(' ', '_').to_lower()
	if opt.output != '' {
		output_file = os.join_path(opt.output.trim_right(os.path_separator), default_file_name)
	} else {
		output_file = default_file_name
	}
	return output_file
}

pub fn (opt WasmOptions) resolve_io() !(string, string, WasmFormat) {
	input := opt.resolve_input()!
	return input, opt.resolve_output(input)!, opt.format
}
