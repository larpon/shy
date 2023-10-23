module mth

import math // TODO
// TODO v module BUG prevents calling this "math"?!, also consider "manmade math"

pub const (
	pi_div_2 = pi / 2
	deg2rad  = f32((pi * 2) / 360)
	rad2deg  = f32(360 / (pi * 2))
)

// min returns the minimum of `a` and `b`.
[inline]
pub fn min[T](a T, b T) T {
	return if a < b { a } else { b }
}

// max returns the maximum of `a` and `b`.
[inline]
pub fn max[T](a T, b T) T {
	return if a > b { a } else { b }
}

// abs returns the absolute value of `a`.
[inline]
pub fn abs[T](a T) T {
	return if a < 0 { -a } else { a }
}

// gcd finds the Greatest Common Divisor between two numbers.
pub fn gcd[T](a T, b T) T {
	return T(if b == 0 {
		a
	} else {
		gcd(b, T(math.mod(f64(a), f64(b))))
	})
}

// reduce reduces a fraction by finding the Greatest Common Divisor and dividing by it.
pub fn reduce_fraction[T](numerator T, denominator T) (T, T) {
	g_c_d := gcd(numerator, denominator)
	return numerator / g_c_d, denominator / g_c_d
}

// eq_approx_f32 returns whether `x` and `y` are approximately equal within `tolerance`.
pub fn eq_approx_f32(x f32, y f32, tolerance f32) bool {
	diff := abs(x - y)
	if diff <= tolerance {
		return true
	}
	if diff < max(abs(x), abs(y)) * tolerance {
		return true
	}
	return false
}

// eq_approx_f64 returns whether `x` and `y` are approximately equal within `tolerance`.
pub fn eq_approx_f64(x f64, y f64, tolerance f64) bool {
	diff := abs(x - y)
	if diff <= tolerance {
		return true
	}
	if diff < max(abs(x), abs(y)) * tolerance {
		return true
	}
	return false
}
