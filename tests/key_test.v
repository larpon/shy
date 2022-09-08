// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
import shy.shy

fn test_keycode_from_string() {
	assert shy.keycode_from_string('Unknown') == .unknown
	assert shy.keycode_from_string('0') == ._0
	assert shy.keycode_from_string('9') == ._9
	assert shy.keycode_from_string('A') == .a
	assert shy.keycode_from_string('z') == .z
	assert shy.keycode_from_string('Keypad 1') == .kp_1
	assert shy.keycode_from_string('Right Alt') == .ralt
	assert shy.keycode_from_string('Audio Play') == .audioplay
	assert shy.keycode_from_string('Obscure') == .unknown
	assert shy.keycode_from_string('') == .unknown
}

fn test_keycode_name() {
	mut kc := shy.KeyCode{}

	assert shy.keycode_name(kc) == 'unknown'
	kc = .kp_0
	assert shy.keycode_name(kc) == 'keypad 0'
}
