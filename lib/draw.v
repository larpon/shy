// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module lib

@[flag]
pub enum Fill {
	stroke
	body
}

pub enum Cap {
	butt
	round
	square
}

pub fn (c Cap) next() Cap {
	return match c {
		.butt {
			.round
		}
		.round {
			.square
		}
		.square {
			.butt
		}
	}
}

pub enum Connect {
	miter
	bevel
	round
}

pub fn (c Connect) next() Connect {
	return match c {
		.miter {
			.bevel
		}
		.bevel {
			.round
		}
		.round {
			.miter
		}
	}
}

pub struct Stroke {
pub:
	width   f32     = 1.0
	connect Connect = .bevel // Beav(el)is and Butt(head) - uuuh - huh huh
	cap     Cap     = .butt
	color   Color   = colors.shy.white
}

pub fn (d &Draw) shape_2d() DrawShape2D {
	mut s := d.shy
	mut d2d := DrawShape2D{
		shy:    s
		factor: d.canvas.factor
	}
	d2d.init() or {
		msg := 'initializing DrawShape2D failed'
		s.log.gcritical('${@STRUCT}.${@FN}', msg)
		panic('${@STRUCT}.${@FN}' + ' ' + msg)
	}
	return d2d
}

pub fn (d &Draw) text() DrawText {
	mut s := d.shy
	mut dt := DrawText{
		shy:    s
		factor: d.canvas.factor
	}
	dt.init() or {
		msg := 'initializing DrawText failed'
		s.log.gcritical('${@STRUCT}.${@FN}', msg)
		panic('${@STRUCT}.${@FN}' + ' ' + msg)
	}
	return dt
}

pub fn (d &Draw) image() DrawImage {
	mut s := d.shy
	mut di := DrawImage{
		shy:    s
		factor: d.canvas.factor
		draw:   unsafe { d }
	}
	di.init() or {
		msg := 'initializing DrawImage failed'
		s.log.gcritical('${@STRUCT}.${@FN}', msg)
		panic('${@STRUCT}.${@FN}' + ' ' + msg)
	}
	return di
}
