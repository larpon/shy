// Copyright(C) 2023 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license file distributed with this software package
module paths

import os

pub const shy_namespace = $d('shy:paths:namespace', 'shy')

const sanitized_exe_name = os.file_name(os.executable()).replace(' ', '_').replace('.exe',
	'').to_lower()

pub enum Kind {
	temp
	data
	config
	cache
}

// ensure creates `path` if it does not already exist.
pub fn ensure(path string) ! {
	if !os.exists(path) {
		os.mkdir_all(path) or {
			return error('${@MOD}.${@FN}: error while making directory "${path}":\n${err}')
		}
	}
}

// shy returns a `string` with the path to `shy`'s `kind` directory.
// NOTE: the returned path may not exist on disk. Use `ensure/1` to ensure it exists.
pub fn shy(kind Kind) string {
	return os.join_path(root(kind), shy_namespace)
}

// exe returns a `string` with the path to the executable's `kind` directory.
// NOTE: the returned path may not exist on disk. Use `ensure/1` to ensure it exists.
pub fn exe(kind Kind) string {
	return os.join_path(root(kind), sanitized_exe_name)
}

// root returns a `string` with the path to a `kind` directory.
// NOTE: the returned path may not exist on disk. Use `ensure/1` to ensure it exists.
pub fn root(kind Kind) string {
	return match kind {
		.temp {
			platform_temp_dir()
		}
		.data {
			platform_data_dir()
		}
		.config {
			platform_config_dir()
		}
		.cache {
			platform_cache_dir()
		}
	}
}
