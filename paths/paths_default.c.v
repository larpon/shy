// Copyright(C) 2023 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license file distributed with this software package
module paths

import os

// platform_config_dir returns the path to the user configuration directory (depending on the platform).
// On windows, that is `%AppData%`.
// On macos, that is `~/Library/Application Support`.
// On Android SDL2's SDL_androidGetInternalStoragePath() function will be used.
// On the rest, that is `$XDG_CONFIG_HOME`, or if that is not available, `~/.config`.
// If the path cannot be determined, it returns an error.
// (for example, when $HOME on linux, or %AppData% on windows is not defined)
fn platform_config_dir() string {
	return os.config_dir() or { panic('${@STRUCT}.${@FN}:${@LINE}: cannot find config directory') }
}

fn platform_data_dir() string {
	return os.data_dir()
}

fn platform_temp_dir() string {
	return os.temp_dir()
}

fn platform_cache_dir() string {
	return os.cache_dir()
}
