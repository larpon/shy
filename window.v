// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module solid

pub struct Window {
	ref voidptr // &sdl.Window
pub:
	id u32
}
