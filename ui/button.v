// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module ui

import shy.lib as shy

// Item is the base type for all UI elements.
// By embedding `Item` in a struct - the struct fulfills
// the `Node` interface required for a type to be an UI item.
// Likewise any new types embedding `Item` thus also fulfill
// the `Node` interface requirements - making them "automagically"
// compliant with the scene graph - and allows for easy, user-land,
// creation of new UI nodes that can be reused across code-bases.
@[heap]
pub struct Button {
	Rectangle
pub mut:
	label string
}

// init initialize this `Button` and it's children.
pub fn (mut b Button) init(ui &UI) ! {
	// assert i != unsafe { nil }
	b.radius = 3
	b.color = ui.theme.colors.button_background

	b.Rectangle.init(ui)!
}

// update is called when the `Button` needs to e.g. update it's layout or position.
pub fn (mut b Button) update() {
	// assert i != unsafe { nil }
	//
	b.Rectangle.update()
}

// draw draws the `Button` and/or any child nodes.
pub fn (mut b Button) draw() {
	// assert b != unsafe { nil }
	// mut mb := unsafe { b }
	b.Rectangle.draw()

	// Draw text
	vs := b.visual_state()

	et := b.ui.easy.text(
		x: vs.x
		y: vs.y
		// width: vs.width
		// height: vs.height
		origin: shy.Anchor.center
		text: b.label
	)
	et.draw()

	for mut child in b.body {
		child.draw()
	}
}

// event delegates `e` `Event` to any child nodes and/or it's own listeners.
pub fn (mut b Button) event(e Event) ?&Node {
	if node := b.Rectangle.event(e) {
		return node
	}
	hit := b.Rectangle.contains_pointer_device()
	b.color = b.ui.theme.colors.button_background
	if hit {
		// vs := b.visual_state()
		b.color = b.ui.theme.colors.button_background.lighter()
	}

	if hit {
		for on_event in b.on_event {
			assert !isnil(on_event)

			if on_event(b, e) {
				// If `on_event` returns true, it means
				// a listener on *this* item has accepted the event
				return b
			}
		}
	}
	return none
}
