// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
//
// This file defines (most of) Shy's public API
module shy

[inline]
pub fn (s Shy) fps() u32 {
	return s.state.fps_snapshot
}

[inline]
pub fn (s Shy) ticks() u64 {
	return u64(s.timer.elapsed().milliseconds())
}

[inline]
pub fn (s Shy) active_window() &Window {
	return s.api.wm.active_window()
}

[inline]
pub fn (s Shy) performance_counter() u64 {
	return s.api.system.performance_counter()
}

[inline]
pub fn (s Shy) performance_frequency() u64 {
	return s.api.system.performance_frequency()
}

[inline]
pub fn (s Shy) draw() &Draw {
	return s.api.gfx.draw
}
