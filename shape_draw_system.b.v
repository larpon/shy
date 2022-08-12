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
	// Initialize Sokol GP, adjust the size of command buffers for your own use.
	sgp_desc := sgp.Desc{
		// max_vertices: 1_000_000
		// max_commands: 100_000
	}
	sgp.setup(&sgp_desc)
	if !sgp.is_valid() {
		error_msg := unsafe { cstring_to_vstring(sgp.get_error_message(sgp.get_last_error())) }
		panic('Failed to create Sokol GP context:\n$error_msg')
	}

	sds.solid = solid
}

fn (mut sds ShapeDrawSystem) shutdown() {
	sgp.shutdown()
}
