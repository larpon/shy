// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module utils

import mth
import math
import os

pub const stdin_is_a_pipe = (os.is_atty(0) == 0)
pub const stdout_is_a_pipe = (os.is_atty(1) == 0)

@[inline]
pub fn remap[T](value T, min T, max T, new_min T, new_max T) T {
	// NOTE: This is carefully crafted like this because 2 hours of debugging led to an obscure corner case.
	// I thought it was a "regression" (maybe not) with V's generics (cgen?, cast?, parenthesis?)
	// `return (((value - min) * (new_max - new_min)) / (max - min)) + new_min` <- this version, incl. return T(...)
	// consistently returned "0.0" until the temp var `r` was used... and I could NOT reduce the scenario.
	// It was discovered while rewriting a function to procedurally generate shade colors (HSV -> RGB) for some bushes...
	// The nasty thought is that something using T *elsewhere* can someday do the same in some unrelated context... nightmare.
	// The fix, however, was simply to cast to `f64` because arguments may be inferred as integer although a float was expected.
	return T((((f64(value) - f64(min)) * (f64(new_max) - f64(new_min))) / (f64(max) - f64(min))) +
		f64(new_min))
	// return (((value - min) * (new_max - new_min)) / (max - min)) + new_min
	// The above yields red bushes in small_world with just `v run`...
}

@[inline]
pub fn remap_u8_to_f32(value u8, min u8, max u8, new_min f32, new_max f32) f32 {
	return f32((((value - min) * (new_max - new_min)) / (max - min)) + new_min)
}

@[inline]
pub fn remap_f32_to_u8(value f32, min f32, max f32, new_min u8, new_max u8) u8 {
	return u8((((value - min) * (new_max - new_min)) / (max - min)) + new_min)
}

@[inline]
pub fn lerp[T](x T, y T, s T) T {
	return T(f64(x) + f64(s) * (f64(y) - f64(x)))
}

// exp_decay returns a frame independent exponential decay value between `a` and `b` using `delta_time_seconds`.
// `decay` is supposed to be useful in the range 1.0 to 25.0. From slow to fast.
// The function is a frame rate independent (approximation) of the well-known `lerp` (linear interpolation) function.
// It is ported to V from the pseudo code shown towards the end of the video https://youtu.be/LSNQuFEDOyQ?t=2977
// NOTE: Thanks to Freya Holmér for the function and the work done in this field.
@[inline]
pub fn exp_decay[T](a T, b T, decay f64, delta_time_seconds f64) T {
	return T(f64(b) + (f64(a) - f64(b)) * math.exp(-decay * delta_time_seconds))
}

@[inline]
pub fn clamp[T](val T, min T, max T) T {
	return T(mth.min(mth.max(val, min), max))
}

// loop_f32 loops a continious `value` in the range `from`,`to`.
pub fn loop_f32(value f32, from f32, to f32) f32 {
	range := to - from
	offset_value := value - from // value relative to 0
	// + `from` to reset back to start of original range
	return (offset_value - f32((mth.floor(offset_value / range) * range))) + from
}

// loop_int loops a continious `value` in the range `from`,`to`.
pub fn loop_int(value int, from int, to int) int {
	range := to - from
	offset_value := value - from // value relative to 0
	// + `from` to reset back to start of original range
	return (offset_value - int((mth.floor(offset_value / range) * range))) + from
}

fn osc_mod(num f32, div f32) f32 {
	ratio := num / div
	return div * (ratio - f32(mth.floor(ratio)))
}

// oscillate_int e.g. "wave" or "ping-pong" `value` between `min` and `max`.
pub fn oscillate_int(value int, min int, max int) int {
	rmin := if min < max { min } else { max }
	rmax := if min > max { min } else { max }

	range := rmax - rmin
	cycle_length := 2 * range

	mut state := osc_mod(value - rmin, cycle_length)
	if state > range {
		state = cycle_length - state
	}

	return int(mth.round(state + min))
}

// oscillate_f32 e.g. "wave" or "ping-pong" `value` between `min` and `max`.
pub fn oscillate_f32(value f32, min f32, max f32) f32 {
	rmin := if min < max { min } else { max }
	rmax := if min > max { min } else { max }

	range := rmax - rmin
	cycle_length := 2 * range

	mut state := osc_mod(value - rmin, cycle_length)
	if state > range {
		state = cycle_length - state
	}

	return state + min
}

// manhattan_distance returns the "manhattan" distance between 2 points.
pub fn manhattan_distance[T](ax T, ay T, bx T, by T) T {
	r := T(mth.abs(ax - bx) + mth.abs(ay - by))
	return r
}
