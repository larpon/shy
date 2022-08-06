// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module solid

import sgp

struct ShapeDrawSystem {
mut:
	solid &Solid
}

fn (mut sds ShapeDrawSystem) init(solid &Solid) {
	sds.solid = solid
}

fn (mut sds ShapeDrawSystem) shutdown() {
}

fn (sds ShapeDrawSystem) scope_open() {
	w, h := sds.solid.backend.get_drawable_size()
	// ratio := f32(w)/f32(h)

	// Begin recording draw commands for a frame buffer of size (width, height).
	sgp.begin(w, h)

	// Set frame buffer drawing region to (0,0,width,height).
	sgp.viewport(0, 0, w, h)
	// Set drawing coordinate space to (left=-ratio, right=ratio, top=1, bottom=-1).
	// sgp.project(-ratio, ratio, 1.0, -1.0)
	// sgp.project(0, 0, w, h)

	sgp.reset_project()
}

fn (sds ShapeDrawSystem) scope_close() {
	// Dispatch all draw commands to Sokol GFX.
	sgp.flush()
	// Finish a draw command queue, clearing it.
	sgp.end()
}
