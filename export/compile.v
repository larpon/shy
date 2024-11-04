// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module export

import os
import shy.paths
import shy.cli
import shy.utils
import shy.vxt

pub enum CompileType {
	v_to_c
	c_to_o
	other
}

pub struct CompileError {
	Error
pub:
	kind CompileType
	err  string
}

fn (err CompileError) msg() string {
	enum_to_text := match err.kind {
		.v_to_c {
			'.v to .c'
		}
		.c_to_o {
			'.c to .o'
		}
		.other {
			'.other'
		}
	}
	return 'failed to compile ${enum_to_text}:\n${err.err}'
}

pub struct VCompileOptions {
pub:
	verbosity int // level of verbosity
	cache     bool = true
	parallel  bool = true
	input     string @[required]
	output    string
	is_prod   bool
	cc        string
	os        string
	v_flags   []string // flags to pass to the v compiler
	c_flags   []string // flags to pass to the C compiler(s)
}

// verbose prints `msg` to STDOUT if `AppImageOptions.verbosity` level is >= `verbosity_level`.
pub fn (vco VCompileOptions) verbose(verbosity_level int, msg string) {
	if vco.verbosity >= verbosity_level {
		println(msg)
	}
}

// has_v_d_flag returns true if `d_flag` (-d <ident>) can be found among the passed v flags.
pub fn (opt VCompileOptions) has_v_d_flag(d_flag string) bool {
	for v_flag in opt.v_flags {
		if v_flag.contains('-d ${d_flag}') {
			return true
		}
	}
	return false
}

// is_debug_build returns true if either `-cg` or `-g` flags is found among the passed v flags.
pub fn (opt VCompileOptions) is_debug_build() bool {
	return '-cg' in opt.v_flags || '-g' in opt.v_flags
}

pub fn (opt VCompileOptions) cmd() []string {
	vexe := vxt.vexe()

	mut v_cmd := [
		vexe,
	]
	if !opt.uses_gc() {
		v_cmd << '-gc none'
	}
	if opt.cc != '' {
		v_cmd << '-cc ${opt.cc}'
	}
	if opt.os != '' {
		v_cmd << '-os ${opt.os}'
	}
	if opt.is_prod {
		v_cmd << '-prod'
	}
	if !opt.cache {
		v_cmd << '-nocache'
	}
	v_cmd << opt.v_flags
	if opt.c_flags.len > 0 {
		v_cmd << "-cflags '${opt.c_flags.join(' ')}'"
	}

	if opt.output != '' {
		v_cmd << '-o ${opt.output}'
	}

	v_cmd << opt.input
	return v_cmd
}

