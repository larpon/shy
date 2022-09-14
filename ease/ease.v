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
	quartic
	quintic
	exponential
	circular
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
	blend_in_fn  EaseBlendFn
	blend_out_fn EaseBlendFn
	custom_fn    CustomEaseFn
}

pub fn (e &Ease) ease(time f64) f64 {
	kind := e.kind
	mode := e.mode
	mut t := time
	if !isnil(e.blend_in_fn) {
		t = e.blend_in_fn(t)
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
		.quartic {
			quartic(t, mode)
		}
		.quintic {
			quintic(t, mode)
		}
		.exponential {
			exponential(t, mode)
		}
		.circular {
			circular(t, mode)
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
			if !isnil(e.custom_fn) {
				e.custom_fn(t, mode)
			} else {
				0
			}
		}
	}
	if !isnil(e.blend_out_fn) {
		t = e.blend_out_fn(t)
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

pub fn bezier_blend(t f64) f64 {
	return t * t * (3.0 - 2.0 * t)
}

pub fn parametric_blend(t f64) f64 {
	sqt := t * t
	return sqt / (2.0 * (sqt - t) + 1.0)
}

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
			t * t
		}
		.out {
			1 - (1 - t) * (1 - t)
		}
		.in_out {
			if t < 0.5 {
				2 * t * t
			} else {
				2.0 * (t - 0.5) * (1.0 - (t - 0.5)) + 0.5
			}
		}
	}
}

pub fn cubic(t f64, mode Mode) f64 {
	return match mode {
		.@in {
			t * t * t
		}
		.out {
			tm := -(1 - t)
			tm * tm * tm + 1
		}
		.in_out {
			if t < 0.5 {
				4 * t * t * t
			} else {
				(t - 1) * (2 * t - 2) * (2 * t - 2) + 1
			}
		}
	}
}

pub fn quartic(t f64, mode Mode) f64 {
	return match mode {
		.@in {
			t * t * t * t
		}
		.out {
			tm := -(1 - t)
			1 - tm * tm * tm * tm
		}
		.in_out {
			if t < 0.5 {
				8 * t * t * t * t
			} else {
				tm := -(1 - t)
				1 - 8 * tm * tm * tm * tm
			}
		}
	}
}

pub fn quintic(t f64, mode Mode) f64 {
	return match mode {
		.@in {
			t * t * t * t * t
		}
		.out {
			tm := -(1 - t)
			1 + tm * tm * tm * tm * tm
		}
		.in_out {
			if t < 0.5 {
				16 * t * t * t * t * t
			} else {
				tm := -(1 - t)
				1 + 16 * tm * tm * tm * tm * tm
			}
		}
	}
}

pub fn sine(t f64, mode Mode) f64 {
	return match mode {
		.@in { 1.0 - math.cos((t * mth.pi) / 2) }
		.out { math.sin((t * mth.pi) / 2) }
		.in_out { -(math.cos(mth.pi * t) - 1) / 2 }
	}
}

pub fn circular(t f64, mode Mode) f64 {
	return match mode {
		.@in {
			-(math.sqrt(1 - t * t) - 1)
		}
		.out {
			mt := t - 1
			math.sqrt(1 - mt * mt)
		}
		.in_out {
			mut mt := t * 2
			if mt < 1 {
				-0.5 * (math.sqrt(1 - mt * mt) - 1)
			} else {
				mt -= 2.0
				0.5 * (math.sqrt(1 - mt * mt) + 1)
			}
		}
	}
}

pub fn exponential(t f64, mode Mode) f64 {
	if t == 0.0 {
		return 0.0
	}
	if t == 1.0 {
		return 1.0
	}

	return match mode {
		.@in {
			math.pow(2, 10 * t - 10)
		}
		.out {
			1 - math.pow(2, -10 * t)
		}
		.in_out {
			if t < 0.5 {
				math.pow(2, 20 * t - 10) / 2
			} else {
				(2 - math.pow(2, -20 * t + 10)) / 2
			}
		}
	}
}

pub fn elastic(t f64, mode Mode) f64 {
	if t == 0.0 {
		return 0.0
	}
	if t == 1.0 {
		return 1.0
	}

	c4 := (2 * mth.pi) / 3

	return match mode {
		.@in {
			-math.pow(2, 10 * t) * math.sin((t * 10 - 10.75) * c4)
		}
		.out {
			math.pow(2, -10 * t) * math.sin((t * 10 - 0.75) * c4) + 1
		}
		.in_out {
			c5 := (2 * mth.pi) / 4.5

			if t < 0.5 {
				-(math.pow(2, 20 * t - 10) * math.sin((20 * t - 11.125) * c5)) / 2
			} else {
				(math.pow(2, -20 * t + 10) * math.sin((20 * t - 11.125) * c5)) / 2 + 1
			}
		}
	}
}

pub fn back(t f64, mode Mode) f64 {
	c1 := 1.70158
	c3 := c1 + 1.0

	return match mode {
		.@in {
			c3 * t * t * t - c1 * t * t
		}
		.out {
			1.0 + c3 * math.pow(t - 1, 3) + c1 * math.pow(t - 1, 2)
		}
		.in_out {
			c2 := c1 * 1.525

			if t < 0.5 {
				(math.pow(2 * t, 2) * ((c2 + 1) * 2 * t - c2)) / 2
			} else {
				(math.pow(2 * t - 2, 2) * ((c2 + 1) * (t * 2 - 2) + c2) + 2) / 2
			}
		}
	}
}

pub fn bounce(t f64, mode Mode) f64 {
	return match mode {
		.@in {
			1 - bounce(1 - t, Mode.out)
		}
		.out {
			n1 := 7.5625
			d1 := 2.75

			if t < (1.0 / d1) {
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
		.in_out {
			if t < 0.5 {
				(1 - bounce(1 - 2 * t, Mode.out)) / 2
			} else {
				(1 + bounce(2 * t - 1, Mode.out)) / 2
			}
		}
	}
}

[inline]
pub fn mix_factor(v f64) f64 {
	return mth.min(mth.max(1 - v * 2 + 0.3, 0.0), 1.0)
}

[inline]
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
