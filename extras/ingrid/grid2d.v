module ingrid

// 2D grid in 1D array: https://softwareengineering.stackexchange.com/questions/212808/treating-a-1d-data-structure-as-2d-grid
import shy.lib as shy
import shy.vec
import shy.mth

const c_zero_vec2 = vec.Vec2[f32]{0, 0}

@[if shy_trace_ingrid ?]
fn epln(str string) {
	eprintln(str)
}

// Cell2D represents a 2D cell in a `Grid2D`.
// `grid_id` is the id of the Grid2D.config.id this cell belongs to.
// `grid_id` can be helpful if several grids are used in the same codebase.
// The `ixy` field is a unique coordinate "index" of the cell that can be used as a seed for a random number generator.
// `ixy` is used to *uniquely* identify each cell in the grid.
// The `pos` field represents the position of this cell in 2D graphics space. (top-left 0,0)
pub struct Cell2D {
pub:
	grid_id u32
	ixy     vec.Vec2[f32]
	pos     vec.Vec2[f32]
}

// Bookmark2D represents an, immutable, exact position in the grid that can be restored via `load_bookmark`.
pub struct Bookmark2D {
pub:
	config Config2D
	ixy    vec.Vec2[f32]
	pos    vec.Vec2[f32]
}

// Config2D represents a configuration for a `Grid2D` grid.
@[params]
pub struct Config2D {
pub:
	id            u32 //@[required]
	units         vec.Vec2[f32] = vec.Vec2[f32]{1, 1} // Units or resolution of the cell coordinates
	cell_size     shy.Size      = shy.Size{100, 100}      // Default cell size w,h
	fill_multiply shy.Size      = shy.Size{1, 1}
	dimensions    shy.Size
}

// Grid2D represents and hold the state of an "infinite" 2 dimensional grid of cells.
pub struct Grid2D {
pub:
	config Config2D // [required]
mut:
	origin Cell2D // The "origin" (top-left) cell that everything can be calculated from

	fill   shy.Rect // Area which should be "filled" with cells at a minimum
	bounds shy.Rect // Cells shift ixy coordinates when moving outside these

	rows int
	cols int
}

// make_2d returns an initialized `Grid2D` from a `Config2D`.
pub fn make_2d(config Config2D) Grid2D {
	return Grid2D{
		config: config
	}
}

// origin returns the "origin" cell (the top-left most cell in the grid).
pub fn (g &Grid2D) origin() Cell2D {
	return g.origin
}

// cols_and_rows returns the amount of columns and rows used in the grid
pub fn (g &Grid2D) cols_and_rows() (int, int) {
	return g.cols, g.rows
}

// cols returns the amount of columns in the grid
pub fn (g &Grid2D) cols() int {
	return g.cols
}

// rows returns the amount of rows used in the grid
pub fn (g &Grid2D) rows() int {
	return g.rows
}

// count_cells returns the amount of cells in the grid.
pub fn (g &Grid2D) count_cells() int {
	return g.cols * g.rows
}

// fill returns the 2D rectangle that are the bounds of which the grid should always keep filled
// with cells. The fill is calculated based on factors supplied via the grid's configuration.
pub fn (g &Grid2D) fill() shy.Rect {
	return shy.Rect{
		x:      g.fill.x
		y:      g.fill.y
		width:  g.fill.width
		height: g.fill.height
	}
}

// bounds returns the rectangle used for collision detection for when a cells leaves/enters the grid.
pub fn (g &Grid2D) bounds() shy.Rect {
	return shy.Rect{
		x:      g.bounds.x
		y:      g.bounds.y
		width:  g.bounds.width
		height: g.bounds.height
	}
}

// init (re)initializes the grid with cells when called.
pub fn (mut g Grid2D) init() {
	g.update_dimensions()
	g.reset_origin()
	g.warp(vec.Vec2[f32]{})
}

// shutdown shuts down the grid.
pub fn (mut g Grid2D) shutdown() {}

// reset_origin resets the grid's "origin" (top-left most) cell.
pub fn (mut g Grid2D) reset_origin() {
	g.origin = Cell2D{
		grid_id: g.config.id
		ixy:     c_zero_vec2
		pos:     c_zero_vec2
	}
}

// cell_at_index_safe returns the `Cell2D` at the given `index`.
// If `index` is out of bounds, the index is clamped to be within a valid range.
pub fn (g &Grid2D) cell_at_index_safe(index int) Cell2D {
	mut i := index
	if i >= g.count_cells() {
		i = g.count_cells() - 1
	} else if i < 0 {
		i = 0
	}
	ix := i % g.cols
	iy := (i / g.cols) % g.rows // NOTE: integer division

	ixy := vec.Vec2[f32]{g.origin.ixy.x + ix, g.origin.ixy.y + iy} * g.config.units
	pos := vec.Vec2[f32]{g.origin.pos.x + (ix * g.config.cell_size.width), g.origin.pos.y +
		(iy * g.config.cell_size.height)}

	return Cell2D{
		grid_id: g.config.id
		ixy:     ixy
		pos:     pos
	}
}

