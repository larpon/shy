// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module lib

import sdl

pub fn (sys System) performance_counter() u64 {
	return sdl.get_performance_counter()
}

pub fn (sys System) performance_frequency() u64 {
	return sdl.get_performance_frequency()
}
