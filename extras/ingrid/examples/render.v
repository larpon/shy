// Copyright(C) 2024 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module main

import shy.lib as shy
import shy.vec
import shy.embed
import shy.extras.ingrid

const c_max_zoom = 3
const c_min_zoom = 0.1

fn main() {
	mut app := &App{}
	shy.run[App](mut app)!
}

@[heap]
pub struct App {
	embed.ExampleApp
mut:
	grid          ingrid.Grid2D
	config        u8
	configs       [2]ingrid.Config2D
	bookmark      ingrid.Bookmark2D
	viewport      [2]shy.Rect
	warp_to       vec.Vec2[f32]
	warp_anchor   shy.Anchor = .center
	zoom          f32        = 1.0
	clip_viewport bool
}

pub fn (mut a App) init() ! {
	a.ExampleApp.init()!

	canvas := a.window.canvas()

	a.viewport[0] = shy.Rect{
		x:      shy.quarter * canvas.width
		y:      shy.quarter * canvas.height
		width:  shy.half * canvas.width
		height: shy.half * canvas.height
	}

	a.configs[0] = ingrid.Config2D{
		id:            0
		cell_size:     shy.Size{100, 100}
		fill_multiply: shy.Size{1, 1}
		dimensions:    a.viewport[0].size()
	}

	a.viewport[1] = shy.Rect{
		x:      0
		y:      0
		width:  canvas.width
		height: canvas.height
	}
	a.configs[1] = ingrid.Config2D{
		id:            1
		cell_size:     shy.Size{
			width:  1024
			height: 1024
		}
		fill_multiply: shy.Size{
			width:  10
			height: 8
		}
		dimensions:    a.viewport[1].size()
	}

	config := a.configs[a.config] or { a.configs[0] }
	a.update_grid_config(config)
}

pub fn (mut a App) update_viewport_dimensions() {
	canvas := a.window.canvas()

	a.viewport[0] = shy.Rect{
		x:      shy.quarter * canvas.width
		y:      shy.quarter * canvas.height
		width:  shy.half * canvas.width
		height: shy.half * canvas.height
	}

	a.configs[0] = ingrid.Config2D{
		...a.configs[0]
		dimensions: a.viewport[0].size()
	}

	a.viewport[1] = shy.Rect{
		x:      0
		y:      0
		width:  canvas.width
		height: canvas.height
	}
	a.configs[1] = ingrid.Config2D{
		...a.configs[1]
		dimensions: a.viewport[1].size()
	}
}

pub fn (mut a App) update_grid_config(config ingrid.Config2D) {
	a.grid = ingrid.make_2d(config)
	a.grid.init()
	a.grid.warp_anchor(a.warp_to, a.warp_anchor)
}

pub fn (mut a App) event(e shy.Event) {
	a.ExampleApp.event(e)
	mut fbf := a.configs[a.config].fill_multiply
	mut cs := a.configs[a.config].cell_size
	match e {
		shy.KeyEvent {
			if e.state == .up {
				return
			}
			key := e.key_code
			kb := a.keyboard
			alt_is_held := (kb.is_key_down(.lalt) || kb.is_key_down(.ralt))
			ctrl_is_held := (kb.is_key_down(.lctrl) || kb.is_key_down(.rctrl))
			shift_is_held := (kb.is_key_down(.lshift) || kb.is_key_down(.rshift))
			move_by := f32(22.0)
			match key {
				.up {
					if shift_is_held {
						fbf.height++
					} else if alt_is_held {
						cs.height -= 10
					} else if ctrl_is_held {
						a.warp_to.y -= 1
					} else {
						a.grid.move(shy.vec2[f32](0, move_by))
					}
				}
				.left {
					if shift_is_held {
						fbf.width--
					} else if alt_is_held {
						cs.width -= 10
					} else if ctrl_is_held {
						a.warp_to.x -= 1
					} else {
						a.grid.move(shy.vec2[f32](move_by, 0))
					}
				}
				.right {
					if shift_is_held {
						fbf.width++
					} else if alt_is_held {
						cs.width += 10
					} else if ctrl_is_held {
						a.warp_to.x += 1
					} else {
						a.grid.move(shy.vec2[f32](-move_by, 0))
					}
				}
				.down {
					if shift_is_held {
						fbf.height--
					} else if alt_is_held {
						cs.height += 10
					} else if ctrl_is_held {
						a.warp_to.y += 1
					} else {
						a.grid.move(shy.vec2[f32](0, -move_by))
					}
				}
				.w {
					a.grid.warp_anchor(a.warp_to, a.warp_anchor)
				}
				.s {
					a.bookmark = a.grid.bookmark()
				}
				.l {
					a.grid.load_bookmark(a.bookmark)
				}
				.a {
					if shift_is_held {
						a.warp_anchor = a.warp_anchor.prev()
					} else {
						a.warp_anchor = a.warp_anchor.next()
					}
				}
				.v {
					a.clip_viewport = !a.clip_viewport
				}
				.c {
					mut nc := int(a.config)
					if shift_is_held {
						nc++
					} else {
						nc--
					}
					if nc < 0 {
						nc = a.configs.len - 1
					}
					if nc > a.configs.len - 1 {
						nc = 0
					}
					a.config = u8(nc)
					a.update_grid_config(a.configs[a.config])
				}
				else {}
			}

			if key in [.up, .left, .right, .down] && (alt_is_held || shift_is_held) {
				a.configs[a.config] = ingrid.Config2D{
					...a.configs[a.config]
					cell_size:     cs
					fill_multiply: fbf
				}
				a.update_grid_config(a.configs[a.config])
			}
		}
		shy.MouseWheelEvent {
			if e.scroll_y > 0 {
				a.zoom += 0.1
			} else {
				a.zoom -= 0.1
			}

			if a.zoom > c_max_zoom {
				a.zoom = c_max_zoom
			}
			if a.zoom < c_min_zoom {
				a.zoom = c_min_zoom
			}
		}
		shy.WindowResizeEvent {
			a.update_viewport_dimensions()
			a.update_grid_config(a.configs[a.config])
		}
		else {}
	}
}

