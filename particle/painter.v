// Copyright(C) 2020 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license file distributed with this software package
module particle

pub interface Painter {
	groups []string
	draw(p &Particle, frame_delta f64)
mut:
	init(mut p Particle)
}
