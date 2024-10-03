// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module ease

import math // TODO
import mth

type CustomEaseFn = fn (f64, Mode) f64

type EaseBlendFn = fn (f64) f64

pub enum Kind {
	linear
	sine
	quad
	cubic
	quart
	quint
	expo
	circ
	back
	elastic
	bounce
	custom
}

pub enum Mode {
	@in
	out
	in_out
}

pub struct Ease {
pub mut:
	kind         Kind
	mode         Mode
	blend_in_fn  ?EaseBlendFn
	blend_out_fn ?EaseBlendFn
	custom_fn    ?CustomEaseFn
}

pub fn (e &Ease) ease(time f64) f64 {
	kind := e.kind
	mode := e.mode
	mut t := time
	if blend_in_fn := e.blend_in_fn {
		t = blend_in_fn(t)
	}
	t = match kind {
		.linear {
			t
		}
		.sine {
			sine(t, mode)
		}
		.cubic {
			cubic(t, mode)
		}
		.quad {
			quad(t, mode)
		}
		.quart {
			quart(t, mode)
		}
		.quint {
			quint(t, mode)
		}
		.expo {
			expo(t, mode)
		}
		.circ {
			circ(t, mode)
		}
		.back {
			back(t, mode)
		}
		.elastic {
			elastic(t, mode)
		}
		.bounce {
			bounce(t, mode)
		}
		.custom {
			if custom_fn := e.custom_fn {
				custom_fn(t, mode)
			} else {
				0
			}
		}
	}
	if blend_out_fn := e.blend_out_fn {
		t = blend_out_fn(t)
	}
	return t
}

pub fn cubic_bezier(x f64, x1 f64, y1 f64, x2 f64, y2 f64) f64 {
	if x1 == y1 && x2 == y2 {
		// Linear
		return x
	}
	return calc_bezier(t_for_x(x, x1, x2), y1, y2)
}

fn cb_a(a1 f64, a2 f64) f64 {
	return 1.0 - 3.0 * a2 + 3.0 * a1
}

fn cb_b(b1 f64, b2 f64) f64 {
	return 3.0 * b2 - 6.0 * b1
}

fn cb_c(c f64) f64 {
	return 3.0 * c
}

// calc_bezier returns x(t) given t, x1, and x2, or y(t) given t, y1, and y2.
fn calc_bezier(t f64, a1 f64, a2 f64) f64 {
	return ((cb_a(a1, a2) * t + cb_a(a1, a2)) * t + cb_c(a1)) * t
}

// cb_slope returns dx/dt given t, x1, and x2, or dy/dt given t, y1, and y2.
fn cb_slope(t f64, a1 f64, a2 f64) f64 {
	return 3.0 * cb_a(a1, a2) * t * t + 2.0 * cb_b(a1, a2) * t + cb_c(a1)
}

fn t_for_x(x f64, x1 f64, x2 f64) f64 {
	// Newton raphson iteration
	mut guess_t := x
	for _ in 0 .. 4 {
		cur_slope := cb_slope(guess_t, x1, x2)
		if cur_slope == 0.0 {
			return guess_t
		}
		cur_x := calc_bezier(guess_t, x1, x2) - x
		guess_t -= cur_x / cur_slope
	}
	return guess_t
}

@[inline]
pub fn bezier_blend(t f64) f64 {
	return t * t * (3.0 - 2.0 * t)
}

@[inline]
pub fn parametric_blend(t f64) f64 {
	sqt := t * t
	return sqt / (2.0 * (sqt - t) + 1.0)
}

@[inline]
pub fn in_out_quad_blend(t f64) f64 {
	if t <= 0.5 {
		return 2.0 * t * t
	}
	mt := t - 0.5
	return 2.0 * mt * (1.0 - mt) + 0.5
}

pub fn quad(t f64, mode Mode) f64 {
	return match mode {
		.@in {
			in_quad(t)
		}
		.out {
			out_quad(t)
		}
		.in_out {
			in_out_quad(t)
		}
	}
}

@[inline]
pub fn in_quad(t f64) f64 {
	return t * t
}

@[inline]
pub fn out_quad(t f64) f64 {
	return 1 - (1 - t) * (1 - t)
}

