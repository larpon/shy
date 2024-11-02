// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module lib

import shy.vec { Vec2 }
import shy.wraps.sokol.gl
import shy.wraps.sokol.sfons

// DrawText
pub struct DrawText {
	ShyFrame
	factor f32 = 1.0
mut:
	font_context &FontContext = null
}

pub fn (mut dt DrawText) begin() {
	dt.ShyFrame.begin()
	win := dt.shy.active_window()
	// w, h := win.drawable_wh()

	mut gfx := unsafe { dt.shy.api.gfx }
	fc := gfx.get_font_context(win.gfx)

	/*
	// gl.set_context(fc.sgl)

	// unsafe { dt.shy.api.draw.layer++ }
	// gl.set_context(gl.default_context)
	// gl.layer(dt.shy.api.draw.layer)

	gl.defaults()

	gl.matrix_mode_projection()
	gl.ortho(0.0, f32(w), f32(h), 0.0, -1.0, 1.0)
	*/
	//¤ FLOOD dt.shy.log.gdebug('${@STRUCT}.${@FN}', 'begin ${ptr_str(fc.fsc)}...')
	dt.font_context = fc
	assert !isnil(fc), 'FontContext is null'
	fc.begin()
}

pub fn (mut dt DrawText) end() {
	dt.ShyFrame.end()
	fc := dt.font_context
	assert !isnil(fc), 'FontContext is null'
	if !isnil(fc) {
		//¤ FLOOD d2d.shy.log.gdebug('${@STRUCT}.${@FN}', 'end   ${ptr_str(fc.fsc)}...')
		fc.end()
		dt.font_context = null
	}

	// gl.draw_layer(dt.shy.api.draw.layer)
	// gl.context_draw(fc.sgl)
	// gl.draw()
}

pub fn (mut dt DrawText) text_2d() Draw2DText {
	assert !isnil(dt.font_context), 'DrawText.font_context is null'
	return Draw2DText{
		factor: dt.factor
		fc:     dt.font_context
	}
}

// pub type TextAlign = fontstash.Align

@[flag]
pub enum TextAlign {
	// Horizontal align
	left // Default
	center
	right
	// Vertical align
	top
	middle
	bottom
	baseline // Default
}

pub fn (ta TextAlign) str_clean() string {
	return ta.str().all_after('{').all_before('}').trim_space()
}

pub fn (ta TextAlign) next() TextAlign {
	if ta.has(.top) {
		if ta.has(.left) {
			return .top | .center
		} else if ta.has(.center) {
			return .top | .right
		} else {
			return .middle | .left
		}
	} else if ta.has(.middle) {
		if ta.has(.left) {
			return .middle | .center
		} else if ta.has(.center) {
			return .middle | .right
		} else {
			return .baseline | .left
		}
	} else if ta.has(.baseline) {
		if ta.has(.left) {
			return .baseline | .center
		} else if ta.has(.center) {
			return .baseline | .right
		} else {
			return .bottom | .left
		}
	} else if ta.has(.bottom) {
		if ta.has(.left) {
			return .bottom | .center
		} else if ta.has(.center) {
			return .bottom | .right
		} else {
			return .top | .left
		}
	}
	return .top | .left
}

pub struct Draw2DText {
	Vec2[f32]
	fc     &FontContext
	factor f32 = 1.0
mut:
	cur_align TextAlign = .baseline | .left // According to fontstash source code
pub mut:
	text     string
	rotation f32
	font     string    = defaults.font.name
	color    Color     = defaults.font.color
	origin   Origin    = Anchor.top_left
	align    TextAlign = .baseline | .left // TODO: V BUG lib.defaults.font.align
	size     f32       = defaults.font.size
	scale    f32       = 1.0
	fills    Fill      = .body | .stroke
	offset   Vec2[f32]
	blur     f32
}

/*
fn calculate_text_offset_from_anchor(anchor Anchor, max_w f32, max_h f32) ( f32, f32) {
	mut off_x := f32(0)
	mut off_y := f32(0)
	match anchor {
			.top_left {}
			.top_center {
				off_x = -(max_w / 2)
			}
			.top_right {
				off_x = -max_w
			}
			.center_left {
				off_y = -(max_h / 2)
			}
			.center {
				off_x = -(max_w / 2)
				off_y = -(max_h / 2)
			}
			.center_right {
				off_x = -max_w
				off_y = -(max_h / 2)
			}
			.bottom_left {
				off_y = -max_h
			}
			.bottom_center {
				off_x = -(max_w / 2)
				off_y = -max_h
			}
			.bottom_right {
				off_x = -max_w
				off_y = -max_h
			}
	}
	return off_x, off_y
}
*/

