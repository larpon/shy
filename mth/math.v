module mth

// TODO v module BUG prevents calling this math, also consider "manmade math"

pub const (
	pi      = 3.14159265358979323846264338327950288419716939937510582097494459
	deg2rad = f32((pi * 2) / 360)
	rad2deg = f32(360 / (pi * 2))
)

[inline]
pub fn abs<U>(x U) U {
	if x > 0 {
		return x
	}
	return -x
}
