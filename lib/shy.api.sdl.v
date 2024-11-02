// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module lib

import os
import sdl

// data_dir returns a path to a writable location on the platform.
// @[inline]
// pub fn (s &Shy) data_dir() !string {
// 	// TODO:
// 	return error('${@STRUCT}.${@FN}:${@LINE}: TODO: data dir not implemented yet')
// }

// config_dir returns the path to the user configuration directory (depending on the platform).
// On windows, that is `%AppData%`.
// On macos, that is `~/Library/Application Support`.
// On Android SDL2's SDL_androidGetInternalStoragePath() function will be used.
// On the rest, that is `$XDG_CONFIG_HOME`, or if that is not available, `~/.config`.
// If the path cannot be determined, it returns an error.
// (for example, when $HOME on linux, or %AppData% on windows is not defined)
pub fn (s &Shy) config_dir() !string {
	$if windows {
		app_data := os.getenv('AppData')
		if app_data != '' {
			return app_data
		}
	} $else $if macos || darwin || ios {
		home := os.home_dir()
		if home != '' {
			return home + '/Library/Application Support'
		}
	} $else $if android && !termux {
		path_char_ptr := sdl.android_get_internal_storage_path()
		if isnil(path_char_ptr) {
			error_msg := unsafe { cstring_to_vstring(sdl.get_error()) }
			return error('${@STRUCT}.${@FN}:${@LINE}: failed getting config directory via sdl.android_get_internal_storage_path. SDL2 says: ${error_msg}')
		}
		path := unsafe { cstring_to_vstring(path_char_ptr) }
		return path
	} $else {
		xdg_home := os.getenv('XDG_CONFIG_HOME')
		if xdg_home != '' {
			return xdg_home
		}
		home := os.home_dir()
		if home != '' {
			return home + '/.config'
		}
	}
	return error('${@STRUCT}.${@FN}:${@LINE}: cannot find config directory')
}
