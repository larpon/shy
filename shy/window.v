// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module shy

pub struct Boot {
	ShyStruct
}

pub struct WM {
	ShyStruct
mut:
	root   &Window = null
	w_id   u32
	active &Window = null
}
