module mth

// math/const.v

pub const (
	epsilon      = 2.2204460492503130808472633361816E-16
	e            = 2.71828182845904523536028747135266249775724709369995957496696763
	pi           = 3.14159265358979323846264338327950288419716939937510582097494459
	pi_2         = pi / 2.0
	pi_4         = pi / 4.0
	phi          = 1.61803398874989484820458683436563811772030917980576286213544862
	tau          = 6.28318530717958647692528676655900576839433879875021164194988918
	one_over_tau = 1.0 / tau
	one_over_pi  = 1.0 / pi
	tau_over2    = tau / 2.0
	tau_over4    = tau / 4.0
	tau_over8    = tau / 8.0
	sqrt2        = 1.41421356237309504880168872420969807856967187537694807317667974
	sqrt_3       = 1.73205080756887729352744634150587236694280525381038062805580697
	sqrt_5       = 2.23606797749978969640917366873127623544061835961152572427089724
	sqrt_e       = 1.64872127070012814684865078781416357165377610071014801157507931
	sqrt_pi      = 1.77245385090551602729816748334114518279754945612238712821380779
	sqrt_tau     = 2.50662827463100050241576528481104525300698674060993831662992357
	sqrt_phi     = 1.27201964951406896425242246173749149171560804184009624861664038
	ln2          = 0.693147180559945309417232121458176568075500134360255254120680009
	log2_e       = 1.0 / ln2
	ln10         = 2.30258509299404568401799145468436420760110148862877297603332790
	log10_e      = 1.0 / ln10
	two_thirds   = 0.66666666666666666666666666666666666666666666666666666666666667
)

// Floating-point limit values
// max is the largest finite value representable by the type.
// smallest_non_zero is the smallest positive, non-zero value representable by the type.
pub const (
	max_f32               = 3.40282346638528859811704183484516925440e+38 // 2**127 * (2**24 - 1) / 2**23
	smallest_non_zero_f32 = 1.401298464324817070923729583289916131280e-45 // 1 / 2**(127 - 1 + 23)
	max_f64               = 1.797693134862315708145274237317043567981e+308 // 2**1023 * (2**53 - 1) / 2**52
	smallest_non_zero_f64 = 4.940656458412465441765687928682213723651e-324 // 1 / 2**(1023 - 1 + 52)
)

// Integer limit values
pub const (
	max_i8  = 127
	min_i8  = -128
	max_i16 = 32767
	min_i16 = -32768
	max_i32 = 2147483647
	min_i32 = -2147483648
	// -9223372036854775808 is wrong because C compilers parse literal values
	// without sign first, and 9223372036854775808 overflows i64, hence the
	// consecutive subtraction by 1
	min_i64 = i64(-9223372036854775807 - 1)
	max_i64 = i64(9223372036854775807)
	max_u8  = 255
	max_u16 = 65535
	max_u32 = u32(4294967295)
	max_u64 = u64(18446744073709551615)
)

// copied from vlib/math/unsafe.v

// f64_bits returns the IEEE 754 binary representation of f,
// with the sign bit of f and the result in the same bit position,
// and f64_bits(f64_from_bits(x)) == x.
pub fn f64_bits(f f64) u64 {
	p := *unsafe { &u64(&f) }
	return p
}

// f64_from_bits returns the floating-point number corresponding
// to the IEEE 754 binary representation b, with the sign bit of b
// and the result in the same bit position.
// f64_from_bits(f64_bits(x)) == x.
pub fn f64_from_bits(b u64) f64 {
	p := *unsafe { &f64(&b) }
	return p
}

// copied from vlib/math/floor.v

// floor returns the greatest integer value less than or equal to x.
//
// special cases are:
// floor(±0) = ±0
// floor(±inf) = ±inf
// floor(nan) = nan
pub fn floor(x f64) f64 {
	if x == 0 || is_nan(x) || is_inf(x, 0) {
		return x
	}
	if x < 0 {
		mut d, fract := modf(-x)
		if fract != 0.0 {
			d = d + 1
		}
		return -d
	}
	d, _ := modf(x)
	return d
}

// ceil returns the least integer value greater than or equal to x.
//
// special cases are:
// ceil(±0) = ±0
// ceil(±inf) = ±inf
// ceil(nan) = nan
pub fn ceil(x f64) f64 {
	return -floor(-x)
}

// trunc returns the integer value of x.
//
// special cases are:
// trunc(±0) = ±0
// trunc(±inf) = ±inf
// trunc(nan) = nan
pub fn trunc(x f64) f64 {
	if x == 0 || is_nan(x) || is_inf(x, 0) {
		return x
	}
	d, _ := modf(x)
	return d
}

// round returns the nearest integer, rounding half away from zero.
//
// special cases are:
// round(±0) = ±0
// round(±inf) = ±inf
// round(nan) = nan
pub fn round(x f64) f64 {
	if x == 0 || is_nan(x) || is_inf(x, 0) {
		return x
	}
	// Largest integer <= x
	mut y := floor(x) // Fractional part
	mut r := x - y // Round up to nearest.
	if r > 0.5 {
		unsafe {
			goto rndup
		}
	}
	// Round to even
	if r == 0.5 {
		r = y - 2.0 * floor(0.5 * y)
		if r == 1.0 {
			rndup:
			y += 1.0
		}
	}
	// Else round down.
	return y
}