pub fn (mut a App) frame(dt f64) {
	canvas_width := a.window.canvas().width
	canvas_height := a.window.canvas().height

	center := shy.vec2[f32](canvas_width, canvas_height).mul_scalar(shy.half)

	draw := a.shy.draw()
	draw.push_matrix()
	draw.translate(center.x, center.y, 0)
	draw.scale(a.zoom, a.zoom, 1)
	draw.translate(-center.x, -center.y, 0)

	cell_size := a.grid.config.cell_size
	viewport := a.viewport[a.config]
	viewport_offset := viewport.pos_as_vec2[f32]()

	for i in 0 .. a.grid.count_cells() {
		cell := a.grid.cell_at_index(i)
		cell_pos := cell.pos + viewport_offset
		cell_rect := shy.Rect{
			x:      cell_pos.x
			y:      cell_pos.y
			width:  cell_size.width
			height: cell_size.height
		}

		if a.clip_viewport && !cell_rect.hit_rect(viewport) {
			continue
		}

		mut color := shy.colors.red
		if cell.ixy == a.warp_to {
			color = shy.colors.blue
		}
		if cell_rect.scale_at(center.x, center.y, a.zoom, a.zoom).contains(a.mouse.x,
			a.mouse.y)
		{
			color = color.copy_set_a(127)
		}

		a.quick.rect(
			x:      cell_pos.x
			y:      cell_pos.y
			width:  cell_size.width
			height: cell_size.height
			color:  color
		)
		a.quick.text(
			x:      cell_pos.x + (cell_size.width * 0.5)
			y:      cell_pos.y + (cell_size.height * 0.5)
			origin: shy.Anchor.center
			text:   '${cell.ixy.x},${cell.ixy.y}'
		)
	}

	fill := a.grid.fill()
	bounds := a.grid.bounds()

	a.quick.rect(
		x:      fill.x + viewport_offset.x
		y:      fill.y + viewport_offset.y
		width:  fill.width
		height: fill.height
		fills:  .stroke
		stroke: shy.Stroke{
			color: shy.colors.red
		}
	)
	a.quick.rect(
		x:      bounds.x + viewport_offset.x
		y:      bounds.y + viewport_offset.y
		width:  bounds.width
		height: bounds.height
		fills:  .stroke
		stroke: shy.Stroke{
			color: shy.colors.blue
		}
	)

	a.quick.rect(
		x:      viewport_offset.x
		y:      viewport_offset.y
		width:  viewport.width
		height: viewport.height
		fills:  .stroke
		stroke: shy.Stroke{
			color: shy.colors.green
		}
	)

	a.quick.circle(
		x:      center.x
		y:      center.y
		radius: 10
		fills:  .body
		color:  shy.colors.yellow.copy_set_a(127)
		origin: shy.Anchor.center
	)

	draw.pop_matrix()

	a.quick.text(
		x:      canvas_width * 0.01
		y:      canvas_height * 0.01
		origin: shy.Anchor.top_left
		size:   28
		text:   'Controls
Window can be resized via the mouse.
Zoom canvas via mouse scroll wheel.
Use "Alt" + arrow keys to change cell size.
Use "Shift" + arrow keys to change fill multipliers.
Use arrow keys alone to move origin cell.
Use "Ctrl" + arrow keys to adjust warp point.
Use "w" to warp the grid to warp point.
Use "Shift" + "a" and "a" to adjust the warp anchor.
Use "s" to bookmark (save) current grid.
Use "l" to load the last saved bookmark.
Use "c" to change current grid config
Use "v" to change viewport clipping (optimization)'
	)

	a.quick.text(
		x:      canvas_width * 0.01
		y:      canvas_height * 0.99
		origin: shy.Anchor.bottom_left
		size:   28
		text:   'Window ---
Size:  ${a.window.width}x${a.window.height}

Mouse ---
Location: ${a.mouse.x},${a.mouse.y}

Canvas ---
Factor: ${a.window.canvas().factor}
Size: ${a.window.canvas().width}x${a.window.canvas().height}
Zoom: ${a.zoom}

Config ---
Cell size: ${cell_size.width}x${cell_size.height}
Fill multipliers: ${a.grid.config.fill_multiply.width},${a.grid.config.fill_multiply.height}
Dimensions: ${a.grid.config.dimensions.width}x${a.grid.config.dimensions.height}

Grid ---
Origin: ixy: ${a.grid.origin().ixy.x},${a.grid.origin().ixy.y} pos: ${a.grid.origin().pos.x},${a.grid.origin().pos.y}
Cols (x): ${a.grid.cols()}
Rows (y): ${a.grid.rows()}
Cells: ${a.grid.count_cells()}
Fill: ${a.grid.fill().x},${a.grid.fill().y} ${a.grid.fill().width}x${a.grid.fill().height}
Bounds: ${a.grid.bounds().x},${a.grid.bounds().y} ${a.grid.bounds().width}x${a.grid.bounds().height}

Bookmark ---
ixy: ${a.bookmark.ixy.x},${a.bookmark.ixy.y}
pos: ${a.bookmark.pos.x},${a.bookmark.pos.y}

Warp ---
To: ${a.warp_to.x},${a.warp_to.y}
Anchor: ${a.warp_anchor}'
	)
}
