// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module ui

// import shy.lib as shy

// Item is the base type for all UI elements.
// By embedding `Item` in a struct - the struct fulfills
// the `Node` interface required for a type to be an UI item.
// Likewise any new types embedding `Item` thus also fulfill
// the `Node` interface requirements - making them "automagically"
// compliant with the scene graph - and allows for easy, user-land,
// creation of new UI nodes that can be reused across code-bases.
@[heap]
pub struct Button {
	Rectangle // pub mut:
	//	text Text
}

// draw draws the `Button` and/or any child nodes.
pub fn (b &Button) draw(ui &UI) {
	assert b != unsafe { nil }
	mut mb := unsafe { b }
	mb.Rectangle.color = ui.theme.colors.button_background
	b.Rectangle.draw(ui)
	for child in b.body {
		child.draw(ui)
	}
}
