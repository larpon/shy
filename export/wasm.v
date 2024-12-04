// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module export

import os
import flag
import shy.paths
import shy.cli
import shy.vxt

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
	work_dir string     = os.join_path(paths.shy(.temp), 'export', 'wasm') @[ignore]
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

	paths.ensure(output)!
	paths.ensure(opt.work_dir)!

	match format {
		.emscripten {
			opt.verbose(1, 'Exporting to ${format}')
		}
	}

	//
	// emcc -flto -fPIC -fvisibility=hidden \
	//	--preload-file $shy_root/assets@/ --preload-file $pro/assets@/ \
	//	-sEXPORTED_FUNCTIONS="['_malloc', '_main']" -sSTACK_SIZE=1mb \
	//	-sERROR_ON_UNDEFINED_SYMBOLS=0 -sASSERTIONS=1 -sUSE_WEBGL2=1 -sUSE_SDL=2 -sNO_EXIT_RUNTIME=1 -sALLOW_MEMORY_GROWTH=1 \
	//	-O0 -g -D_DEBUG_ -D_DEBUG -D SOKOL_GLES3 -D SOKOL_NO_ENTRY -D MINIAUDIO_IMPLEMENTATION -D _REENTRANT \
	//	-I "$shy_root/thirdparty/stb" -I "$shy_root/thirdparty/fontstash" -I "$shy_root/thirdparty/sokol" -I "$shy_root/thirdparty/sokol/util" \
	//	-I "$shy_root/wraps/miniaudio/c/miniaudio" -I "$shy_root/shy" \
	//	-Wno-enum-conversion -Wno-unused-value $shy_root/thirdparty/stb/stbi.c /tmp/shyem/vc_src.c -lm -lpthread -ldl -o /tmp/shyem/vc_src.html
	//

	// build_dir := os.join_path(opt.work_dir, 'build')

	v_c_file := os.join_path(opt.work_dir, 'v', 'wasm.c')

	mut v_flags := opt.v_flags.clone()
	v_flags << ['-skip-unused', '-gc none']
	v_to_c_opt := VCompileOptions{
		verbosity: opt.verbosity
		cache:     opt.cache
		input:     input
		output:    v_c_file
		os:        'wasm32_emscripten'
		v_flags:   v_flags
	}

	v_dump_opt := VDumpOptions{
		VCompileOptions: VCompileOptions{
			...v_to_c_opt
			cc: 'clang' // TODO: "select" compilers in order
		}
		work_dir:        os.join_path(opt.work_dir, 'v', 'dump')
	}
	opt.verbose(1, 'Dumping V meta info...')
	v_meta_dump := v_dump_meta(v_dump_opt)!

	if v_meta_dump.imports.len == 0 {
		return error('${@MOD}.${@FN}: empty module dump')
	}

	compile_v_to_c(v_to_c_opt) or {
		return IError(CompileError{
			kind: .v_to_c
			err:  err.msg()
		})
	}

	mut cflags := opt.c_flags.clone()
	mut sflags := opt.s_flags.clone()
	mut includes := []string{}
	mut defines := []string{}
	mut ldflags := []string{}

	v_cflags := v_meta_dump.c_flags
	imported_modules := v_meta_dump.imports

	// Grab any external C flags
	for line in v_cflags {
		if line.contains('.tmp.c') || line.ends_with('.o"') {
			continue
		}
		if line.starts_with('-D') {
			defines << line
		} else if line.starts_with('-I') {
			if line.contains('/usr/') {
				continue
			}
			includes << line
		} else if line.starts_with('-l') {
			if line.contains('-lgc') {
				// not used / compiled in
				continue
			}
			if line.contains('-lSDL') && 'sdl' in imported_modules {
				// different via -sUSE_SDL=X
				opt.verbose(2, 'Ignoring "${line}"...')
				continue
			}
			ldflags << line
		} else if line.starts_with('-s') {
			if line.contains('-std=') {
				opt.verbose(2, 'Ignoring "${line}"...')
				continue
			}
			mut crammed := line.replace('-s ', '-s')
			if crammed.contains('-sMODULARIZE') || crammed.contains('-sMODULARIZE ') {
				opt.verbose(2, 'Ignoring -sMODULARIZE...')
				crammed = crammed.replace('-sMODULARIZE', '')
			}
			sflags << crammed
		} else {
			// todo_v_c_flags << line
		}
	}
	sflags = sflags.filter(it != '')

	// cflags = cflags.filter(it.starts_with('-std'))

	// dump(v_cflags)
	// mut filtered_v_cflags := []string{}
	// filtered_v_cflags << includes
	// filtered_v_cflags << defines
	// filtered_v_cflags << ldflags
	// dump(filtered_v_cflags)
	// dump(cflags)
	// dump(sflags)

	mut vcdeps_cflags := []string{}
	// vcdeps_cflags << '--clear-cache' // TODO: nope exits
	if 'sync.threads' in imported_modules {
		vcdeps_cflags << '-pthread' // -sPROXY_TO_PTHREAD=1'
		// sflags << '-sUSE_PTHREADS=1'
		// sflags << '-sPTHREAD_POOL_SIZE=8'
	}

	// dump(v_cflags)
	// v_thirdparty_dir := os.join_path(vxt.home(), 'thirdparty')
	//
	// uses_gc := opt.uses_gc()
	//
	//
	// TODO: cache check?
	//
	// TODO: Remove any previous builds??
	v_c_deps := os.join_path(paths.shy(.temp), 'export', 'v', 'cdeps')
	v_c_c_opt := VCCompileOptions{
		verbosity: opt.verbosity
		cache:     opt.cache
		parallel:  opt.parallel
		is_prod:   opt.supported_v_flags.prod
		cc:        'emcc'
		c_flags:   vcdeps_cflags
		work_dir:  v_c_deps
		v_meta:    v_meta_dump
	}

	vicd := compile_v_c_dependencies(v_c_c_opt) or {
		return IError(CompileError{
			kind: .c_to_o
			err:  err.msg()
		})
	}
	mut o_files := vicd.o_files.clone()
	mut a_files := vicd.a_files.clone()

	// dump(o_files)

	// TODO: emcc: warning: -pthread + ALLOW_MEMORY_GROWTH may run non-wasm code slowly, see https://github.com/WebAssembly/design/issues/1271 [-Wpthreads-mem-growth]
	sflags << ['-sEXPORTED_FUNCTIONS="[\'_malloc\',\'_main\']"', '-sSTACK_SIZE=2mb',
		'-sALLOW_MEMORY_GROWTH=1']
	if 'sdl' in imported_modules {
		sflags << '-sUSE_SDL=2'
	}
	if 'shy.lib' in imported_modules {
		shy_assets := os.join_path(vxt.vmodules()!, 'shy', 'assets@/')
		sflags << '--preload-file ${shy_assets}'
	}
	if 'sync.threads' in imported_modules {
		sflags << '-pthread' // -sPROXY_TO_PTHREAD=1'
		sflags << '-sUSE_PTHREADS=1'
		// sflags << '-sPTHREAD_POOL_SIZE=8'
	}
	// cflags << '-U__STRICT_ANSI__' // nope
	// cflags << '--clear-cache' // nope exits

	// TODO: these from `fetch` module??
	// sflags << '-sPTHREAD_POOL_SIZE_STRICT=2' // nah, did not really work

	input_assets := '${input}/assets'
	if os.is_dir(input_assets) {
		sflags << '--preload-file ${input_assets}@/' // TODO:
	}

	default_shell_file := os.join_path(vxt.vmodules()!, 'shy', 'platforms', 'wasm', 'emscripten',
		'index.html')
	if os.is_file(default_shell_file) {
		sflags << '--shell-file ${default_shell_file}'
	}

	// ldflags << '-ldl' // TODO: decide

	// ... still a bit of a mess
	is_debug_build := opt.is_debug_build()
	if opt.supported_v_flags.prod {
		cflags << ['-Os']
	} else {
		cflags << ['-O0']
		if is_debug_build {
			cflags << '-D_DEBUG_ -D_DEBUG -gsource-map'
		}
	}
	cflags << ['-fPIC', '-fvisibility=hidden']
	//, '-ffunction-sections', '-fdata-sections', '-ferror-limit=1']

	cflags << ['-Wall', '-Wextra']

	cflags << ['-Wno-unused-parameter'] // sokol_app.h

	// TODO: V compile warnings - here to make the compiler(s) shut up :/
	cflags << ['-Wno-unused-variable', '-Wno-unused-result', '-Wno-unused-function',
		'-Wno-unused-label']
	cflags << ['-Wno-missing-braces', '-Werror=implicit-function-declaration']
	cflags << ['-Wno-enum-conversion', '-Wno-unused-value', '-Wno-pointer-sign',
		'-Wno-incompatible-pointer-types']

	// if uses_gc {
	// 	includes << '-I"' + os.join_path(v_thirdparty_dir, 'libgc', 'include') + '"'
	// }

	opt.verbose(1, 'Compiling C output' + if opt.parallel { ' in parallel' } else { '' })

	o_file_name := os.file_name(input)
	o_file := os.join_path(output, '${o_file_name}.html') // TODO: html?
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
		output: o_file
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
	mut output_dir := ''
	// Generate from defaults: [-o <output>] <input>
	default_dir_name := input.all_after_last(os.path_separator).replace(' ', '_').to_lower() +
		'_wasm'
	if opt.output != '' {
		if !os.is_dir(opt.output) {
			return error('${@MOD}.${@FN}: output "${opt.output}" should *exist* and be a directory')
		}
		output_dir = os.join_path(opt.output.trim_right(os.path_separator), '', default_dir_name)
		// dump(output_dir)
	} else {
		output_dir = default_dir_name
	}
	return output_dir
}

pub fn (opt WasmOptions) resolve_io() !(string, string, WasmFormat) {
	input := opt.resolve_input()!
	return input, opt.resolve_output(input)!, opt.format
}