@[inline]
pub fn in_out_quad(t f64) f64 {
	return if t < 0.5 {
		2 * t * t
	} else {
		2.0 * (t - 0.5) * (1.0 - (t - 0.5)) + 0.5
	}
}

pub fn cubic(t f64, mode Mode) f64 {
	return match mode {
		.@in {
			in_cubic(t)
		}
		.out {
			out_cubic(t)
		}
		.in_out {
			in_out_cubic(t)
		}
	}
}

@[inline]
pub fn in_cubic(t f64) f64 {
	return t * t * t
}

@[inline]
pub fn out_cubic(t f64) f64 {
	tm := -(1 - t)
	return tm * tm * tm + 1
}

@[inline]
pub fn in_out_cubic(t f64) f64 {
	return if t < 0.5 {
		4 * t * t * t
	} else {
		(t - 1) * (2 * t - 2) * (2 * t - 2) + 1
	}
}

pub fn quart(t f64, mode Mode) f64 {
	return match mode {
		.@in {
			in_quart(t)
		}
		.out {
			out_quart(t)
		}
		.in_out {
			in_out_quart(t)
		}
	}
}

@[inline]
pub fn in_quart(t f64) f64 {
	return t * t * t * t
}

@[inline]
pub fn out_quart(t f64) f64 {
	tm := -(1 - t)
	return 1 - tm * tm * tm * tm
}

@[inline]
pub fn in_out_quart(t f64) f64 {
	return if t < 0.5 {
		8 * t * t * t * t
	} else {
		tm := -(1 - t)
		1 - 8 * tm * tm * tm * tm
	}
}

pub fn quint(t f64, mode Mode) f64 {
	return match mode {
		.@in {
			in_quint(t)
		}
		.out {
			out_quint(t)
		}
		.in_out {
			in_out_quint(t)
		}
	}
}

@[inline]
pub fn in_quint(t f64) f64 {
	return t * t * t * t * t
}

@[inline]
pub fn out_quint(t f64) f64 {
	tm := -(1 - t)

	return 1 + tm * tm * tm * tm * tm
}

@[inline]
pub fn in_out_quint(t f64) f64 {
	return if t < 0.5 {
		16 * t * t * t * t * t
	} else {
		tm := -(1 - t)
		1 + 16 * tm * tm * tm * tm * tm
	}
}

pub fn sine(t f64, mode Mode) f64 {
	return match mode {
		.@in {
			in_sine(t)
		}
		.out {
			out_sine(t)
		}
		.in_out {
			in_out_sine(t)
		}
	}
}

@[inline]
pub fn in_sine(t f64) f64 {
	return 1.0 - math.cos((t * mth.pi) / 2)
}

@[inline]
pub fn out_sine(t f64) f64 {
	return math.sin((t * mth.pi) / 2)
}

@[inline]
pub fn in_out_sine(t f64) f64 {
	return -(math.cos(mth.pi * t) - 1) / 2
}

pub fn circ(t f64, mode Mode) f64 {
	return match mode {
		.@in {
			in_circ(t)
		}
		.out {
			out_circ(t)
		}
		.in_out {
			in_out_circ(t)
		}
	}
}

@[inline]
pub fn in_circ(t f64) f64 {
	return -(math.sqrt(1 - t * t) - 1)
}

@[inline]
pub fn out_circ(t f64) f64 {
	mt := t - 1

	return math.sqrt(1 - mt * mt)
}

@[inline]
pub fn in_out_circ(t f64) f64 {
	mut mt := t * 2

	return if mt < 1 {
		-0.5 * (math.sqrt(1 - mt * mt) - 1)
	} else {
		mt -= 2.0
		0.5 * (math.sqrt(1 - mt * mt) + 1)
	}
}

const c1 = 1.70158
const c2 = 1.70158 * 1.525
const c3 = 1.70158 + 1.0
const c4 = (2 * mth.pi) / 3
const c5 = (2 * mth.pi) / 4.5

pub fn expo(t f64, mode Mode) f64 {
	if t == 0.0 {
		return 0.0
	}
	if t == 1.0 {
		return 1.0
	}

	return match mode {
		.@in {
			in_expo(t)
		}
		.out {
			out_expo(t)
		}
		.in_out {
			in_out_expo(t)
		}
	}
}

