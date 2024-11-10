// Copyright(C) 2023 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license file distributed with this software package
module paths

fn platform_config_dir() string {
	return '/shy/.config' // See *_wasm32_emscripten.c.v file
}

fn platform_data_dir() string {
	return '/shy/.local/share' // See *_wasm32_emscripten.c.v file
}

fn platform_temp_dir() string {
	return '/tmp' // See *_wasm32_emscripten.c.v file
}

fn platform_cache_dir() string {
	return '/shy/.cache' // See *_wasm32_emscripten.c.v file
}
