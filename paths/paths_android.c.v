// Copyright(C) 2023 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license file distributed with this software package
module paths

import os
import sdl // TODO: build variant?

// platform_config_dir returns the path to the user configuration directory (depending on the platform).
// On Android SDL2's SDL_androidGetInternalStoragePath() function will be used.
fn platform_config_dir() string {
	$if !termux {
		path_char_ptr := sdl.android_get_internal_storage_path()
		if isnil(path_char_ptr) {
			error_msg := unsafe { cstring_to_vstring(sdl.get_error()) }
			panic('${@STRUCT}.${@FN}:${@LINE}: failed getting config directory via sdl.android_get_internal_storage_path. SDL says: ${error_msg}')
		}
		path := unsafe { cstring_to_vstring(path_char_ptr) }
		return path
	} $else {
		return os.config_dir() or {
			panic('${@STRUCT}.${@FN}:${@LINE}: cannot find config directory')
		}
	}
	panic('${@STRUCT}.${@FN}:${@LINE}: cannot find config directory')
}

fn platform_data_dir() string {
	return platform_config_dir()
}

fn platform_temp_dir() string {
	return platform_config_dir()
}

fn platform_cache_dir() string {
	return platform_config_dir()
}
