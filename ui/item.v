// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module ui

import shy.lib as shy
import shy.vec

// Item is the base type for all UI elements.
// By embedding `Item` in a struct - the struct fulfills
// the `Node` interface required for a type to be an UI item.
// Likewise any new types embedding `Item` thus also fulfill
// the `Node` interface requirements - making them "automagically"
// compliant with the scene graph - and allows for easy, user-land,
// creation of new UI nodes that can be reused across code-bases.
@[heap]
pub struct Item {
	shy.Rect
pub:
	id u64 = 1
mut:
	ui &UI = unsafe { nil }
	// NOTE The `unsafe { nil }` assignment once resulted in several V bugs: https://github.com/vlang/v/issues/16882
	// ... which was quickly fixed but one of them couldn't be made as an MRE (minimal reproducible example) - so it's
	// a target of regression: https://github.com/vlang/v/commit/2119a24 <- this commit has the fix.
	parent   &Node = unsafe { nil }
	on_event []OnEventFn
	// nice to have state
	hovered_by_pointer_device bool
pub mut:
	body []&Node
	// Transformations
	rotation f32
	scale    f32 = 1.0
	offset   vec.Vec2[f32]
	origin   shy.Origin
}

// init initialize this `Item` and it's children.
pub fn (mut i Item) init(ui &UI) ! {
	// TODO V BUG #20220 (https://github.com/vlang/v/issues/20220)
	// TODO V BUG #20229 (https://github.com/vlang/v/issues/20229)
	// assert i != unsafe { nil }
	i.ui = ui
	for mut child in i.body {
		child.init(ui)!
	}
	i.update()
}

// update is called when the `Item` needs to e.g. update it's layout.
pub fn (mut i Item) update() {
	// assert i != unsafe { nil }
	for mut child in i.body {
		child.update()
	}
}

/*
// parent returns this `Item`'s parent.
pub fn (i &Item) parent() &Node {
	//assert i != unsafe { nil }
	// BUG: returning ?&Node is not possible currently: if isnil(i.parent) { return none }
	return i.parent
}
*/

// reparent sets this `Item`'s `parent` to `new_parent`.
pub fn (mut i Item) reparent(new_parent &Node) {
	//	assert i != unsafe { nil }
	// assert new_parent != unsafe { nil }
	unsafe {
		i.parent = new_parent
	}
}

// draw draws the `Item` and/or any child nodes.
pub fn (mut i Item) draw() {
	// println(ptr_str(i.ui))
	// Items are invisible, they have a size only
	for mut child in i.body {
		child.draw()
	}
}

// visual_state returns this `Item`'s `VisualState`.
@[inline]
pub fn (i &Item) visual_state() VisualState {
	// assert i != unsafe { nil }
	p := i.parent //()
	if !isnil(p) && p.id != 0 {
		// TODO switch to matricies and actually do the needed transformation math here
		p_vs := p.visual_state()

		// scale := p_vs.scale * i.scale
		return VisualState{
			x:        p_vs.x + i.Rect.x
			y:        p_vs.y + i.Rect.y
			width:    i.Rect.width
			height:   i.Rect.height
			rotation: i.rotation
			scale:    i.scale
			offset:   i.offset
			origin:   i.origin
		}
	}
	// No parent, return as-is
	return VisualState{
		Rect:     i.Rect
		rotation: i.rotation
		scale:    i.scale
		offset:   i.offset
		origin:   i.origin
	}
}

// event delegates `e` `Event` to any child nodes and/or it's own listeners.
pub fn (mut i Item) event(e Event) ?&Node {
	// By sending the event on to the children nodes
	// it's effectively *bubbling* the event upwards in the
	// tree / scene graph
	for mut child in i.body {
		if node := child.event(e) {
			return node
		}
	}

	hit := match e {
		MouseButtonEvent, MouseMotionEvent, MouseWheelEvent {
			vs := i.visual_state()
			vs.Rect.contains(e.x, e.y)
		}
		else {
			false
		}
	}

	i.hovered_by_pointer_device = false
	if hit {
		i.hovered_by_pointer_device = true
		for on_event in i.on_event {
			assert !isnil(on_event)

			if on_event(i, e) {
				// If `on_event` returns true, it means
				// a listener on *this* item has accepted the event
				return i
			}
		}
	}
	return none
}

