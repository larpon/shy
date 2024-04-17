// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
import shy.lib as shy

fn test_rgb_to_hsv_and_back() {
	col_0 := shy.rgb(0, 0, 0)
	col_1 := shy.rgb(255, 255, 255)
	col_2 := shy.rgb_hex(0xbadc6c)

	// assert col_2.to[u32]() == 0xbadc6c  // TODO
	// col_3 := shy.rgb_hex(0xdcae6d) // TODO
	assert col_0.as_hsv().as_rgb() == col_0
	assert col_1.as_hsv().as_rgb() == col_1
	assert col_2.as_hsv().as_rgb() == col_2
	// assert col_3.as_hsv().as_rgb() == col_3
}