@[inline]
pub fn (t Draw2DText) draw() {
	// http://www.freetype.org/freetype2/docs/tutorial/metrics.png

	//¤ FLOOD d2d.shy.log.gdebug('${@STRUCT}.${@FN}', 'using ${ptr_str(fc.fsc)}...')
	fc := t.fc
	font_context := fc.fsc

	assert !isnil(font_context), '${@STRUCT}.${@FN}' + ': no font context'

	text_x := t.x * t.factor
	text_y := t.y * t.factor
	text_size := t.size * t.factor
	text_offset := t.offset.mul_scalar(t.factor)
	/*
	font_context.set_alignment(.left | .baseline)
	font_context.set_spacing(5.0)
	*/

	if t.font != defaults.font.name {
		font_id := fc.fonts[t.font]
		font_context.set_font(font_id)
	}

	// println('${@FN} ${t.color}')
	color := sfons.rgba(t.color.r, t.color.g, t.color.b, t.color.a)
	font_context.set_color(color)
	font_size := f32(int(text_size)) // TODO: rendering errors/artefacts on (some) float values?
	font_context.set_size(font_size)
	// eprintln('${@STRUCT}.${@FN} ${font_size}')
	unsafe {
		debug_font_spam(0, 'Font: "${t.font}" size: ${font_size}')
	}

	if t.blur > 0 {
		font_context.set_blur(t.blur)
	}

	lines := t.text.split('\n')

	fm := t.metrics()
	line_height := fm.line_height

	mut max_w := f32(0)
	mut max_h := f32(0)
	if lines.len > 0 {
		mut p_r := Rect{}
		for line in lines {
			r := t.bounds(line)
			if r.width > max_w {
				max_w = r.width
			}
			max_h += line_height - 2 // 1 // lines.len
			// max_h += line_height - (line_height - r.height) - 1
			p_r = r
		}
		if lines.len == 1 {
			max_w = p_r.width
			max_h = p_r.height
		}
	}

	mut y_accu := f32(0)
	mut prev_line_height := f32(0)
	for i, line in lines {
		mut off_x := f32(0)
		mut off_y := f32(0)
		// if t.origin != .bottom_left {

		/*
		mut align := TextAlign.baseline
		if t.align.has(.right) {
			align.set(.right)
		} else if t.align.has(.center) {
			align.set(.center)
		} else {
			align.set(.left)
		}
		t.set_font_render_alignment(align)
		*/
		align := t.align
		t.set_font_render_alignment(align)
		r := t.bounds(line)

		// ymin, ymax := t.line_bounds(0)
		// base_lh := '' // t.baseline_height(line)
		// println('Origin: $t.origin $r.x,$r.y w$r.width h$r.height\nyMin $ymin,yMax $ymax\nMetrics: $fm\nBaseline height: $base_lh\nLine height: $line_height\nText: $line\nAlign: $t.align\n$max_w x $max_h ')

		// Tweak for which corner of the text we're drawing.
		// per default, fontstash has chosen to let the drawing start from left at the font's baseline
		// We compensate for that here:

		off_compensate_y := -(r.y + r.height) + r.height
		off_y = off_compensate_y

		align_off_x := if align.has(.center) {
			(max_w / 2)
		} else if align.has(.right) {
			max_w
		} else {
			0
		}
		off_x += align_off_x

		o_off_x, o_off_y := t.origin.pos_wh(max_w, max_h)

		off_x += -o_off_x
		off_y += -o_off_y

		y_accu += prev_line_height
		prev_line_height = line_height - 2 // lines.len

		// Rounding x and y off (f32(int(...))) is important to prevent the rendering being smeared
		x := f32(int(text_x + text_offset.x + off_x))
		y := f32(int(text_y + text_offset.y + off_y + y_accu))

		gl.push_matrix()
		gl.translate(x, y, 0)

		if t.rotation != 0 {
			gl.rotate(t.rotation, 0, 0, 1)
		}
		if t.scale != 1 {
			gl.scale(t.scale, t.scale, 0)
		}
		font_context.draw_text(0, 0, line)

		t.dbg_draw_rect(r)

		$if shy_debug_draw ? {
			if i == 0 {
				t.dbg_draw_rect(Rect{
					x:      r.x - align_off_x / 2
					y:      r.y
					width:  max_w
					height: max_h
				})
			}
		}

		gl.translate(-x, -y, 0)
		gl.pop_matrix()
	}
}

