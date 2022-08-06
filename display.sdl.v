// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module solid

import sdl

fn display_count() int {
	return sdl.get_num_video_displays()
}
