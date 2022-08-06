// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module solid

pub fn (s Solid) text_draw() TextDraw {
	return TextDraw{
		solid: &s
	}
}

pub struct TextDraw {
mut:
	solid &Solid
pub mut:
	color Color = rgb(255, 255, 255)
}

pub fn (td TextDraw) text_at(text string, x int, y int) {
	td.solid.backend.font_system.draw_text_at(text, x, y)
}
