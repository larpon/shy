// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module export

import os
import flag
import shy.vxt
import shy.paths
import shy.utils
import net.http

pub const appimage_exporter_version = '0.0.1'
pub const appimage_fn_description = 'shy export appimage
exports both plain V applications and shy-based applications to Linux AppImages.
'

pub enum AppImageFormat {
	app_image // .AppImage
	app_dir   // .AppDir
}

pub fn (aif AppImageFormat) ext() string {
	return match aif {
		.app_image {
			'AppImage'
		}
		.app_dir {
			'AppDir'
		}
	}
}

pub struct AppImageOptions {
	ExportOptions
pub:
	work_dir string = os.join_path(paths.shy(.temp), 'export', 'appimage') @[ignore]
	compress bool   @[xdoc: 'Compress executable with `upx` if available']
	strip    bool   @[xdoc: 'Strip executable symbols with `strip` if available']
	format   AppImageFormat = .app_image
}

fn (aio AppImageOptions) help_or_docs() ?Result {
	if aio.show_version {
		return Result{
			output: 'shy export appimage ${appimage_exporter_version}'
		}
	}

	if aio.dump_usage {
		export_doc := flag.to_doc[ExportOptions](
			name:        'shy export appimage'
			version:     '${appimage_exporter_version}'
			description: appimage_fn_description
		) or { return none }

		appimage_doc := flag.to_doc[AppImageOptions](
			options: flag.DocOptions{
				show: .flags | .flag_type | .flag_hint | .footer
			}
		) or { return none }

		return Result{
			output: '${export_doc}\n${appimage_doc}'
		}
	}
	return none
}

pub fn args_to_appimage_options(args []string) !AppImageOptions {
	export_options, unmatched := flag.to_struct[ExportOptions](args, skip: 1)!
	options, no_match := flag.to_struct[AppImageOptions](unmatched)!
	if no_match.len > 0 {
		return error('Unrecognized argument(s): ${no_match}')
	}
	return AppImageOptions{
		...options
		ExportOptions: export_options
	}
}

