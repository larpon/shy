// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
import shy.lib as shy
import shy.utils

fn test_oscillate_int() {
	assert utils.oscillate_int(0, 0, 100) == 0
	assert utils.oscillate_int(1, 0, 100) == 1
	assert utils.oscillate_int(100, 0, 100) == 100
	assert utils.oscillate_int(202, 0, 100) == 2
	assert utils.oscillate_int(2001, 0, 100) == 1
	mut osc := utils.oscillate_int(30_598_401, 0, 100)
	assert osc >= 0 && osc <= 100
	osc = utils.oscillate_int(4_345_401, 0, 100)
	assert osc >= 0 && osc <= 100

	for i in 0 .. 1_000_000 {
		osc_v := utils.oscillate_int(i, 0, 100)
		assert osc_v >= 0 && osc_v <= 100
	}
}

fn test_oscillate_f32() {
	assert utils.oscillate_f32(0, 0, 100) == 0
	assert utils.oscillate_f32(1, 0, 100) == 1
	assert utils.oscillate_f32(100, 0, 100) == 100
	// assert utils.oscillate_f32(202,0,100) == 2
	// assert utils.oscillate_f32(2001,0,100) == 1
	mut osc := utils.oscillate_f32(30_598_401, 0, 100)
	assert osc >= 0 && osc <= 100
	osc = utils.oscillate_f32(4_345_401, 0, 100)
	assert osc >= 0 && osc <= 100

	for i in 0 .. 1_000_000 {
		osc_v := utils.oscillate_f32(i, 0, 100)
		assert osc_v >= 0 && osc_v <= 100
	}
}
