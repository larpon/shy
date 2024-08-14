// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module export

import os
import shy.vxt
import net.http

fn (opt Options) ensure_appimagetool() !string {
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

fn export_appimage(opt Options) ! {
	if opt.verbosity > 3 {
		eprintln('--- ${@MOD}.${@FN} ---')
		eprintln(opt)
	}
	appimagetool_exe := opt.ensure_appimagetool()!

	// Resolve and sanitize input path
	input := os.real_path(opt.input).trim_string_right(os.path_separator)

	// Build V input app for host platform
	v_app := os.join_path(opt.work_dir, 'v_app')
	if opt.verbosity > 0 {
		eprintln('Building V source as "${v_app}"...')
	}
	mut v_cmd := [
		vxt.vexe(),
	]
	if opt.is_prod {
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
	if opt.verbosity > 1 {
		eprintln('Resolved app name to "${app_name}"')
	}
	// Prepare AppDir directory. We do it manually because the "format",
	// or rather, conventions - are fairly straight forward and appimage-builder is a mess.
	// https://docs.appimage.org/packaging-guide/overview.html#manually-creating-an-appdir
	// https://docs.appimage.org/packaging-guide/manual.html
	//
	app_dir_path := os.join_path(opt.work_dir, '${app_name}.AppDir')
	if os.exists(app_dir_path) {
		os.rmdir_all(app_dir_path)!
	}
	os.mkdir_all(app_dir_path)!

	// Create an AppDir structure, that the appimagetool can work on.
	//
	// NOTE Please keep this list in "growing" order so the longest paths in
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
Categories=Game;'

	// TODO for term apps Terminal=true

	os.write_file(desktop_path, desktop_contents)!

	// TODO desktop-file-validate your.desktop ??

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
		format:       opt.format
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
		if opt.verbosity > 1 {
			eprintln('Copying "${lib_real_path}" to "${app_lib}"')
		}
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
	NOTE kept for debugging purposes
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
		if opt.verbosity > 0 {
			eprintln('Including assets from "${assets_by_side}"')
		}
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
				if opt.verbosity > 1 {
					eprintln('Skipping "${assets_above}" since it\'s already included')
				}
			} else {
				if opt.verbosity > 0 {
					eprintln('Including assets from "${assets_above}"')
				}
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
				if opt.verbosity > 1 {
					eprintln('Skipping "${shy_example_assets}" since it\'s already included')
				}
			} else {
				if opt.verbosity > 0 {
					eprintln('Including assets from "${shy_example_assets}"')
				}
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
			if opt.verbosity > 1 {
				eprintln('Skipping "${assets_in_dir}" since it\'s already included')
			}
		} else {
			if opt.verbosity > 0 {
				eprintln('Including assets from "${assets_in_dir}"')
			}
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
				if opt.verbosity > 1 {
					eprintln('Skipping "${user_asset}" since it\'s already included')
				}
			} else {
				if opt.verbosity > 0 {
					eprintln('Including assets from "${user_asset}"')
				}
				os.cp_all(user_asset, assets_path, false) or {
					return error('${@MOD}.${@FN}: failed to copy "${user_asset}" to "${assets_path}": ${err}')
				}
				included_asset_paths << user_asset_resolved
			}
		} else {
			os.cp(user_asset, assets_path) or {
				eprintln('Skipping invalid or non-existent asset file "${user_asset}"')
			}
		}
	}

	// strip exe
	strip_exe := os.find_abs_path_of_executable('strip') or { '' }
	if os.is_executable(strip_exe) {
		if opt.verbosity > 0 {
			eprintln('Running ${strip_exe} "${app_exe}"...')
		}
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

	// Compress exe
	if opt.compress {
		upx_exe := os.find_abs_path_of_executable('upx') or { '' }
		if os.is_executable(upx_exe) {
			if opt.verbosity > 0 {
				eprintln('Compressing "${app_exe}"...')
			}
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

	if opt.format == .appimage_dir {
		return
	}

	// Write .AppDir to AppImage using `appimagetool`
	output := opt.output
	if opt.verbosity > 0 {
		eprintln('Building AppImage "${output}"...')
	}
	appimagetool_cmd := [
		appimagetool_exe,
		app_dir_path,
		output,
	]
	if opt.verbosity > 2 {
		eprintln('Running "${appimagetool_cmd}"...')
	}
	ait_res := os.execute(appimagetool_cmd.join(' '))
	if ait_res.exit_code != 0 {
		ait_cmd := appimagetool_cmd.join(' ')
		return error('${@MOD}.${@FN}: "${ait_cmd}" failed: ${ait_res.output}')
	}
	os.chmod(output, 0o775)! // make it executable
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
