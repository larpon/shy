// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module export

import os
import shy.vxt
import net.http

fn tmp_work_dir() string {
	return os.join_path(os.temp_dir(), 'export')
}

fn ensure_cache_dir() !string {
	dir := os.join_path(os.cache_dir(),'shy','export')
	if !os.is_dir(dir) {
		os.mkdir_all(dir) !
	}
	return dir
}

pub enum Variant {
	generic
	steam
}

pub enum Format {
	zip // .zip
	directory // /path/to/output
	appimage_dir // .AppDir
	appimage // .AppImage
}

pub fn (f Format) ext() string {
	return match f {
		.zip{
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
	}
}

pub struct Options {
pub:
	// These fields would make little sense to change during a run
	verbosity int
	work_dir  string = tmp_work_dir()
	//
	run          bool
	parallel     bool = true // Run, what can be run, in parallel
	compress     bool // Run upx if the host has it installed
	cache        bool // defaults to false in os.args/flag parsing phase
	gles_version int  // = android.default_gles_version
pub mut:
	// I/O
	input           string
	output          string
	format          Format
	variant         Variant
	is_prod         bool
	c_flags         []string // flags passed to the C compiler(s)
	v_flags         []string // flags passed to the V compiler
}

// resolve_output returns the path/file and format of the export.
fn (opt &Options) resolve_output() !(string,Format) {
	mut	output := opt.output
	// If no specific output file is given, we use the input file
	if output == '' {
		output = opt.input
	}
	mut format := opt.format
	ext := os.file_ext(output).all_after('.').to_lower()
	// If user has explicitly named the output. E.g.: '/tmp/out.apk'
	if ext != '' {
		format = string_to_export_format(ext)!
		return output, format
	}
	return output+'.'+format.ext(), format
}

pub fn export(opt &Options) ! {
	if vxt.vexe() == '' {
		return error('${@MOD}.${@FN}: No V install could be detected')
	}

	if !os.is_dir(opt.work_dir) {
		os.mkdir_all(opt.work_dir) !
	}

	// Determine output path/file and format.
	output, format := opt.resolve_output()!

	resolved_options := Options{
		...opt
		output: output
		format: format
	}

	if opt.verbosity > 0 {
		eprintln('Exporting "$opt.input" as $format to "$output"...')
	}
	uos := os.user_os()
	match format {
		.zip {

		}
		.directory {

		}
		.appimage, .appimage_dir {
			if uos != 'linux' {
				return error('${@MOD}.${@FN}: AppImage format is only supported on Linux hosts')
			}
			export_appimage(resolved_options)!
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
		else {
			error('${@MOD}.${@FN}: unsupported format "$str"')
		}
	}
}

fn export_appimage(opt Options) ! {
	appimagetool_url := 'https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage'
	appimagetool := os.join_path(ensure_cache_dir()!,'appimagetool')
	if !os.exists(appimagetool) {
		if opt.verbosity > 0 {
			eprintln('Downloading `appimagetool` to "$appimagetool"...')
		}
		http.download_file(appimagetool_url, appimagetool) or {
			return error('${@MOD}.${@FN}: failed to download "$appimagetool_url": $err')
		}
		os.chmod(appimagetool, 0o775) ! // make it executable
	}

	// Build V input app for host platform
	v_app := os.join_path(opt.work_dir,'v_app')
	if opt.verbosity > 0 {
		eprintln('Building app to "$v_app"...')
	}
	v_cmd := [
		vxt.vexe(),
		'-o',
		v_app,
		opt.input,
	]
	res := os.execute(v_cmd.join(' '))
	if res.exit_code != 0 {
		vcmd := v_cmd.join(' ')
		return error('${@MOD}.${@FN}: "$vcmd" failed: $res.output')
	}

	// Prepare AppDir directory
	// https://docs.appimage.org/packaging-guide/overview.html#manually-creating-an-appdir
	// https://docs.appimage.org/packaging-guide/manual.html
	//
	app_name := os.file_name(opt.input).all_before_last('.')
	app_dir_path := os.join_path(opt.work_dir,'{app_name}.AppDir')
	if os.exists(app_dir_path) {
		os.rmdir_all(app_dir_path)!
	}
	os.mkdir_all(app_dir_path)!

	// Create AppDir structure
	// Please keep this list in order so that it can be reversed
	// so the longest paths in each root sub-dir will come first if looped.
	// (empty directories can then be cleaned up afterwards)
	sub_dirs := [
		os.join_path('bin'),
		os.join_path('usr'),
		os.join_path('usr','bin'),
		os.join_path('usr','sbin'),
		os.join_path('usr','games'),
		os.join_path('usr','share'),
		os.join_path('usr','local'),
		os.join_path('usr','local','lib'),
		os.join_path('usr','lib'),
		os.join_path('usr','lib','perl5'),
		os.join_path('usr','lib','i386-linux-gnu'),
		os.join_path('usr','lib','x86_64-linux-gnu'),
		os.join_path('usr','lib32'),
		os.join_path('usr','lib64'),
		os.join_path('lib'),
		os.join_path('lib','i386-linux-gnu'),
		os.join_path('lib','x86_64-linux-gnu'),
		os.join_path('lib32'),
		os.join_path('lib64'),
	]
	for sub_dir in sub_dirs {
		os.mkdir_all(os.join_path(app_dir_path,sub_dir))!
	}

	// Write .desktop file entry
	desktop_path := os.join_path(app_dir_path,'{app_name}.desktop')
	desktop_contents := '[Desktop Entry]
Name={app_name}
Exec={app_name}
Icon={app_name}
Type=Application
Categories=Game;'

	// TODO for term apps Terminal=true

	os.write_file(desktop_path, desktop_contents)!

	// TODO desktop-file-validate your.desktop ??

	// Copy icon TODO
	shy_icon := os.join_path(@VMODROOT,'logo.svg')
	app_icon := os.join_path(app_dir_path,'{app_name}'+os.file_ext(shy_icon))
	os.cp(shy_icon, app_icon) or {
		return error('failed to copy "{shy_icon}" to "{app_icon}": $err')
	}

	// Create AppRun executable script
	//
	// Suggested:
	// https://github.com/AppImage/AppImageKit/blob/master/resources/AppRun
	//
	app_run_path := os.join_path(app_dir_path,'AppRun')
	app_run_contents := r'#!/bin/sh
SELF=$(readlink -f "$0")
HERE=${SELF%/*}
export PATH="${HERE}/usr/bin/:${HERE}/usr/sbin/:${HERE}/usr/games/:${HERE}/bin/:${HERE}/sbin/${PATH:+:$PATH}"
export LD_LIBRARY_PATH="${HERE}/usr/lib/:${HERE}/usr/local/lib/:${HERE}/usr/lib/i386-linux-gnu/:${HERE}/usr/lib/x86_64-linux-gnu/:${HERE}/usr/lib32/:${HERE}/usr/lib64/:${HERE}/lib/:${HERE}/lib/i386-linux-gnu/:${HERE}/lib/x86_64-linux-gnu/:${HERE}/lib32/:${HERE}/lib64/${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export PYTHONPATH="${HERE}/usr/share/pyshared/${PYTHONPATH:+:$PYTHONPATH}"
export XDG_DATA_DIRS="${HERE}/usr/share/${XDG_DATA_DIRS:+:$XDG_DATA_DIRS}"
export PERLLIB="${HERE}/usr/share/perl5/:${HERE}/usr/lib/perl5/${PERLLIB:+:$PERLLIB}"
export GSETTINGS_SCHEMA_DIR="${HERE}/usr/share/glib-2.0/schemas/${GSETTINGS_SCHEMA_DIR:+:$GSETTINGS_SCHEMA_DIR}"
export QT_PLUGIN_PATH="${HERE}/usr/lib/qt4/plugins/:${HERE}/usr/lib/i386-linux-gnu/qt4/plugins/:${HERE}/usr/lib/x86_64-linux-gnu/qt4/plugins/:${HERE}/usr/lib32/qt4/plugins/:${HERE}/usr/lib64/qt4/plugins/:${HERE}/usr/lib/qt5/plugins/:${HERE}/usr/lib/i386-linux-gnu/qt5/plugins/:${HERE}/usr/lib/x86_64-linux-gnu/qt5/plugins/:${HERE}/usr/lib32/qt5/plugins/:${HERE}/usr/lib64/qt5/plugins/${QT_PLUGIN_PATH:+:$QT_PLUGIN_PATH}"
EXEC=$(grep -e '+"'^Exec=.*'"+r' "${HERE}"/*.desktop | head -n 1 | cut -d "=" -f 2 | cut -d " " -f 1)
exec "${EXEC}" "$@"'

	os.write_file(app_run_path, app_run_contents)!
	os.chmod(app_run_path, 0o775) ! // make it executable

	// Resolve dependencies
	//
	mut so_excludes := [
    	//'linux-vdso.so.1',
    	//'ld-linux-x86-64.so.2',
	]string{}
	so_excludes << appimage_exclude_list(opt.verbosity)!

	mut skip_resolve := [
		'libSDL2-2.0.so.0',
	]

	rd_config := ResolveDependenciesConfig{
		verbosity: opt.verbosity
		format: opt.format
		exe: v_app
		excludes: so_excludes
		skip_resolve: skip_resolve
	}
	dependencies := resolve_dependencies(rd_config)!
	dump(dependencies)

	for _, lib_path in dependencies {
		app_lib_dir := os.join_path(app_dir_path,os.dir(lib_path).all_after('/'))
		mut app_lib := os.join_path(app_lib_dir,os.file_name(lib_path))
		mut lib_real_path := lib_path
		if os.is_link(lib_real_path) {
			lib_real_path = os.real_path(lib_real_path)
		}
		if opt.verbosity > 1 {
			eprintln('Copying "{lib_real_path}" to "{app_lib}"')
		}
		os.cp(lib_real_path, app_lib) or {
			return error('failed to copy "{lib_real_path}" to "{app_lib}": $err')
		}
	}

	// Move v_app to .AppDir
	app_exe := os.join_path(app_dir_path,'usr','bin',app_name)
	os.mv(v_app, app_exe)!

	// Compress exe
	if opt.compress {
		if opt.verbosity > 0 {
			eprintln('Compressing "$app_exe"...')
		}
		upx_cmd := [
			'upx',
			'-9',
			app_exe,
		]
		upx_res := os.execute(upx_cmd.join(' '))
		if upx_res.exit_code != 0 {
			upxcmd := upx_cmd.join(' ')
			return error('${@MOD}.${@FN}: "{upxcmd}" failed: $upx_res.output')
		}
	}

	// Clean up empty dirs
	for sub_dir in sub_dirs.reverse() {
		rmdir_path := os.join_path(app_dir_path,sub_dir)
		if os.is_dir(rmdir_path) && os.is_dir_empty(rmdir_path) {
			if opt.verbosity > 2 {
				eprintln('Removing empty dir "{rmdir_path}"')
			}
			os.rmdir(rmdir_path)!
		}
	}

	if opt.verbosity > 1 {
		eprintln('Created .AppDir:')
		os.walk(app_dir_path, fn (path string){
			eprintln('{path}')
		})
	}

	if opt.format == .appimage_dir {
		return
	}

	// Write .AppDir to AppImage using `appimagetool`
	output := opt.output
	if opt.verbosity > 0 {
		eprintln('Building AppImage "{output}"...')
	}
	appimagetool_cmd := [
		appimagetool,
		app_dir_path,
		output,
	]
	ait_res := os.execute(appimagetool_cmd.join(' '))
	if ait_res.exit_code != 0 {
		ait_cmd := appimagetool_cmd.join(' ')
		return error('${@MOD}.${@FN}: "{ait_cmd}" failed: {ait_res.output}')
	}
	os.chmod(output, 0o775) ! // make it executable
}

// pub struct Dependency{
// 	path string
// 	// { 'so':so, 'path':path, 'realpath':realpath, 'dependants':set([executable]), 'type':'lib' }
// }

struct ResolveDependenciesConfig{
	verbosity int
	indent int
	exe string
	excludes []string
	skip_resolve []string
	format Format
}

fn resolve_dependencies_recursively(mut deps map[string]string, config ResolveDependenciesConfig) ! {
	// Resolving shared object (.so) dependencies on Linux is not as straight forward as
	// one could wish for. Using `objdump` alone gives us only the *names* of the
	// shared objects, not the full path. Using only `ldd` *does* result in resolved lib paths BUT
	// they're done recursively and printed in one stream which makes it impossible to know
	// which libs has dependencies on which, on top `ldd` has security issues and problems with cross-compiled
	// binaries. The issues are mostly ignored in our case since we consider the input (v sources) "trusted" and we do not
	// support cross-compiled binaries anyway at this point (Not sure AppImages support it either?!).
	//
	// Digging even further and reading source code of programs like `lddtree` will reveal
	// that it's not straight forward to know what `.so` will be loaded by `ld` upon execution
	// (LD_LIBRARY_PATH etc. mess and misuse).
	//
	// So. For now we've chosen a solution using a mix of both `objdump` and `ldd` - it has pitfalls for sure -
	// but how many and how severe - only time will tell. If we are to do this "correctly" it'll need a lot
	// more development time and special-cases (and native V modules for reading ELF binaries etc.) than what
	// is feasible right now; We really just want to be able to collect a bunch of shared object files that
	// a given V executable rely on in-order for us to collect them and package them up, for example, in an AppImage.
	//
	// The strategy is thus the following:
	// 1. Run `objdump` on the exe/so file (had to choose one; readelf lost: https://stackoverflow.com/questions/8979664/readelf-vs-objdump-why-are-both-needed)
	// this gives us the immediate (1st level) dependencies of the app.
	// 2. Run `ldd` on the same exe/so file to obtain the first encountered resolved path(s) to the 1st level exe/so dependency.
	// 3. Do step 1 and 2 for all dependencies, recursively
	// 4. Cross our fingers and assume that 99.99% of cases will end up having happy users.
	// The remaining user pool will hopefully be tech savy enough to fix/extend things themselves.

	verbosity := config.verbosity
	indent := config.indent
	mut root_indents := '  '.repeat(indent)+' '
	if indent == 0 {
		root_indents = ''
	}
	indents := '  '.repeat(indent+1)+' '
	executable := config.exe
	excludes := config.excludes
	skip_resolve := config.skip_resolve

	if verbosity > 0 {
		base := os.file_name(executable)
		eprintln('{root_indents}{base} (included)')
	}
	objdump_cmd := [
		'objdump'
		'-x'
		executable,
	]
	od_res := os.execute(objdump_cmd.join(' '))
	if od_res.exit_code != 0 {
		cmd := objdump_cmd.join(' ')
		return error('${@MOD}.${@FN} "$cmd" failed:\n$od_res.output')
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
				eprintln('{indents}{so_name} (excluded)')
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
		return error('${@MOD}.${@FN} "$cmd" failed:\n$ldd_res.output')
	}
	ldd_lines := ldd_res.output.split('\n').map(it.trim_space())
	for line in ldd_lines {
		if line.contains('statically linked') {
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
					eprintln('{indents}{so_name} Warning: resolved path is ambiguous "{existing}" vs. "{path}"')
				}
				continue
			}
			resolved_deps[so_name] = path
		}

		//if _ := deps[so_name] {
			// Could add to "dependants" here
		//	continue
		//}

	}

	for so_name, path in resolved_deps {
		deps[so_name] = path

		if so_name in skip_resolve {
			if verbosity > 1 {
				eprintln('{indents}{so_name} (skipped)')
			}
			continue
		}

		conf := ResolveDependenciesConfig{
			...config
			exe: path
			indent: indent+1
		}
		resolve_dependencies_recursively(mut deps, conf)!
	}
}

pub fn resolve_dependencies(config ResolveDependenciesConfig) !map[string]string {
	mut deps := map[string]string{}
	if config.verbosity > 0 {
		eprintln('Resolving {config.format.ext()} dependencies...')
	}
	resolve_dependencies_recursively(mut deps, config)!
	return deps
}

pub fn appimage_exclude_list(verbosity int) ![]string {
	// https://raw.githubusercontent.com/AppImageCommunity/pkg2appimage/master/excludelist
	// Previously at: https://raw.githubusercontent.com/probonopd/AppImages/master/excludelist
	excludes_url := 'https://raw.githubusercontent.com/AppImageCommunity/pkg2appimage/master/excludelist'
	excludes_path := os.join_path(ensure_cache_dir()!,'excludes')
	if !os.exists(excludes_path) {
		if verbosity > 0 {
		 	eprintln('Downloading `excludes` to "$excludes_path"...')
		}
		http.download_file(excludes_url, excludes_path) or {
			return error('${@MOD}.${@FN}: failed to download "$excludes_url": $err')
		}
	}
	return os.read_lines(excludes_path) or {[]string{}}.filter(it.trim_space() != '' && !it.trim_space().starts_with('#'))
}