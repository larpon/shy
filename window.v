// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module shy

pub struct Boot {
	ShyApp
}

pub struct WM {
	ShyApp
mut:
	root &Window = shy.null
}