@[inline; if shy_debug_draw ?]
fn (t Draw2DText) dbg_draw_line(x1 f32, y1 f32, x2 f32, y2 f32) {
	gl.begin_line_strip()
	gl.v2f(x1, y1)
	gl.v2f(x2, y2)
	gl.end()
}

@[inline; if shy_debug_draw ?]
fn (t Draw2DText) dbg_draw_rect(r Rect) {
	gl.begin_line_strip()
	gl.v2f(r.x, r.y)
	gl.v2f(r.x + r.width, r.y)
	gl.v2f(r.x + r.width, r.y)
	gl.v2f(r.x + r.width, r.y + r.height)
	gl.v2f(r.x + r.width, r.y + r.height)
	gl.v2f(r.x, r.y + r.height)
	gl.v2f(r.x, r.y)
	gl.end()
}

@[inline]
pub fn (t Draw2DText) set_font_render_alignment(align TextAlign) {
	unsafe {
		t.cur_align = align
		t.fc.fsc.set_align(int(align))
	}
}

@[inline]
pub fn (t Draw2DText) baseline_height(s string) f32 {
	prev_align := t.cur_align
	t.set_font_render_alignment(.left | .top)
	bounds_tl := t.bounds(s)
	t.set_font_render_alignment(.left | .baseline)
	bounds_de := t.bounds(s)
	t.set_font_render_alignment(prev_align)
	// println('btl: $bounds_base\nbbase: $bounds_base')
	return bounds_tl.y - bounds_de.y
}

@[inline]
pub fn (t Draw2DText) bounds(s string) Rect {
	fc := t.fc
	font_context := fc.fsc
	assert !isnil(font_context), '${@STRUCT}.${@FN}' + ': no font context'

	/*
	font_context.set_alignment(.left | .baseline)
	font_context.set_spacing(5.0)
	*/

	if t.font != defaults.font.name {
		font_id := fc.fonts[t.font]
		font_context.set_font(font_id)
	}
	color := sfons.rgba(t.color.r, t.color.g, t.color.b, t.color.a)
	font_context.set_color(color)
	font_size := f32(int(t.size)) // TODO: rendering errors/artefacts on (some) float values?
	font_context.set_size(font_size)
	// eprintln('${@STRUCT}.${@FN} ${font_size}')
	if t.blur > 0 {
		font_context.set_blur(t.blur)
	}
	mut buf := [4]f32{}
	font_context.text_bounds(0, 0, s, &buf[0])
	return Rect{
		x:      buf[0]
		y:      buf[1]
		width:  buf[2] - buf[0]
		height: buf[3] - buf[1]
	}
}

@[inline]
pub fn (t Draw2DText) line_bounds(y f32) (f32, f32) {
	mut min_y, mut max_y := f32(0), f32(0)
	t.fc.fsc.line_bounds(y, &min_y, &max_y)
	return min_y, max_y
}

pub struct FontMetrics {
pub:
	ascender    f32
	descender   f32
	line_height f32
}

@[inline]
pub fn (t Draw2DText) metrics() FontMetrics {
	mut asc, mut desc, line_h := f32(0), f32(0), f32(0)
	t.fc.fsc.vert_metrics(&asc, &desc, &line_h)
	return FontMetrics{
		ascender:    asc
		descender:   desc
		line_height: line_h
	}
}

@[inline]
fn (t Draw2DText) anchor_to_alignment(a Anchor) TextAlign {
	return match a {
		.top_left {
			.left | .top
		}
		.top_center {
			.top | .center
		}
		.top_right {
			.top | .right
		}
		.center_left {
			.middle | .left
		}
		.center {
			.middle | .center
		}
		.center_right {
			.middle | .right
		}
		.bottom_left {
			.bottom | .left
		}
		.bottom_center {
			.bottom | .center
		}
		.bottom_right {
			.bottom | .right
		}
	}
}
