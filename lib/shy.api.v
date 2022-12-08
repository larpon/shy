// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
//
// This file defines (most of) Shy's public API
module lib

import shy.vec
// TODO BUG see consts below // import shy.mth

pub const (
	deg2rad = f32(0.017453292519943295) // TODO BUG with `-live` mth.deg2rad
	rad2deg = f32(57.29577951308232) // TODO BUG with `-live` mth.rad2deg
)

[inline]
pub fn (s &Shy) ticks() u64 {
	return u64(s.timer.elapsed().milliseconds())
}

[inline]
pub fn (s &Shy) active_window() &Window {
	assert !isnil(s.api)
	return s.api.wm.active_window()
}

[inline]
pub fn (s &Shy) performance_counter() u64 {
	assert !isnil(s.api)
	return s.api.system.performance_counter()
}

[inline]
pub fn (s &Shy) performance_frequency() u64 {
	assert !isnil(s.api)
	return s.api.system.performance_frequency()
}

[inline]
pub fn (s &Shy) wm() &WM {
	assert !isnil(s.api)
	assert !isnil(s.api.wm)
	return s.api.wm
}

[inline]
pub fn (s &Shy) assets() &Assets {
	assert !isnil(s.api)
	assert !isnil(s.api.assets)
	return s.api.assets
}

[inline]
pub fn (s &Shy) gfx() &GFX {
	assert !isnil(s.api)
	assert !isnil(s.api.gfx)
	return s.api.gfx
}

[inline]
pub fn (s &Shy) draw() &Draw {
	assert !isnil(s.api)
	assert !isnil(s.api.draw)
	return s.api.draw
}

[inline]
pub fn (s &Shy) audio() &Audio {
	assert !isnil(s.api)
	assert !isnil(s.api.audio)
	return s.api.audio
}

[inline]
pub fn (s &Shy) scripts() &Scripts {
	assert !isnil(s.api)
	assert !isnil(s.api.scripts)
	return s.api.scripts
}

[inline]
pub fn (s &Shy) app() voidptr {
	assert !isnil(s.app)
	return s.app
}

[inline]
pub fn vec2[T](x T, y T) vec.Vec2[T] {
	return vec.Vec2[T]{
		x: x
		y: y
	}
}

[inline]
pub fn rect(x f32, y f32, w f32, h f32) Rect {
	return Rect{
		x: x
		y: y
		width: w
		height: h
	}
}
