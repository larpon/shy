// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module shy

import os

[heap]
pub struct Asset {
pub:
	data voidptr
	ao   AssetOption
	// status AssetStatus
}

[heap]
pub struct Assets {
	ShyStruct
mut:
	ass map[string]&Asset // Uuuh huh huh, hey Beavis... uhuh huh huh
}

[params]
pub struct AssetOption {
	path   string
	async  bool = true
	stream bool
}

pub fn (mut a Assets) load(ao AssetOption) ! {
	if !os.is_file(ao.path) {
		return error(@STRUCT + '.' + @FN + ': "$ao.path" does not exist')
	}
	if ao.async {
	}
}

pub fn (mut a Assets) get(path string) !&Asset {
	if asset := a.ass[path] {
		return asset
	}
	return error(@STRUCT + '.' + @FN + ': "$path" is not available. It can be loaded with ' +
		@STRUCT + '.load(\'$path\')')
}
