// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module shy

pub struct Draw {
	ShyStruct
}

pub fn (d &Draw) shape_2d() DrawShape2D {
	s := d.shy
	mut d2d := DrawShape2D{
		shy: s
	}
	d2d.init() or {
		msg := 'initializing DrawShape2D failed'
		s.log.gcritical(@STRUCT + '.' + @FN, msg)
		panic(@STRUCT + '.' + @FN + ' ' + msg)
	}
	return d2d
}

pub fn (d &Draw) text() DrawText {
	s := d.shy
	mut dt := DrawText{
		shy: s
	}
	dt.init() or {
		msg := 'initializing DrawText failed'
		s.log.gcritical(@STRUCT + '.' + @FN, msg)
		panic(@STRUCT + '.' + @FN + ' ' + msg)
	}
	return dt
}

pub fn (d &Draw) image() DrawImage {
	s := d.shy
	mut di := DrawImage{
		shy: s
	}
	di.init() or {
		msg := 'initializing DrawImage failed'
		s.log.gcritical(@STRUCT + '.' + @FN, msg)
		panic(@STRUCT + '.' + @FN + ' ' + msg)
	}
	return di
}
