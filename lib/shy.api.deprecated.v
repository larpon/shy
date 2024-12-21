// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module lib

import paths

// config_dir returns the path to the user configuration directory (depending on the platform).
// On windows, that is `%AppData%`.
// On macos, that is `~/Library/Application Support`.
// On Android SDL2's SDL_androidGetInternalStoragePath() function will be used.
// On the rest, that is `$XDG_CONFIG_HOME`, or if that is not available, `~/.config`.
// If the path cannot be determined, it returns an error.
// (for example, when $HOME on linux, or %AppData% on windows is not defined)
@[deprecated: 'use import shy.paths; paths.root(.config) instead']
@[deprecated_after: '2025-11-09']
pub fn (s &Shy) config_dir() !string {
	return paths.root(.config)
}
