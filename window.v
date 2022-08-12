// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module solid

pub struct Boot {
	solid &Solid
}

pub struct WM {
mut:
	solid &Solid
	root  &Window = unsafe { nil }
}