// uses_gc returns true if a `-gc` flag is found among the passed v flags.
pub fn (opt VCompileOptions) uses_gc() bool {
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

pub struct VDumpOptions {
	VCompileOptions
pub:
	work_dir string = os.join_path(paths.tmp_work(), 'export', 'v', 'dump') // temporary work directory
}

pub struct VMetaInfo {
pub:
	imports []string
	c_flags []string
}

// v_dump_meta returns the information dumped by
// -dump-modules and -dump-c-flags.
pub fn v_dump_meta(opt VDumpOptions) !VMetaInfo {
	paths.ensure(opt.work_dir)!

	// Dump modules and C flags to files
	v_cflags_file := os.join_path(opt.work_dir, 'v.cflags')
	os.rm(v_cflags_file) or {}
	v_dump_modules_file := os.join_path(opt.work_dir, 'v.modules')
	os.rm(v_dump_modules_file) or {}

	mut v_flags := opt.v_flags.clone()
	v_flags << [
		'-dump-modules "${v_dump_modules_file}"',
		'-dump-c-flags "${v_cflags_file}"',
	]

	vco := VCompileOptions{
		...opt.VCompileOptions
		output:  ''
		v_flags: v_flags
	}

	v_cmd := vco.cmd()

	opt.verbose(3, 'Running `${v_cmd.join(' ')}`...')
	v_dump_res := cli.run(v_cmd)
	opt.verbose(4, v_dump_res.output)

	// Read in the dumped cflags
	cflags := os.read_file(v_cflags_file) or {
		flat_cmd := v_cmd.join(' ')
		return error('${@MOD}.${@FN}: failed reading C flags to "${v_cflags_file}". ${err}\nCompile output of `${flat_cmd}`:\n${v_dump_res}')
	}

	// Parse imported modules from dump
	mut imported_modules := os.read_file(v_dump_modules_file) or {
		flat_cmd := v_cmd.join(' ')
		return error('${@MOD}.${@FN}: failed reading module dump file "${v_dump_modules_file}". ${err}\nCompile output of `${flat_cmd}`:\n${v_dump_res}')
	}.split('\n').filter(it != '')
	imported_modules.sort()
	opt.verbose(3, 'Imported modules: ${imported_modules}')
	return VMetaInfo{
		imports: imported_modules
		c_flags: cflags.split('\n')
	}
}

pub struct CCompileOptions {
	verbosity int // level of verbosity
	cache     bool = true
	parallel  bool = true
	input     string @[required]
	output    string // @[required]
	c         string // @[required]
	cc        string @[required]
	c_flags   []string // flags to pass to the C compiler(s)
}

// verbose prints `msg` to STDOUT if `CCompileOptions.verbosity` level is >= `verbosity_level`.
pub fn (cco CCompileOptions) verbose(verbosity_level int, msg string) {
	if cco.verbosity >= verbosity_level {
		println(msg)
	}
}

pub fn (opt CCompileOptions) cmd() []string {
	mut c_cmd := [
		opt.cc,
	]
	if opt.c_flags.len > 0 {
		c_cmd << opt.c_flags
	}
	if opt.c != '' {
		c_cmd << '-c "${opt.c}"'
	}
	c_cmd << opt.input
	if opt.output != '' {
		c_cmd << '-o "${opt.output}"'
	}

	return c_cmd
}

// compile_v_to_c compiles V sources to their compatible C counterpart.
pub fn compile_v_to_c(opt VCompileOptions) ! {
	work_dir := os.dir(opt.output)
	paths.ensure(work_dir)!

	opt.verbose(1, 'Compiling V to C' + if opt.v_flags.len > 0 {
		'. V flags: `${opt.v_flags}`'
	} else {
		''
	})

	// Boehm-Demers-Weiser Garbage Collector (bdwgc / libgc)
	opt.verbose(2, 'Garbage collection is ${opt.uses_gc()}')

	// Compile to X compatible C file
	v_cmd := opt.cmd()

	opt.verbose(3, 'Running "${v_cmd.join(' ')}"...')
	v_cmd_res := cli.run_or_error(v_cmd)!
	opt.verbose(3, v_cmd_res)
}

struct VImportCDeps {
pub:
	o_files []string
	a_files []string
}

pub struct VCCompileOptions {
pub:
	verbosity int // level of verbosity
	cache     bool = true
	parallel  bool = true
	is_prod   bool
	cc        string @[required]
	c_flags   []string // flags to pass to the C compiler(s)
	work_dir  string = os.join_path(paths.tmp_work(), 'export', 'v', 'cdeps') // temporary work directory
	v_meta    VMetaInfo
}

// verbose prints `msg` to STDOUT if `VCCompileOptions.verbosity` level is >= `verbosity_level`.
pub fn (vcco VCCompileOptions) verbose(verbosity_level int, msg string) {
	if vcco.verbosity >= verbosity_level {
		println(msg)
	}
}

// compile_v_c_dependencies compiles the C dependencies in the V code.
pub fn compile_v_c_dependencies(opt VCCompileOptions) !VImportCDeps {
	opt.verbose(1, 'Compiling V import C dependencies (.c to .o)' +
		if opt.parallel { ' in parallel' } else { '' })

	// err_sig := @MOD + '.' + @FN
	v_meta_info := opt.v_meta
	imported_modules := v_meta_info.imports

	// The following detects `#flag /path/to/file.o` entries in V source code that matches a module.
	//
	// Find all "*.o" entries in the C flags dump (obtained via `-dump-c-flags`).
	// Match the (file)name of these .o files with what modules are actually imported
	// (imports are obtained via `-dump-modules`)
	// If they are module .o files - look for the corresponding `.o.description.txt` that V produces
	// as `~/.vmodules/cache/<hex>/<hash>.o.description.txt`.
	// If the file exists read in it's contents to obtain the exact flags passed to the C compiler.
	mut v_module_o_files := map[string][][]string{}
	for line in v_meta_info.c_flags {
		line_trimmed := line.trim('\'"')
		if line_trimmed.contains('.module.') && line_trimmed.ends_with('.o') {
			module_name := line_trimmed.all_after('.module.').all_before_last('.o')
			if module_name in imported_modules {
				description_file := line_trimmed.all_before_last('.o') + '.description.txt'
				if os.is_file(description_file) {
					if description_contents := os.read_file(description_file) {
						desc := description_contents.split(' ').map(it.trim_space()).filter(it != '')
						index_of_at := desc.index('@')
						index_of_o := desc.index('-o')
						index_of_c := desc.index('-c')
						if desc.len <= 3 || index_of_at <= 0 || index_of_o <= 0 || index_of_c <= 0 {
							if opt.verbosity > 2 {
								println('Description file "${description_file}" does not seem to have valid contents for object file generation')
								println('Description file contents:\n---\n"${description_contents}"\n---')
							}
							continue
						}
						v_module_o_files[module_name] << (desc[index_of_at + 2..])
					}
				}
			}
		}
	}

	mut o_files := []string{}
	mut a_files := []string{}

	// uses_gc := opt.uses_gc()
	build_dir := opt.work_dir
	// is_debug_build := opt.is_debug_build()

	mut cflags_common := opt.c_flags.clone()
	// if opt.is_prod {
	// 	cflags_common << ['-Os']
	// } else {
	// 	cflags_common << ['-O0']
	// }
	// cflags_common << ['-fPIC']
	// cflags_common << ['-Wall', '-Wextra']

	// v_thirdparty_dir := os.join_path(vxt.home(), 'thirdparty')

	mut jobs := []utils.ShellJob{}
	mut cflags := cflags_common.clone()
	o_dir := os.join_path(build_dir, 'o')
	paths.ensure(o_dir)!

	c_compiler := opt.cc

	// Support builtin libgc which is enabled by default in V or via explicit passed `-gc` flag.
	// if uses_gc {
	// 	if opt.verbosity > 1 {
	// 		println('Compiling libgc (${arch}) via -gc flag')
	// 	}
	//
	// 	mut defines := []string{}
	// 	if is_debug_build {
	// 		defines << '-DGC_ASSERTIONS'
	// 		defines << '-DGC_ANDROID_LOG'
	// 	}
	// 	if !opt.has_v_d_flag('no_gc_threads') {
	// 		defines << '-DGC_THREADS=1'
	// 	}
	// 	defines << '-DGC_BUILTIN_ATOMIC=1'
	// 	defines << '-D_REENTRANT'
	// 	// NOTE: it's currently a little unclear why this is needed.
	// 	// V UI can crash and with when the gc is built into the exe and started *without* GC_INIT() the error would occur:
	// 	defines << '-DUSE_MMAP' // Will otherwise crash with a message with a path to the lib in GC_unix_mmap_get_mem+528
	//
	// 	o_file := os.join_path(arch_o_dir, 'gc.o')
	// 	build_cmd := [
	// 		compiler,
	// 		cflags.join(' '),
	// 		'-I"' + os.join_path(v_thirdparty_dir, 'libgc', 'include') + '"',
	// 		defines.join(' '),
	// 		'-c "' + os.join_path(v_thirdparty_dir, 'libgc', 'gc.c') + '"',
	// 		'-o "${o_file}"',
	// 	]
	// 	util.verbosity_print_cmd(build_cmd, opt.verbosity)
	// 	o_res := util.run_or_error(build_cmd)!
	// 	if opt.verbosity > 2 {
	// 		eprintln(o_res)
	// 	}
	//
	// 	o_files[arch] << o_file
	//
	// 	jobs << job_utils.ShellJob{
	// 		cmd: build_cmd
	// 	}
	// }

	// Compile all detected `#flag /path/to/xxx.o` V source code entires that matches an imported module.
	// NOTE: currently there's no way in V source to pass flags for specific architectures so these flags need
	// to be added specially here. It should probably be supported as compile options from commandline...
	for module_name, mod_compile_lines in v_module_o_files {
		opt.verbose(2, 'Compiling .o files from module ${module_name}...')
		opt.verbose(3, 'Lines ${mod_compile_lines}')

		for compile_line in mod_compile_lines {
			index_o_arg := compile_line.index('-o') + 1
			mut o_file := ''
			if path := compile_line[index_o_arg] {
				file_name := os.file_name(path).trim_space().trim('\'"')
				o_file = os.join_path(o_dir, '${file_name}')
			}
			mut build_cmd := [
				c_compiler,
				//'--no-entry', // TODO:
				cflags.join(' '),
			]
			for i, entry in compile_line {
				if i == index_o_arg {
					build_cmd << '"${o_file}"'
					continue
				}
				build_cmd << entry
			}

			opt.verbose(2, 'Compiling "${o_file}" from module ${module_name}...')

			// Dafuq vab ??
			// opt.verbose(3, 'Running "${build_cmd.join(' ')}"...')
			// o_res := cli.run_or_error(build_cmd)!
			// opt.verbose(3, o_res)

			o_files << o_file

			jobs << utils.ShellJob{
				message: utils.ShellJobMessage{
					std_err: if opt.verbosity > 2 {
						'Running "${build_cmd.join(' ')}"...'
					} else {
						''
					}
				}
				cmd:     build_cmd
			}
		}
	}

	utils.run_jobs(jobs, opt.parallel, opt.verbosity)!

	return VImportCDeps{
		o_files: o_files
		a_files: a_files
	}
}
