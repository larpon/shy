// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module lib

pub struct WrenVM {
	ShyStruct
}

fn (w WrenVM) on_frame(dt f64) {}

pub fn (mut w WrenVM) init() ! {}

pub fn (mut w WrenVM) shutdown() ! {}
