// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module lib

pub const no_window = u32(0)
const root_window_id = u32(1)

pub struct Boot {
	ShyStruct
}

pub fn (b Boot) init() !&WM {
	b.shy.assert_api_init()
	s := b.shy
	s.log.gdebug('${@STRUCT}.${@FN}', '')
	wm := &WM{
		shy: s
	}
	return wm
}

pub struct WM {
	ShyStruct
mut:
	root   &Window = null
	w_id   u32
	active &Window = null
}

fn (wm &WM) find_window(wid u32) ?&Window {
	if !isnil(wm.root) && wm.root.id == wid {
		return wm.root
	}
	return wm.root.find_window(wid)
}
