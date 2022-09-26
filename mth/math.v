module mth

// TODO v module BUG prevents calling this "math"?!, also consider "manmade math"

pub const (
	pi_div_2 = pi / 2
	deg2rad  = f32((pi * 2) / 360)
	rad2deg  = f32(360 / (pi * 2))
)

// min returns the minimum of `a` and `b`
[inline]
pub fn min<T>(a T, b T) T {
	return if a < b { a } else { b }
}

// max returns the maximum of `a` and `b`
[inline]
pub fn max<T>(a T, b T) T {
	return if a > b { a } else { b }
}

// abs returns the absolute value of `a`
[inline]
pub fn abs<T>(a T) T {
	return if a < 0 { -a } else { a }
}
