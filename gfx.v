// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module shy

pub struct Draw {
	ShyApp
}

pub fn (d &Draw) new_2d() Draw2D {
	s := d.shy
	mut d2d := Draw2D{
		shy: s
	}
	d2d.init() or {
		msg := 'initializing Draw2D failed'
		s.log.gcritical(@STRUCT + '.' + @FN, msg)
		panic(@STRUCT + '.' + @FN + ' ')
	}
	return d2d
}

pub fn (d &Draw) new_text() DrawText {
	s := d.shy
	mut dt := DrawText{
		shy: s
	}
	dt.init() or {
		msg := 'initializing DrawText failed'
		s.log.gcritical(@STRUCT + '.' + @FN, msg)
		panic(@STRUCT + '.' + @FN + ' ')
	}
	return dt
}