// contains_pointer_device returns `true` if this item contains the coordinates for
// a pointer device, such as a computer mouse.
pub fn (i &Item) contains_pointer_device() bool {
	return i.hovered_by_pointer_device
}

/*
fn (mut i Item) shutdown() {
	for child in i.body {
		child.shutdown()
		// unsafe { child.free() }
		// unsafe { free(child) }
	}
	i.body.clear()
	//i.body.free()
}*/

@[heap]
pub struct EventArea {
	Item
}

/*
// parent returns the parent Node.
pub fn (ea &EventArea) parent() &Node {
	return ea.Item.parent()
}
*/

/*
// draw draws the `Item` and/or any child nodes.
pub fn (ea &EventArea) draw(ui &UI) {
	ea.Item.draw(ui)
}
*/

/*
// rect returns this `Item`'s rectangle.
pub fn (ea &EventArea) visual_state() VisualState {
	return ea.Item.visual_state()
}
*/

/*
// event sends an `Event` any child nodes and/or it's own listeners.
pub fn (ea &EventArea) event(e Event) ?&Node {
	return ea.Item.event(e)
}
*/

@[heap]
pub struct PointerEventArea {
	EventArea
	on_pointer_event []OnPointerEventFn
}

/*
// parent returns the parent Node.
pub fn (pea &PointerEventArea) parent() &Node {
	return pea.EventArea.parent()
}

// draw draws the `Item` and/or any child nodes.
pub fn (pea &PointerEventArea) draw(ui &UI) {
	pea.EventArea.draw(ui)
}

// rect returns this `Item`'s rectangle.
pub fn (pea &PointerEventArea) visual_state() VisualState {
	return pea.EventArea.visual_state()
}*/

// event sends an `Event` any child nodes and/or it's own listeners.
pub fn (mut pea PointerEventArea) event(e Event) ?&Node {
	if e is MouseButtonEvent || e is MouseMotionEvent || e is MouseWheelEvent {
		ex := match e {
			MouseButtonEvent, MouseMotionEvent, MouseWheelEvent {
				e.x
			}
			else {
				0
			}
		}
		ey := match e {
			MouseButtonEvent, MouseMotionEvent, MouseWheelEvent {
				e.y
			}
			else {
				0
			}
		}
		for on_pointer_event in pea.on_pointer_event {
			assert !isnil(on_pointer_event)
			mut pe := PointerEvent{
				event: e
				x:     ex
				y:     ey
			}

			// BUG: pea pointer address is not the same in userspace callbacks?!
			/*
			eprintln('${@STRUCT}.${@FN} ea: ${ptr_str(pea.EventArea)}')
			eprintln('${@STRUCT}.${@FN} ea.this: ${ptr_str(pea.EventArea.this)}')
			eprintln('${@STRUCT}.${@FN} pea: ${ptr_str(pea)}')
			eprintln('${@STRUCT}.${@FN} id: ${pea.id}')
			eprintln('${@STRUCT}.${@FN} this: ${ptr_str(pea.this)}')

			//unsafe { pea.this = pea }
			//if on_pointer_event(pea.EventArea, pe) {
			mut copy := &PointerEventArea{...pea}
			unsafe { copy.this = copy }
			eprintln('${@STRUCT}.${@FN} copy ea: ${ptr_str(copy.EventArea)}')
			eprintln('${@STRUCT}.${@FN} copy ea.this: ${ptr_str(copy.EventArea.this)}')
			eprintln('${@STRUCT}.${@FN} copy pea: ${ptr_str(copy)}')
			eprintln('${@STRUCT}.${@FN} copy id: ${copy.id}')
			eprintln('${@STRUCT}.${@FN} copy this: ${ptr_str(copy.this)}')
			*/

			if on_pointer_event(pea, pe) {
				// If `on_pointer_event` returns true, it means
				// a listener on *this* item has accepted the event
				return pea
			}
		}
	}
	return pea.EventArea.event(e)
}

@[heap]
pub struct TextArea {
	Item
pub mut:
	// extra parts
	text  string
	color shy.Color = shy.colors.shy.white
}
