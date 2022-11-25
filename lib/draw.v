// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module lib

[flag]
pub enum Fill {
	outline
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
	width   f32     = 1.0
	connect Connect = .bevel // Beav(el)is and Butt(head) - uuuh - huh huh
	cap     Cap     = .butt
	color   Color   = colors.shy.white
}

pub struct Draw {
	ShyStruct // pub mut:
	//	layer int
	//	font_layer []int
}

pub fn (d &Draw) shape_2d() DrawShape2D {
	// unsafe { d.layer++ }
	s := d.shy
	mut d2d := DrawShape2D{
		shy: s
	}
	d2d.init() or {
		msg := 'initializing DrawShape2D failed'
		s.log.gcritical('${@STRUCT}.${@FN}', msg)
		panic('${@STRUCT}.${@FN}' + ' ' + msg)
	}
	return d2d
}

pub fn (d &Draw) text(fonts Fonts) DrawText {
	// unsafe { d.layer++ }
	// d.font_layer << d.layer

	s := d.shy
	mut dt := DrawText{
		shy: s
		fonts: fonts // TODO fix this horrible font mess
	}
	dt.init() or {
		msg := 'initializing DrawText failed'
		s.log.gcritical('${@STRUCT}.${@FN}', msg)
		panic('${@STRUCT}.${@FN}' + ' ' + msg)
	}
	return dt
}

pub fn (d &Draw) image() DrawImage {
	// unsafe { d.layer++ }
	s := d.shy
	mut di := DrawImage{
		shy: s
	}
	di.init() or {
		msg := 'initializing DrawImage failed'
		s.log.gcritical('${@STRUCT}.${@FN}', msg)
		panic('${@STRUCT}.${@FN}' + ' ' + msg)
	}
	return di
}
