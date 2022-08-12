// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module solid

pub enum MousePositionType {
	global
	window
}

pub struct Mouse {
mut:
	solid &Solid = unsafe { nil }
}