// resolve_input returns the resolved path/file of the input.
fn (opt AppImageOptions) resolve_input() !string {
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
fn (opt AppImageOptions) resolve_output(input string) !string {
	// Resolve output
	mut output_file := ''
	// input_file_ext := os.file_ext(opt.input).trim_left('.').to_lower()
	output_file_ext := os.file_ext(opt.output).trim_left('.').to_lower()
	// Infer from output
	if output_file_ext in ['appimage', 'appdir'] {
		output_file = opt.output
	} else { // Generate from defaults: [-o <output>] <input>
		default_file_name := input.all_after_last(os.path_separator).replace(' ', '_').to_lower()
		if opt.output != '' {
			ext := os.file_ext(opt.output)
			if ext != '' {
				output_file = opt.output.all_before(ext)
			} else {
				output_file = os.join_path(opt.output.trim_right(os.path_separator), default_file_name)
			}
		} else {
			output_file = default_file_name
		}
		if opt.format == .app_image {
			output_file += '.AppImage'
		} else {
			output_file += '.AppDir'
		}
	}
	return output_file
}

pub fn (opt AppImageOptions) resolve_io() !(string, string, AppImageFormat) {
	input := opt.resolve_input()!
	return input, opt.resolve_output(input)!, opt.format
}

fn (opt AppImageOptions) ensure_appimagetool() !string {
	appimagetool_url := 'https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage'
	mut appimagetool_exe := os.join_path(ensure_cache_dir()!, 'squashfs-root', 'AppRun')
	if !os.exists(appimagetool_exe) {
		appimagetool := os.join_path(ensure_cache_dir()!, 'appimagetool')
		if os.exists(appimagetool) {
			os.rm(appimagetool) or {
				return error('${@MOD}.${@FN}: failed to remove previous appimagetool at "${appimagetool}": ${err}')
			}
		}
		if opt.verbosity > 0 {
			eprintln('Downloading `appimagetool` to "${appimagetool}"...')
		}
		http.download_file(appimagetool_url, appimagetool) or {
			return error('${@MOD}.${@FN}: failed to download "${appimagetool_url}": ${err}')
		}
		os.chmod(appimagetool, 0o775)! // make it executable

		// On some systems like Alpine the squashfs gimick doesn't work... *sigh*
		// ... so we extract the entry point script and use that.
		pwd := os.getwd()
		os.chdir(ensure_cache_dir()!)!
		appimagetool_extract_cmd := [
			appimagetool,
			'--appimage-extract',
		]
		aite_res := os.execute(appimagetool_extract_cmd.join(' '))
		if aite_res.exit_code != 0 {
			aite_cmd := appimagetool_extract_cmd.join(' ')
			return error('${@MOD}.${@FN}: "${aite_cmd}" failed: ${aite_res.output}')
		}
		os.chdir(pwd)!

		appimagetool_exe = os.join_path(ensure_cache_dir()!, 'squashfs-root', 'AppRun')

		// Clean up after download as things are extracted
		if os.exists(appimagetool) {
			os.rm(appimagetool) or {}
		}
	}
	return appimagetool_exe
}

pub fn appimage(opt AppImageOptions) !Result {
	if result := opt.help_or_docs() {
		return result
	}

	if opt.input == '' {
		return error('${@MOD}.${@FN}: no input')
	}

	if os.user_os() != 'linux' {
		return error('${@MOD}.${@FN}: AppImage generation is only supported on Linux')
	}
	appimagetool_exe := opt.ensure_appimagetool()!

	// Resolve and sanitize input and output
	input, output, format := opt.resolve_io()!

	paths.ensure(opt.work_dir)!

	// Build V input app for host platform
	v_app := os.join_path(opt.work_dir, 'v_app')
	opt.verbose(1, 'Building V source(s) as "${v_app}"...')

	mut v_cmd := [
		vxt.vexe(),
	]
	if opt.supported_v_flags.prod {
		v_cmd << '-prod'
	}
	v_cmd << opt.v_flags
	v_cmd << [
		'-o',
		v_app,
		input,
	]
	v_res := os.execute(v_cmd.join(' '))
	if v_res.exit_code != 0 {
		vcmd := v_cmd.join(' ')
		return error('${@MOD}.${@FN}: "${vcmd}" failed: ${v_res.output}')
	}

	// Infer app_name from input
	mut app_name := os.file_name(input)
	if os.is_file(input) {
		app_name = app_name.all_before_last('.')
	}
	if app_name == '' {
		return error('${@MOD}.${@FN}: failed resolving app name from ${input}')
	}
	opt.verbose(2, 'Resolved app name to "${app_name}"')

	// Prepare AppDir directory. We do it manually because the "format",
	// or rather, conventions - are fairly straight forward and appimage-builder is a mess.
	// https://docs.appimage.org/packaging-guide/overview.html#manually-creating-an-appdir
	// https://docs.appimage.org/packaging-guide/manual.html
	//
	app_dir_path := os.join_path(opt.work_dir, '${app_name}.AppDir')
	if os.exists(app_dir_path) {
		os.rmdir_all(app_dir_path) or {}
	}
	paths.ensure(app_dir_path)!

	// Create an AppDir structure, that the appimagetool can work on.
	//
	// NOTE: Please keep this list in "growing" order so the longest paths in
	// each root/sub-dir will come first if looped in reverse order.
	//
	// By *growing* we mean that the longest possible path in a directory path
	// should always come after any dirs above it in the list.
	// This way empty directories can then, easily, be cleaned
	// up afterwards by reversing the list.
	//
	// We use a hardcoded list to avoid accidentially including any user paths
	// added to e.g. LD_LIBRARY_PATH - maybe we should add a flag for switching
	// this safety off.
	sub_dirs := [
		os.join_path('bin'),
		os.join_path('usr'),
		os.join_path('usr', 'bin'),
		os.join_path('usr', 'sbin'),
		os.join_path('usr', 'games'),
		os.join_path('usr', 'share'),
		os.join_path('usr', 'local'),
		os.join_path('usr', 'local', 'lib'),
		os.join_path('usr', 'lib'),
		os.join_path('usr', 'lib', 'perl5'),
		os.join_path('usr', 'lib', 'i386-linux-gnu'),
		os.join_path('usr', 'lib', 'x86_64-linux-gnu'),
		os.join_path('usr', 'lib32'),
		os.join_path('usr', 'lib64'),
		os.join_path('lib'),
		os.join_path('lib', 'i386-linux-gnu'),
		os.join_path('lib', 'x86_64-linux-gnu'),
		os.join_path('lib32'),
		os.join_path('lib64'),
	]
	for sub_dir in sub_dirs {
		os.mkdir_all(os.join_path(app_dir_path, sub_dir))!
	}

	// Write .desktop file entry
	desktop_path := os.join_path(app_dir_path, '${app_name}.desktop')
	desktop_contents := '[Desktop Entry]
Name=${app_name}
Exec=${app_name}
Icon=${app_name}
Type=Application
Categories=Game;' // TODO: for term apps Terminal=true

	os.write_file(desktop_path, desktop_contents)!

	// TODO: desktop-file-validate your.desktop ??

	// Copy icon TODO
	shy_icon := os.join_path(@VMODROOT, 'shy.svg')
	app_icon := os.join_path(app_dir_path, '${app_name}' + os.file_ext(shy_icon))
	os.cp(shy_icon, app_icon) or {
		return error('${@MOD}.${@FN}: failed to copy "${shy_icon}" to "${app_icon}": ${err}')
	}

	// Create AppRun executable script
	//
	// Suggested:
	// https://github.com/AppImage/AppImageKit/blob/master/resources/AppRun
	//
	app_run_path := os.join_path(app_dir_path, 'AppRun')
	app_run_contents :=
		r'#!/bin/sh
SELF=$(readlink -f "$0")
HERE=${SELF%/*}
export PATH="${HERE}/usr/bin/:${HERE}/usr/sbin/:${HERE}/usr/games/:${HERE}/bin/:${HERE}/sbin/${PATH:+:$PATH}"
export LD_LIBRARY_PATH="${HERE}/usr/lib/:${HERE}/usr/local/lib/:${HERE}/usr/lib/i386-linux-gnu/:${HERE}/usr/lib/x86_64-linux-gnu/:${HERE}/usr/lib32/:${HERE}/usr/lib64/:${HERE}/lib/:${HERE}/lib/i386-linux-gnu/:${HERE}/lib/x86_64-linux-gnu/:${HERE}/lib32/:${HERE}/lib64/${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export PYTHONPATH="${HERE}/usr/share/pyshared/${PYTHONPATH:+:$PYTHONPATH}"
export XDG_DATA_DIRS="${HERE}/usr/share/${XDG_DATA_DIRS:+:$XDG_DATA_DIRS}"
export PERLLIB="${HERE}/usr/share/perl5/:${HERE}/usr/lib/perl5/${PERLLIB:+:$PERLLIB}"
export GSETTINGS_SCHEMA_DIR="${HERE}/usr/share/glib-2.0/schemas/${GSETTINGS_SCHEMA_DIR:+:$GSETTINGS_SCHEMA_DIR}"
export QT_PLUGIN_PATH="${HERE}/usr/lib/qt4/plugins/:${HERE}/usr/lib/i386-linux-gnu/qt4/plugins/:${HERE}/usr/lib/x86_64-linux-gnu/qt4/plugins/:${HERE}/usr/lib32/qt4/plugins/:${HERE}/usr/lib64/qt4/plugins/:${HERE}/usr/lib/qt5/plugins/:${HERE}/usr/lib/i386-linux-gnu/qt5/plugins/:${HERE}/usr/lib/x86_64-linux-gnu/qt5/plugins/:${HERE}/usr/lib32/qt5/plugins/:${HERE}/usr/lib64/qt5/plugins/${QT_PLUGIN_PATH:+:$QT_PLUGIN_PATH}"
EXEC=$(grep -e ' +
		"'^Exec=.*'" +
		r' "${HERE}"/*.desktop | head -n 1 | cut -d "=" -f 2 | cut -d " " -f 1)
exec "${EXEC}" "$@"'

	os.write_file(app_run_path, app_run_contents)!
	os.chmod(app_run_path, 0o775)! // make it executable

	// Resolve dependencies
	mut so_excludes := []string{}
	// so_excludes << 'linux-vdso.so.1',
	// so_excludes << 'ld-linux-x86-64.so.2',
	so_excludes << appimage_exclude_list(opt.verbosity)!

	// libSDL2 detects and dlopen() it's dependencies at runtime.
	// Skipping it here avoid pulling in *it's* dependencies from this host computer,
	// resulting in a higher chance of success running the app in the wild.
	mut skip_resolve := [
		'libSDL2-2.0.so.0',
	]

	rd_config := ResolveDependenciesConfig{
		verbosity:    opt.verbosity
		exe:          v_app
		excludes:     so_excludes
		skip_resolve: skip_resolve
	}
	dependencies := resolve_dependencies(rd_config)!
	// dump(dependencies)
	for _, lib_path in dependencies {
		app_lib_dir := os.join_path(app_dir_path, os.dir(lib_path).all_after('/'))
		mut app_lib := os.join_path(app_lib_dir, os.file_name(lib_path))
		mut lib_real_path := lib_path
		// Resolve symlinks. These are *very* common across distros.
		if os.is_link(lib_real_path) {
			lib_real_path = os.real_path(lib_real_path)
		}
		opt.verbose(2, 'Copying "${lib_real_path}" to "${app_lib}"')
		os.cp(lib_real_path, app_lib) or {
			return error('${@MOD}.${@FN}: failed to copy "${lib_real_path}" to "${app_lib}": ${err}')
		}
	}

	// Move v_app to .AppDir
	app_exe := os.join_path(app_dir_path, 'usr', 'bin', app_name)
	os.mv(v_app, app_exe)!

	// Copy assets in place next to the executable in .AppDir/usr/bin/
	// This is not very optimal in terms of Linux conventions and could
	// probably be reconsidered at some point. But it works for now.
	assets_path := os.join_path(app_dir_path, 'usr', 'bin', 'assets')
	os.mkdir_all(assets_path) or {
		return error('${@MOD}.${@FN}: failed to make dir "${assets_path}": ${err}')
	}

	mut included_asset_paths := []string{}

	/*
	NOTE: kept for debugging purposes
	test_asset := os.join_path(assets_path, 'test.txt')
	os.rm(test_asset)
	mut fh := open_file(test_asset, 'w+', 0o755) or { panic(err) }
	fh.write('test')
	fh.close()
	*/

	mut assets_by_side_path := input
	if os.is_file(input) {
		assets_by_side_path = os.dir(input)
	}
	// Look for "assets" dir in same location as input
	assets_by_side := os.join_path(assets_by_side_path, 'assets')
	if os.is_dir(assets_by_side) {
		opt.verbose(1, 'Including assets from "${assets_by_side}"')
		os.cp_all(assets_by_side, assets_path, false) or {
			return error('${@MOD}.${@FN}: failed to copy "${assets_by_side}" to "${assets_path}": ${err}')
		}
		included_asset_paths << os.real_path(assets_by_side)
	}
	// Look for "assets" in dir above input dir.
	// This is mostly an exception for the shared example assets in V examples and shy's own examples.
	// For v/examples
	if os.real_path(assets_by_side_path).contains(os.join_path('v', 'examples')) {
		assets_above := os.real_path(os.join_path(assets_by_side_path, '..', 'assets'))
		if os.is_dir(assets_above) {
			if os.real_path(assets_above) in included_asset_paths {
				opt.verbose(2, 'Skipping "${assets_above}" since it\'s already included')
			} else {
				opt.verbose(1, 'Including assets from "${assets_above}"')
				os.cp_all(assets_above, assets_path, false) or {
					return error('${@MOD}.${@FN}: failed to copy "${assets_above}" to "${assets_path}": ${err}')
				}
				included_asset_paths << assets_above
			}
		}
	}
	// For shy/examples
	if os.real_path(assets_by_side_path).contains(os.join_path('shy', 'examples')) {
		shy_example_assets := assets_by_side_path.all_before(os.join_path('shy', 'examples')) +
			os.join_path('shy', 'assets')
		if os.is_dir(shy_example_assets) {
			if os.real_path(shy_example_assets) in included_asset_paths {
				opt.verbose(2, 'Skipping "${shy_example_assets}" since it\'s already included')
			} else {
				opt.verbose(1, 'Including assets from "${shy_example_assets}"')
				os.cp_all(shy_example_assets, assets_path, false) or {
					return error('${@MOD}.${@FN}: failed to copy (assets in dir) "${shy_example_assets}" to "${assets_path}": ${err}')
				}
				included_asset_paths << os.real_path(shy_example_assets)
			}
		}
	}
	// Look for "assets" dir in current dir
	assets_in_dir := 'assets'
	if os.is_dir(assets_in_dir) {
		assets_in_dir_resolved := os.real_path(os.join_path(os.getwd(), assets_in_dir))
		if assets_in_dir_resolved in included_asset_paths {
			opt.verbose(2, 'Skipping "${assets_in_dir}" since it\'s already included')
		} else {
			opt.verbose(1, 'Including assets from "${assets_in_dir}"')
			os.cp_all(assets_in_dir, assets_path, false) or {
				return error('${@MOD}.${@FN}: failed to copy (assets in dir) "${assets_in_dir}" to "${assets_path}": ${err}')
			}
			included_asset_paths << assets_in_dir_resolved
		}
	}
	// Look in user provided dir(s)
	for user_asset in opt.assets {
		if os.is_dir(user_asset) {
			user_asset_resolved := os.real_path(user_asset)
			if user_asset_resolved in included_asset_paths {
				opt.verbose(2, 'Skipping "${user_asset}" since it\'s already included')
			} else {
				opt.verbose(1, 'Including assets from "${user_asset}"')
				os.cp_all(user_asset, assets_path, false) or {
					return error('${@MOD}.${@FN}: failed to copy "${user_asset}" to "${assets_path}": ${err}')
				}
				included_asset_paths << user_asset_resolved
			}
		} else {
			os.cp(user_asset, assets_path) or {
				utils.shy_notice('Skipping invalid or non-existent asset file "${user_asset}"')
			}
		}
	}

	// strip exe
	if opt.strip {
		strip_exe := os.find_abs_path_of_executable('strip') or { '' }
		if os.is_executable(strip_exe) {
			opt.verbose(1, 'Running ${strip_exe} "${app_exe}"...')
			strip_cmd := [
				'${strip_exe}',
				'"${app_exe}"',
			]
			strip_res := os.execute(strip_cmd.join(' '))
			if strip_res.exit_code != 0 {
				stripcmd := strip_cmd.join(' ')
				return error('${@MOD}.${@FN}: "${stripcmd}" failed: ${strip_res.output}')
			}
		}
	}

	// Compress exe
	if opt.compress {
		upx_exe := os.find_abs_path_of_executable('upx') or { '' }
		if os.is_executable(upx_exe) {
			opt.verbose(1, 'Compressing "${app_exe}"...')
			upx_cmd := [
				'${upx_exe}',
				'-9',
				'"${app_exe}"',
			]
			upx_res := os.execute(upx_cmd.join(' '))
			if upx_res.exit_code != 0 {
				upxcmd := upx_cmd.join(' ')
				return error('${@MOD}.${@FN}: "${upxcmd}" failed: ${upx_res.output}')
			}
		}
	}

	// Clean up empty dirs
	for sub_dir in sub_dirs.reverse() {
		rmdir_path := os.join_path(app_dir_path, sub_dir)
		if os.is_dir(rmdir_path) && os.is_dir_empty(rmdir_path) {
			if opt.verbosity > 2 {
				eprintln('Removing empty dir "${rmdir_path}"')
			}
			os.rmdir(rmdir_path)!
		}
	}

	if opt.verbosity > 1 {
		eprintln('Created .AppDir:')
		os.walk(app_dir_path, fn (path string) {
			eprintln('${path}')
		})
	}

	if format == .app_dir {
		return Result{
			output: 'Successfully generated "${app_dir_path}"'
		}
	}

	// Write .AppDir to AppImage using `appimagetool`
	opt.verbose(1, 'Building AppImage "${output}"...')
	appimagetool_cmd := [
		appimagetool_exe,
		app_dir_path,
		output,
	]
	opt.verbose(3, 'Running "${appimagetool_cmd}"...')
	ait_res := os.execute(appimagetool_cmd.join(' '))
	if ait_res.exit_code != 0 {
		ait_cmd := appimagetool_cmd.join(' ')
		return error('${@MOD}.${@FN}: "${ait_cmd}" failed: ${ait_res.output}')
	}
	os.chmod(output, 0o775)! // make it executable
	return Result{
		output: 'Successfully generated "${output}"'
	}
}

pub fn appimage_exclude_list(verbosity int) ![]string {
	// https://raw.githubusercontent.com/AppImageCommunity/pkg2appimage/master/excludelist
	// Previously at: https://raw.githubusercontent.com/probonopd/AppImages/master/excludelist
	excludes_url := 'https://raw.githubusercontent.com/AppImageCommunity/pkg2appimage/master/excludelist'
	excludes_path := os.join_path(ensure_cache_dir()!, 'excludes')
	if !os.exists(excludes_path) {
		if verbosity > 0 {
			eprintln('Downloading AppImage `excludes` file list to "${excludes_path}"...')
		}
		http.download_file(excludes_url, excludes_path) or {
			return error('${@MOD}.${@FN}: failed to download "${excludes_url}": ${err}')
		}
	}
	return os.read_lines(excludes_path) or { []string{} }.filter(it.trim_space() != ''
		&& !it.trim_space().starts_with('#'))
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
			// TODO: ?? - give error here? add an option to continue?
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
