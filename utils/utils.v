// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module utils

import math // TODO this can probably be shaved off at the end of development
import mth
import os

pub const (
	stdin_is_a_pipe  = (os.is_atty(0) == 0)
	stdout_is_a_pipe = (os.is_atty(1) == 0)
)

[inline]
pub fn remap<T>(value T, min T, max T, new_min T, new_max T) T {
	return (((value - min) * (new_max - new_min)) / (max - min)) + new_min
}

[inline]
pub fn remap_u8_to_f32(value u8, min u8, max u8, new_min f32, new_max f32) f32 {
	return f32((((value - min) * (new_max - new_min)) / (max - min)) + new_min)
}

[inline]
pub fn remap_f32_to_u8(value f32, min f32, max f32, new_min u8, new_max u8) u8 {
	return u8((((value - min) * (new_max - new_min)) / (max - min)) + new_min)
}

[inline]
pub fn lerp<T>(x T, y T, s T) T {
	return x + s * (y - x)
}

[inline]
pub fn clamp<T>(val T, min T, max T) T {
	return mth.min(mth.max(val, min), max)
}

// loopf loops a continious `value` in the range `from`,`to`
pub fn loop_f32(value f32, from f32, to f32) f32 {
	range := to - from
	offset_value := value - from // value relative to 0
	// + `from` to reset back to start of original range
	return (offset_value - f32((math.floor(offset_value / range) * range))) + from
}

// loop loops a continious `value` in the range `from`,`to`
pub fn loop_int(value int, from int, to int) int {
	range := to - from
	offset_value := value - from // value relative to 0
	// + `from` to reset back to start of original range
	return (offset_value - int((math.floor(offset_value / range) * range))) + from
}

// oscillate e.g. "wave" or "ping-pong" `value` between `min` and `max`
pub fn oscillate_int(value int, min int, max int) int {
	range := max - min
	return min + math.abs(((value + range) % (range * 2)) - range)
}

// oscillatef e.g. "wave" or "ping-pong" `value` between `min` and `max`
pub fn oscillate_f32(value f32, min f32, max f32) f32 {
	range := max - min
	return f32(min + math.abs(math.fmod((value + range), (range * 2)) - range))
}
