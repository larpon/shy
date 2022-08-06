// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
import solid

fn test_keycode_from_string() {
	assert solid.keycode_from_string('Unknown') == .unknown
	assert solid.keycode_from_string('0') == ._0
	assert solid.keycode_from_string('9') == ._9
	assert solid.keycode_from_string('A') == .a
	assert solid.keycode_from_string('z') == .z
	assert solid.keycode_from_string('Keypad 1') == .kp_1
	assert solid.keycode_from_string('Right Alt') == .ralt
	assert solid.keycode_from_string('Audio Play') == .audioplay
	assert solid.keycode_from_string('Obscure') == .unknown
	assert solid.keycode_from_string('') == .unknown
}

fn test_keycode_name() {
	mut kc := solid.KeyCode{}

	assert solid.keycode_name(kc) == 'unknown'
	kc = .kp_0
	assert solid.keycode_name(kc) == 'keypad 0'
}