// cell_at_index returns the `Cell2D` located at `index` in the grid.
// cell_at_index can be used to iterate the grid cells as if they where a 1 dimensional array.
pub fn (g &Grid2D) cell_at_index(index int) Cell2D {
	$if !no_bounds_checking {
		if index < 0 || index >= g.count_cells() {
			panic('shy.extras.ingrid.Grid2D.cell_at_index/1:\nRequested index must be in range 0 to (Grid2D.cols * Grid2D.rows - 1) (Grid2D.count_cells/0).\nUse `cell_at_index_safe/1` for a slightly slower, but safe access')
		}
	}
	ix := index % g.cols
	iy := (index / g.cols) % g.rows // NOTE: integer division

	ixy := vec.Vec2[f32]{g.origin.ixy.x + ix, g.origin.ixy.y + iy} * g.config.units
	pos := vec.Vec2[f32]{g.origin.pos.x + (ix * g.config.cell_size.width), g.origin.pos.y +
		(iy * g.config.cell_size.height)}

	return Cell2D{
		grid_id: g.config.id
		ixy:     ixy
		pos:     pos
	}
}

// move moves origin cell relatively by `relative_v`.
pub fn (mut g Grid2D) move(relative_v vec.Vec2[f32]) {
	if relative_v.x == 0 && relative_v.y == 0 {
		return
	}
	mut v := relative_v
	// Move in smaller bits
	for mth.abs(v.x) > g.config.cell_size.width || mth.abs(v.y) > g.config.cell_size.height {
		if v.x > g.config.cell_size.width {
			v.x -= g.config.cell_size.width
			g.move(vec.Vec2[f32]{g.config.cell_size.width, 0})
		} else if v.x < -g.config.cell_size.width {
			v.x += g.config.cell_size.width
			g.move(vec.Vec2[f32]{-g.config.cell_size.width, 0})
		}

		if v.y > g.config.cell_size.height {
			v.y -= g.config.cell_size.height
			g.move(vec.Vec2[f32]{0, g.config.cell_size.height})
		} else if v.y < -g.config.cell_size.height {
			v.y += g.config.cell_size.height
			g.move(vec.Vec2[f32]{0, -g.config.cell_size.height})
		}
		// println('relative_v ${relative_v.x},${relative_v.y} require smaller move ${v.x},${v.y} ')
	}

	mut nx := g.origin.pos.x + v.x
	mut ny := g.origin.pos.y + v.y
	mut nix := g.origin.ixy.x
	mut niy := g.origin.ixy.y

	v_br := g.cell_at_index(g.count_cells() - 1) // TODO: can assert for < 0
	v_br_nx := v_br.pos.x + v.x
	v_br_ny := v_br.pos.y + v.y

	limit_tl := vec.Vec2[f32]{g.bounds.x, g.bounds.y}
	limit_br := vec.Vec2[f32]{g.bounds.x + g.bounds.width - g.config.cell_size.width, g.bounds.y +
		g.bounds.height - g.config.cell_size.height}

	if nx < limit_tl.x {
		nx = nx + g.config.cell_size.width
		nix = nix + (1 * g.config.units.x)
	} else if v_br_nx > limit_br.x {
		nx = nx - g.config.cell_size.width
		nix = nix - (1 * g.config.units.x)
	}
	if ny < limit_tl.y {
		ny = ny + g.config.cell_size.height
		niy = niy + (1 * g.config.units.y)
	} else if v_br_ny > limit_br.y {
		ny = ny - g.config.cell_size.height
		niy = niy - (1 * g.config.units.y)
	}

	g.origin = Cell2D{
		grid_id: g.config.id
		ixy:     vec.Vec2[f32]{nix, niy}
		pos:     vec.Vec2[f32]{nx, ny}
	}
}

// warp instantly "warps" to this cell coordinate, and centers the cell inside the dimensions.
pub fn (mut g Grid2D) warp(ixy vec.Vec2[f32]) {
	g.warp_anchor(ixy, .center)
}