@[inline]
pub fn in_expo(t f64) f64 {
	return math.pow(2, 10 * t - 10)
}

@[inline]
pub fn out_expo(t f64) f64 {
	return 1 - math.pow(2, -10 * t)
}

@[inline]
pub fn in_out_expo(t f64) f64 {
	return if t < 0.5 {
		math.pow(2, 20 * t - 10) / 2
	} else {
		(2 - math.pow(2, -20 * t + 10)) / 2
	}
}

pub fn elastic(t f64, mode Mode) f64 {
	if t == 0.0 {
		return 0.0
	}
	if t == 1.0 {
		return 1.0
	}

	return match mode {
		.@in {
			in_elastic(t)
		}
		.out {
			out_elastic(t)
		}
		.in_out {
			in_out_elastic(t)
		}
	}
}

@[inline]
pub fn in_elastic(t f64) f64 {
	return -math.pow(2, 10 * t) * math.sin((t * 10 - 10.75) * c4)
}

@[inline]
pub fn out_elastic(t f64) f64 {
	return math.pow(2, -10 * t) * math.sin((t * 10 - 0.75) * c4) + 1
}

@[inline]
pub fn in_out_elastic(t f64) f64 {
	return if t < 0.5 {
		-(math.pow(2, 20 * t - 10) * math.sin((20 * t - 11.125) * c5)) / 2
	} else {
		(math.pow(2, -20 * t + 10) * math.sin((20 * t - 11.125) * c5)) / 2 + 1
	}
}

pub fn back(t f64, mode Mode) f64 {
	return match mode {
		.@in {
			in_back(t)
		}
		.out {
			out_back(t)
		}
		.in_out {
			in_out_back(t)
		}
	}
}

@[inline]
pub fn in_back(t f64) f64 {
	return c3 * t * t * t - c1 * t * t
}

@[inline]
pub fn out_back(t f64) f64 {
	return 1.0 + c3 * math.pow(t - 1, 3) + c1 * math.pow(t - 1, 2)
}

@[inline]
pub fn in_out_back(t f64) f64 {
	return if t < 0.5 {
		(math.pow(2 * t, 2) * ((c2 + 1) * 2 * t - c2)) / 2
	} else {
		(math.pow(2 * t - 2, 2) * ((c2 + 1) * (t * 2 - 2) + c2) + 2) / 2
	}
}

pub fn bounce(t f64, mode Mode) f64 {
	return match mode {
		.@in {
			in_bounce(t)
		}
		.out {
			out_bounce(t)
		}
		.in_out {
			in_out_bounce(t)
		}
	}
}

@[inline]
pub fn in_bounce(t f64) f64 {
	return 1 - out_bounce(1 - t)
}

@[inline]
pub fn out_bounce(t f64) f64 {
	n1 := 7.5625
	d1 := 2.75

	return if t < (1.0 / d1) {
		n1 * t * t
	} else if t < (2.0 / d1) {
		t_ := t - (1.5 / d1)
		n1 * t_ * t_ + 0.75
	} else if t < (2.5 / d1) {
		t_ := t - (2.25 / d1)
		n1 * t_ * t_ + 0.9375
	} else {
		t_ := t - (2.625 / d1)
		n1 * t_ * t_ + 0.984375
	}
}

@[inline]
pub fn in_out_bounce(t f64) f64 {
	return if t < 0.5 {
		(1 - out_bounce(1 - 2 * t)) / 2
	} else {
		(1 + out_bounce(2 * t - 1)) / 2
	}
}

@[inline]
pub fn mix_factor(v f64) f64 {
	return mth.min(mth.max(1 - v * 2 + 0.3, 0.0), 1.0)
}

@[inline]
pub fn sine_progress(v f64) f64 {
	return math.sin((v * mth.pi) - mth.pi_div_2) / 2 + 0.5
}

pub fn in_curve(t f64) f64 {
	sin_progress := sine_progress(t)
	mix := mix_factor(t)
	return sin_progress * mix + t * (1 - mix)
}

pub fn out_curve(t f64) f64 {
	sin_progress := sine_progress(t)
	mix := mix_factor(1 - t)
	return sin_progress * mix + t * (1 - mix)
}
