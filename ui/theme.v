// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module ui

import shy.lib as shy

pub struct Colors {
pub:
	view_background         shy.Color = shy.rgb_hex(0x1b1e20)
	view_text               shy.Color = shy.rgb_hex(0xfcfcfc)
	window_background       shy.Color = shy.rgb_hex(0x2a2e32)
	window_text             shy.Color = shy.rgb_hex(0xfcfcfc)
	button_background       shy.Color = shy.rgb_hex(0x31363b)
	button_text             shy.Color = shy.rgb_hex(0xfcfcfc)
	selection_background    shy.Color = shy.rgb_hex(0x3daee9)
	selection_text          shy.Color = shy.rgb_hex(0xfcfcfc)
	selection_inactive_text shy.Color = shy.rgb_hex(0xa1a9b1)

	inactive_text shy.Color = shy.rgb_hex(0xa1a9b1)
	active_text   shy.Color = shy.rgb_hex(0xfcfcfc)
}

pub struct Theme {
pub:
	colors Colors
}