// warp_anchor instantly "warps" to cell coordinate `ixy` making it appear at the `anchor` inside the dimensions.
pub fn (mut g Grid2D) warp_anchor(ixy vec.Vec2[f32], anchor shy.Anchor) {
	g.reset_origin()
	g.origin = Cell2D{
		...g.origin
		ixy: ixy
	}

	mut move_to := vec.Vec2[f32]{0, 0}

	cell_size := g.config.cell_size
	half_cell_size := cell_size.mul_scalar(0.5)
	match anchor {
		.top_left {
			// Default / origin point
		}
		.top_center {
			move_to.x = (g.config.dimensions.width * 0.5) - half_cell_size.width
		}
		.top_right {
			move_to.x = (g.config.dimensions.width) - cell_size.width
		}
		.center_left {
			move_to.y = (g.config.dimensions.height * 0.5) - half_cell_size.height
		}
		.center {
			move_to.x = (g.config.dimensions.width * 0.5) - half_cell_size.width
			move_to.y = (g.config.dimensions.height * 0.5) - half_cell_size.height
		}
		.center_right {
			move_to.x = (g.config.dimensions.width) - cell_size.width
			move_to.y = (g.config.dimensions.height * 0.5) - half_cell_size.height
		}
		.bottom_left {
			move_to.y = (g.config.dimensions.height) - cell_size.height
		}
		.bottom_center {
			move_to.x = (g.config.dimensions.width * 0.5) - half_cell_size.width
			move_to.y = (g.config.dimensions.height) - cell_size.height
		}
		.bottom_right {
			move_to.x = (g.config.dimensions.width) - cell_size.width
			move_to.y = (g.config.dimensions.height) - cell_size.height
		}
	}

	g.move(move_to)
	for _ in 0 .. mth.max(g.cols, g.rows) {
		g.touch()
	}
}

// cell_at gets the cell at dimensions (self.rect) x,y coordinate.
// pub fn (g &Grid2D) cell_at(xy vec.Vec2[f32]) ?Cell2D {
// 	vp := g.config.dimensions
//
// 	if xy.x < 0 || xy.x > vp.width {
// 		return none
// 	}
// 	if xy.y < 0 || xy.y > vp.height {
// 		return none
// 	}
//
// 	for i in 0 .. g.count_cells() {
// 		cell := g.cell_at_index(i)
// 		cell_rect := shy.Rect{
// 			x: cell.pos.x
// 			y: cell.pos.y
// 			width: g.config.cell_size.width
// 			height: g.config.cell_size.height
// 		}
// 		if cell_rect.contains(xy.x,xy.y) {
// 			return cell
// 		}
// 	}
// 	return none
// }

// relative_position_in_cell_at returns the relative position of `xy` inside the cell located at `xy` coordinate.
// pub fn (g Grid2D) relative_position_in_cell_at(xy vec.Vec2[f32]) ?vec.Vec2[f32] {
// 	if cell := g.cell_at(xy) {
// 		pos := cell.pos
// 		return xy - pos
// 	}
// 	return none
// }

// bookmark returns a `Bookmark` struct that can be used to restore the cells as they
// occur when this function is called. Restoring is done with `load_bookmark`
pub fn (g Grid2D) bookmark() Bookmark2D {
	cell := g.origin
	return Bookmark2D{
		config: g.config
		ixy:    cell.ixy
		pos:    cell.pos
	}
}

// load_bookmark instantly loads the bookmark.
// NOTE: bookmarks are not reliable across grids unless the grids has identical dimensions and cell sizes,
// use the `config` field of the `Bookmark2D` to access the data of the grid that the bookmark was saved in.
pub fn (mut g Grid2D) load_bookmark(bookmark Bookmark2D) {
	ixy := bookmark.ixy
	pos := bookmark.pos

	g.origin = Cell2D{
		grid_id: g.config.id
		ixy:     ixy
		pos:     pos
	}
}

// Utility functions

// touch moves the grid a bit back and forth by the same amount to trigger any cells on the edges
fn (mut g Grid2D) touch() {
	g.move(vec.Vec2[f32]{1, 1})
	g.move(vec.Vec2[f32]{-1, -1})
}

fn (mut g Grid2D) update_dimensions() {
	g.update_fills()

	w := g.fill.width
	h := g.fill.height

	g.cols = int(mth.ceil(w / g.config.cell_size.width))
	g.rows = int(mth.ceil(h / g.config.cell_size.height))

	epln('${@STRUCT}.${@FN}: w: ${w}, h: ${h} g.cols: ${g.cols}, g.rows: ${g.rows}, cell: ${g.config.cell_size}')
}

fn (mut g Grid2D) update_fills() {
	vp := g.config.dimensions
	cell_size := g.config.cell_size
	fill_multiply := g.config.fill_multiply
	fill_box := vec.Vec2{cell_size.width * fill_multiply.width, cell_size.height * fill_multiply.height}
	bounds_box := vec.Vec2{(fill_box.x + cell_size.width) * 1.0, (fill_box.y + cell_size.height) * 1.0}

	rect := shy.Rect{0, 0, vp.width, vp.height}
	fill_area := rect.grow(fill_box.x, fill_box.y, fill_box.x, fill_box.y)
	bounds_area := rect.grow(bounds_box.x, bounds_box.y, bounds_box.x, bounds_box.y)

	g.fill = fill_area
	g.bounds = bounds_area
}
