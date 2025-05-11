// Copyright(C) 2025 Lars Pontoppidan. All rights reserved.
//
module shape

// import shy.lib as shy
import shy.vec
// import shy.mth
// import shy.utils

pub const c_path_segments = u32($d('shy:shape:path_segments', 1024))

pub enum AutoConnect {
	none
	hard
	average
}

@[params]
pub struct PathOptions {
pub:
	auto_connect AutoConnect = .hard
}

pub struct Bezier {
pub mut:
	points [4]vec.Vec2[f32]
}

// p1 returns the point at `.points[0]` as a `vec.Vec2`.
pub fn (b Bezier) p1() vec.Vec2[f32] {
	return b.points[0]
}

// p2 returns the point at `.points[1]` as a `vec.Vec2`.
pub fn (b Bezier) p2() vec.Vec2[f32] {
	return b.points[1]
}

// p3 returns the point at `.points[2]` as a `vec.Vec2`.
pub fn (b Bezier) p3() vec.Vec2[f32] {
	return b.points[2]
}

// p4 returns the point at `.points[3]` as a `vec.Vec2`.
pub fn (b Bezier) p4() vec.Vec2[f32] {
	return b.points[3]
}

// set_p1 sets the point at `.points[0]` to the value of the `vec.Vec2` `v`.
pub fn (mut b Bezier) set_p1(v vec.Vec2[f32]) {
	b.points[0] = v
}

// set_p2 sets the point at `.points[1]` to the value of the `vec.Vec2` `v`.
pub fn (mut b Bezier) set_p2(v vec.Vec2[f32]) {
	b.points[1] = v
}

// set_p3 sets the point at `.points[2]` to the value of the `vec.Vec2` `v`.
pub fn (mut b Bezier) set_p3(v vec.Vec2[f32]) {
	b.points[2] = v
}

// set_p4 sets the point at `.points[3]` to the value of the `vec.Vec2` `v`.
pub fn (mut b Bezier) set_p4(v vec.Vec2[f32]) {
	b.points[3] = v
}

// make_4_points returns a fixed size [4] array of `vec.Vec2`. Each `x`,`y` pair in the argument list
// is assigned to the respective index in the array. `x1`,`y1` is thus the vector at index = 0.
pub fn make_4_points(x1 f32, y1 f32, x2 f32, y2 f32, x3 f32, y3 f32, x4 f32, y4 f32) [4]vec.Vec2[f32] {
	return [vec.Vec2[f32]{x1, x2}, vec.Vec2[f32]{x2, y2}, vec.Vec2[f32]{x3, y3},
		vec.Vec2[f32]{x4, y4}]!
}

pub struct Path {
mut:
	segments [$d('shy:shape:path_segments', 1024)]Bezier
pub mut:
	len int // should be read-only
}

// last_segment returns the last `Bezier` in `Path`.
@[inline]
pub fn (p &Path) last_segment() Bezier {
	assert p.len > 0
	return p.segments[p.len - 1]
}

// get returns the `Bezier` segment at index `i` in the `Path`.
@[inline]
pub fn (p &Path) get_segment(i int) Bezier {
	assert i >= 0
	assert i < p.len
	return p.segments[i]
}

// add adds the `Bezier` segment `b` to the end of `Path`.
pub fn (mut p Path) add_segment(b Bezier, options PathOptions) {
	assert p.len + 1 < c_path_segments
	p.segments[p.len] = b
	if p.len > 0 {
		p.auto_connect_segment(p.len, options.auto_connect)
	}
	p.len++
}

// insert inserts `Bezier` segment `b` at index `i` in the `Path`.
// If `options.auto_connect` is != `.none`, `b`'s end points will be adjusted accordingly
// so the first point is equal to the last point *before* it (`i - 1`) and
// the last point is equal to the first point of the segment *after* it (`i + 1`).
pub fn (mut p Path) insert_segment(i int, b Bezier, options PathOptions) {
	assert i >= 0
	assert i < c_path_segments - 1
	assert i < p.len

	if i == p.len - 1 {
		p.add_segment(b, options)
		return
	}

	mut segments := [$d('shy:shape:path_segments', 1024)]Bezier{}
	mut k := 0
	for j := 0; j < p.len; j++ {
		segments[k] = p.segments[j]
		if k == i {
			segments[k] = b
			k++
			j--
			continue
		}
		k++
	}
	p.segments = segments

	// for j := i; j < p.len; j++ {
	// 	p.segments[j + 1] = p.segments[j]
	// }
	// p.segments[i] = b
	p.auto_connect_segment(i, options.auto_connect)
	p.len++
}

// delete deletes the `Bezier` segment at index `i` in the `Path`.
// If `options.auto_connect` is != `.none`, remaining end points will be adjusted accordingly
// so the first point is equal to the last point *before* it (`i - 1`) and
// the last point is equal to the first point of the segment *after* it (`i + 1`).
pub fn (mut p Path) delete_segment(i int, options PathOptions) {
	assert i >= 0
	assert i < c_path_segments - 1
	assert i < p.len

	if i == p.len - 1 {
		p.delete_last_segment()
		return
	}

	mut segments := [$d('shy:shape:path_segments', 1024)]Bezier{}
	mut k := 0
	for j := 0; j < p.len; j++ {
		if j == i {
			continue
		} else {
			k++
		}
		segments[k - 1] = p.segments[j]
	}
	p.segments = segments
	p.len--
	p.auto_connect_segment(i, options.auto_connect)
}

// delete_last deletes the last `Bezier` segment in the `Path` efficiently.
pub fn (mut p Path) delete_last_segment() {
	if p.len - 1 >= 0 {
		p.len--
	}
}

// set sets (overwriting/replacing) the `Bezier` segment found at index `i`,
// with the `Bezier` segment `b`.
pub fn (mut p Path) set_segment(i int, b Bezier, options PathOptions) {
	assert i >= 0
	assert i < c_path_segments - 1
	assert i < p.len
	p.segments[i] = b
	p.auto_connect_segment(i, options.auto_connect)
}

// pop pops the last `Bezier` segment from the `Path` and returns it.
pub fn (mut p Path) pop_segment() Bezier {
	assert p.len > 0
	p.len--
	return p.segments[p.len]
}

fn (mut p Path) auto_connect_segment(i int, ac AutoConnect) {
	assert i >= 0
	assert i < c_path_segments - 1
	// assert i < p.len // NOTE: it is ok to pass higher since it allows for calling this function on end added segments in `add/2` also.
	match ac {
		.none {}
		.hard {
			if i > 0 {
				p.segments[i].points[0] = p.segments[i - 1].p4()
			}
			if i < p.len {
				p.segments[i].points[3] = p.segments[i + 1].p1()
			}
		}
		.average {
			if i > 0 {
				p1 := p.segments[i].p1()
				p2 := p.segments[i - 1].p4()
				pn := p1.middle(p2)
				p.segments[i].points[0] = pn
				p.segments[i - 1].points[3] = pn

				// p.segments[i].points[0] = p.segments[i - 1].p4()
			}
			if i < p.len {
				p1 := p.segments[i].p4()
				p2 := p.segments[i + 1].p1()
				pn := p1.middle(p2)
				p.segments[i].points[3] = pn
				p.segments[i + 1].points[0] = pn

				// p.segments[i].points[3] = p.segments[i + 1].p1()
			}
		}
	}
}
