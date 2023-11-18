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

// ticks returns the amount of milliseconds passed since the app was started.
@[inline]
pub fn (s &Shy) ticks() u64 {
	return u64(s.timer.elapsed().milliseconds())
}

// active_window returns a reference to the window currently being rendered.
@[inline]
pub fn (s &Shy) active_window() &Window {
	assert !isnil(s.api)
	win := s.api.wm.active_window()
	assert !isnil(win)
	return win
}

// performance_counter returns the current value of the high resolution counter.
// This function is typically used for profiling.
// Counter values are only meaningful relative to each other.
// Differences between values can be converted to times by using `performance_frequency()`.
// See also: performance_frequency().
@[inline]
pub fn (s &Shy) performance_counter() u64 {
	assert !isnil(s.api)
	return s.api.system.performance_counter()
}

// performance_frequency returns a platform-specific high resolution count per second.
// This function is typically used for profiling.
// Differences between values can be converted to times by using `performance_counter()`.
// See also: performance_counter().
@[inline]
pub fn (s &Shy) performance_frequency() u64 {
	assert !isnil(s.api)
	return s.api.system.performance_frequency()
}

@[inline]
pub fn (s &Shy) wm() &WM {
	assert !isnil(s.api)
	assert !isnil(s.api.wm)
	return s.api.wm
}

@[inline]
pub fn (s &Shy) assets() &Assets {
	assert !isnil(s.api)
	assert !isnil(s.api.assets)
	return s.api.assets
}

@[inline]
pub fn (s &Shy) gfx() &GFX {
	assert !isnil(s.api)
	assert !isnil(s.api.gfx)
	return s.api.gfx
}

@[inline]
pub fn (s &Shy) events() &Events {
	assert !isnil(s.api)
	assert !isnil(s.api.events)
	return s.api.events
}

@[inline]
pub fn (s &Shy) draw() &Draw {
	assert !isnil(s.api)
	assert !isnil(s.api.draw)
	return s.api.draw
}

@[inline]
pub fn (s &Shy) audio() &Audio {
	assert !isnil(s.api)
	assert !isnil(s.api.audio)
	return s.api.audio
}

@[inline]
pub fn (s &Shy) scripts() &Scripts {
	assert !isnil(s.api)
	assert !isnil(s.api.scripts)
	return s.api.scripts
}

@[inline]
pub fn (s &Shy) app[T]() &T {
	assert !isnil(s.app)
	return unsafe { &T(s.app) }
}

@[inline]
pub fn vec2[T](x T, y T) vec.Vec2[T] {
	return vec.Vec2[T]{
		x: x
		y: y
	}
}

@[inline]
pub fn vec3[T](x T, y T, z T) vec.Vec3[T] {
	return vec.Vec3[T]{
		x: x
		y: y
		z: z
	}
}

@[inline]
pub fn vec4[T](x T, y T, z T, w T) vec.Vec4[T] {
	return vec.Vec4[T]{
		x: x
		y: y
		z: z
		w: w
	}
}

@[inline]
pub fn rect(x f32, y f32, w f32, h f32) Rect {
	return Rect{
		x: x
		y: y
		width: w
		height: h
	}
}

@[inline]
pub fn size(w f32, h f32) Size {
	return Size{
		width: w
		height: h
	}
}

@[inline; markused; unsafe]
pub fn shy_free(ptr voidptr) {
	assert !isnil(ptr), 'shy_free tries to free null pointer'
	unsafe { free(ptr) }
	unsafe {
		ptr = nil
	}
}
