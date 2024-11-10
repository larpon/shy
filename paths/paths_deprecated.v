// Copyright(C) 2023 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license file distributed with this software package
module paths

// data returns a `string` with the path to `shy`'s' data directory.
// NOTE: the returned path may not exist on disk. Use `ensure/1` to ensure it exists.
@[deprecated: 'use paths.shy(.data) instead']
@[deprecated_after: '2025-11-09']
pub fn data() string {
	return shy(.data)
}

// config returns a `string` with the path to `shy`'s' configuration directory.
// NOTE: the returned path may not exist on disk. Use `ensure/1` to ensure it exists.
@[deprecated: 'use paths.shy(.config) instead']
@[deprecated_after: '2025-11-09']
pub fn config() string {
	return shy(.config)
}

// tmp_work returns a `string` with the path to `shy`'s' temporary work directory.
// NOTE: the returned path may not exist on disk. Use `ensure/1` to ensure it exists.
@[deprecated: 'use paths.shy(.temp) instead']
@[deprecated_after: '2025-11-09']
pub fn tmp_work() string {
	return shy(.temp)
}

// cache returns a `string` with the path to `shy`'s' cache directory.
// NOTE: the returned path may not exist on disk. Use `ensure/1` to ensure it exists.
@[deprecated: 'use paths.shy(.cache) instead']
@[deprecated_after: '2025-11-09']
pub fn cache() string {
	return shy(.cache)
}

// exe_data returns a `string` with the path to the executable's data directory.
// NOTE: the returned path may not exist on disk. Use `ensure/1` to ensure it exists.
@[deprecated: 'use paths.exe(.data) instead']
@[deprecated_after: '2025-11-09']
pub fn exe_data() string {
	return shy(.data)
}

// exe_config returns a `string` with the path to the executable's configuration directory.
// NOTE: the returned path may not exist on disk. Use `ensure/1` to ensure it exists.
@[deprecated: 'use paths.exe(.config) instead']
@[deprecated_after: '2025-11-09']
pub fn exe_config() string {
	return shy(.config)
}

// exe_tmp_work returns a `string` with the path to the executable's temporary work directory.
// NOTE: the returned path may not exist on disk. Use `ensure/1` to ensure it exists.
@[deprecated: 'use paths.exe(.temp) instead']
@[deprecated_after: '2025-11-09']
pub fn exe_tmp_work() string {
	return shy(.temp)
}

// exe_cache returns a `string` with the path to the executable's cache directory.
// NOTE: the returned path may not exist on disk. Use `ensure/1` to ensure it exists.
@[deprecated: 'use paths.exe(.cache) instead']
@[deprecated_after: '2025-11-09']
pub fn exe_cache() string {
	return shy(.cache)
}
