// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
import shy.lib as shy

fn test_size() {
	assert shy.Size{1.5, 1.6}.cast_via[int]() == shy.Size{1, 1}
	assert shy.Size{1, 1}.half() == shy.Size{0.5, 0.5}
	assert shy.Size{1, 1}.mul_scalar(0.5) == shy.Size{0.5, 0.5}
}
