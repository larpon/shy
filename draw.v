// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module solid

[flag]
pub enum Fill {
	outline
	solid
}

pub enum Cap {
	butt
	round
	square
}

pub enum Connect {
	miter
	bevel
	round
}
