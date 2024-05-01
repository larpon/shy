module mth

union FloatInt {
mut:
	x f32
	i int
}

// inv_sqrt is the infamous fast square root function ported from the Quake source code.
// This V implementation is done by @JalonSolov from this discussion:
// https://github.com/vlang/v/discussions/9159
fn inv_sqrt(x f32) f32 {
	unsafe {
		mut y := FloatInt{
			x: x
		}
		xhalf := 0.5 * y.x
		y.i = 0x5f3759df - (y.i >> 1)
		y.x = y.x * (1.5 - xhalf * y.x * y.x)
		return y.x
	}
}
