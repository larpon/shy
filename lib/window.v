// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module lib

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

fn (wm &WM) find_window(wid u32) ?&Window {
	return wm.root.find_window(wid)
}
