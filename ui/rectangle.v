// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module ui

import shy.lib as shy

@[heap]
pub struct Rectangle {
	Item
pub mut:
	// extra parts
	stroke shy.Stroke
	radius f32 // rounded corner radius. 0 = none
	color  shy.Color = shy.colors.shy.red
	fills  shy.Fill  = .body | .stroke
}

// draw draws the `Rectangle` and/or any child nodes.
pub fn (mut r Rectangle) draw() {
	vs := r.visual_state()
	er := r.ui.easy.rect(
		x:        vs.x
		y:        vs.y
		width:    vs.width
		height:   vs.height
		rotation: vs.rotation
		scale:    vs.scale
		offset:   vs.offset
		origin:   vs.origin
		// easy rect config
		stroke: r.stroke
		radius: r.radius
		color:  r.color
		fills:  r.fills
	)
	er.draw()
	// Draw rest of tree (children) on top
	r.Item.draw()
}