// Returns the rounded float, with sig_digits of precision.
// i.e `assert round_sig(4.3239437319748394,6) == 4.323944`
pub fn round_sig(x f64, sig_digits int) f64 {
	mut ret_str := '$x'

	match sig_digits {
		0 { ret_str = '${x:0.0f}' }
		1 { ret_str = '${x:0.1f}' }
		2 { ret_str = '${x:0.2f}' }
		3 { ret_str = '${x:0.3f}' }
		4 { ret_str = '${x:0.4f}' }
		5 { ret_str = '${x:0.5f}' }
		6 { ret_str = '${x:0.6f}' }
		7 { ret_str = '${x:0.7f}' }
		8 { ret_str = '${x:0.8f}' }
		9 { ret_str = '${x:0.9f}' }
		10 { ret_str = '${x:0.10f}' }
		11 { ret_str = '${x:0.11f}' }
		12 { ret_str = '${x:0.12f}' }
		13 { ret_str = '${x:0.13f}' }
		14 { ret_str = '${x:0.14f}' }
		15 { ret_str = '${x:0.15f}' }
		16 { ret_str = '${x:0.16f}' }
		else { ret_str = '$x' }
	}

	return ret_str.f64()
}

// round_to_even returns the nearest integer, rounding ties to even.
//
// special cases are:
// round_to_even(±0) = ±0
// round_to_even(±inf) = ±inf
// round_to_even(nan) = nan
pub fn round_to_even(x f64) f64 {
	mut bits := f64_bits(x)
	mut e_ := (bits >> mth.shift) & mth.mask
	if e_ >= mth.bias {
		// round abs(x) >= 1.
		// - Large numbers without fractional components, infinity, and nan are unchanged.
		// - Add 0.499.. or 0.5 before truncating depending on whether the truncated
		// number is even or odd (respectively).
		half_minus_ulp := u64(u64(1) << (mth.shift - 1)) - 1
		e_ -= u64(mth.bias)
		bits += (half_minus_ulp + (bits >> (mth.shift - e_)) & 1) >> e_
		bits &= mth.frac_mask >> e_
		bits ^= mth.frac_mask >> e_
	} else if e_ == mth.bias - 1 && bits & mth.frac_mask != 0 {
		// round 0.5 < abs(x) < 1.
		bits = bits & mth.sign_mask | mth.uvone // +-1
	} else {
		// round abs(x) <= 0.5 including denormals.
		bits &= mth.sign_mask // +-0
	}
	return f64_from_bits(bits)
}

// copied from vlib/math/bits.v

const (
	uvnan                   = u64(0x7FF8000000000001)
	uvinf                   = u64(0x7FF0000000000000)
	uvneginf                = u64(0xFFF0000000000000)
	uvone                   = u64(0x3FF0000000000000)
	mask                    = 0x7FF
	shift                   = 64 - 11 - 1
	bias                    = 1023
	normalize_smallest_mask = u64(u64(1) << 52)
	sign_mask               = u64(0x8000000000000000) // (u64(1) << 63)
	frac_mask               = u64((u64(1) << u64(shift)) - u64(1))
)

// inf returns positive infinity if sign >= 0, negative infinity if sign < 0.
pub fn inf(sign int) f64 {
	v := if sign >= 0 { mth.uvinf } else { mth.uvneginf }
	return f64_from_bits(v)
}

// nan returns an IEEE 754 ``not-a-number'' value.
pub fn nan() f64 {
	return f64_from_bits(mth.uvnan)
}

// is_nan reports whether f is an IEEE 754 ``not-a-number'' value.
pub fn is_nan(f f64) bool {
	// IEEE 754 says that only NaNs satisfy f != f.
	// To avoid the floating-point hardware, could use:
	// x := f64_bits(f);
	// return u32(x>>shift)&mask == mask && x != uvinf && x != uvneginf
	return f != f
}

// is_inf reports whether f is an infinity, according to sign.
// If sign > 0, is_inf reports whether f is positive infinity.
// If sign < 0, is_inf reports whether f is negative infinity.
// If sign == 0, is_inf reports whether f is either infinity.
pub fn is_inf(f f64, sign int) bool {
	// Test for infinity by comparing against maximum float.
	// To avoid the floating-point hardware, could use:
	// x := f64_bits(f);
	// return sign >= 0 && x == uvinf || sign <= 0 && x == uvneginf;
	return (sign >= 0 && f > mth.max_f64) || (sign <= 0 && f < -mth.max_f64)
}

pub fn is_finite(f f64) bool {
	return !is_nan(f) && !is_inf(f, 0)
}

// normalize returns a normal number y and exponent exp
// satisfying x == y × 2**exp. It assumes x is finite and non-zero.
pub fn normalize(x f64) (f64, int) {
	smallest_normal := 2.2250738585072014e-308 // 2**-1022
	if abs(x) < smallest_normal {
		return x * mth.normalize_smallest_mask, -52
	}
	return x, 0
}

// copied from vlib/math/modf.v

const (
	modf_maxpowtwo = 4.503599627370496000e+15
)

// modf returns integer and fractional floating-point numbers
// that sum to f. Both values have the same sign as f.
//
// special cases are:
// modf(±inf) = ±inf, nan
// modf(nan) = nan, nan
pub fn modf(f f64) (f64, f64) {
	abs_f := abs(f)
	mut i := 0.0
	if abs_f >= mth.modf_maxpowtwo {
		i = f // it must be an integer
	} else {
		i = abs_f + mth.modf_maxpowtwo // shift fraction off right
		i -= mth.modf_maxpowtwo // shift back without fraction
		for i > abs_f { // above arithmetic might round
			i -= 1.0 // test again just to be sure
		}
		if f < 0.0 {
			i = -i
		}
	}
	return i, f - i // signed fractional part
}
