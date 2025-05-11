import shy.lib as shy
import shy.shape

const p_1 = [shy.vec2[f32](100, 100), shy.vec2[f32](120, 80),
	shy.vec2[f32](200, 70), shy.vec2[f32](400, 200)]!
const p_2 = [shy.vec2[f32](0, 0), shy.vec2[f32](200, 70) + shy.vec2[f32](0, 2 * 80),
	shy.vec2[f32](200, 70), shy.vec2[f32](800, 400)]!
const p_3 = [shy.vec2[f32](0, 0), shy.vec2[f32](100, 10), shy.vec2[f32](211, 99),
	shy.vec2[f32](0, 0)]!

fn test_paths_default_1() {
	b1 := shape.Bezier{
		points: p_1
	}

	b2 := shape.Bezier{
		points: p_2
	}

	b3 := shape.Bezier{
		points: p_3
	}

	mut p := shape.Path{}
	assert p.len == 0

	p.add_segment(b1)
	assert p.len == 1
	assert p.get_segment(0).p1() == p_1[0]
	assert p.get_segment(0).p2() == p_1[1]
	assert p.get_segment(0).p3() == p_1[2]
	assert p.get_segment(0).p4() == p_1[3]
	p.add_segment(b2)
	assert p.len == 2
	assert p.get_segment(1).p1() == p_1[3]
	assert p.get_segment(1).p2() == p_2[1]
	assert p.get_segment(1).p3() == p_2[2]
	assert p.get_segment(1).p4() == p_2[3]
	p.insert_segment(1, b3)
	assert p.len == 3
	assert p.get_segment(1).p1() == p_1[3]
	assert p.get_segment(1).p1() == p.get_segment(0).p4()
	assert p.get_segment(1).p2() == p_3[1]
	assert p.get_segment(1).p3() == p_3[2]
	assert p.get_segment(1).p4() == p.get_segment(2).p1()
	// Check that b2 has moved forward, and should have untouched values (from before the insert)
	assert p.get_segment(2).p1() == p_1[3]
	assert p.get_segment(2).p2() == p_2[1]
	assert p.get_segment(2).p3() == p_2[2]
	assert p.get_segment(2).p4() == p_2[3]
}

fn test_paths_average_connect_1() {
	b1 := shape.Bezier{
		points: p_1
	}

	b2 := shape.Bezier{
		points: p_2
	}

	b3 := shape.Bezier{
		points: p_3
	}

	mut p := shape.Path{}

	assert p.len == 0
	p.add_segment(b1, auto_connect: .average)
	assert p.len == 1
	assert p.get_segment(0).p1() == p_1[0]
	assert p.get_segment(0).p2() == p_1[1]
	assert p.get_segment(0).p3() == p_1[2]
	assert p.get_segment(0).p4() == p_1[3]
	p.add_segment(b2, auto_connect: .average)
	assert p.len == 2
	assert p.get_segment(0).p4() == shy.vec2[f32](200, 100)
	assert p.get_segment(1).p1() == p_1[3].mul_scalar(0.5)
	assert p.get_segment(1).p1() == shy.vec2[f32](200, 100)
	assert p.get_segment(1).p2() == p_2[1]
	assert p.get_segment(1).p3() == p_2[2]
	assert p.get_segment(1).p4() == p_2[3]
	p.insert_segment(1, b3, auto_connect: .average)
	assert p.len == 3
	assert p.get_segment(0).p4() == shy.vec2[f32](100, 50)
	assert p.get_segment(1).p1() == shy.vec2[f32](100, 50)
	assert p.get_segment(1).p1() == p.get_segment(0).p4()
	assert p.get_segment(1).p2() == p_3[1]
	assert p.get_segment(1).p3() == p_3[2]
	assert p.get_segment(1).p4() == p.get_segment(2).p1()
	// Check that b2 has moved forward, and should have *averaged* values (from before the insert)
	assert p.get_segment(2).p1() == shy.vec2[f32](100, 50)
	assert p.get_segment(2).p2() == p_2[1]
	assert p.get_segment(2).p3() == p_2[2]
	assert p.get_segment(2).p4() == p_2[3]
}

fn test_paths_delete_1() {
	b1 := shape.Bezier{
		points: p_1
	}

	b2 := shape.Bezier{
		points: p_2
	}

	b3 := shape.Bezier{
		points: p_3
	}

	mut p := shape.Path{}

	p.add_segment(b1)
	p.add_segment(b2)
	p.insert_segment(1, b3)
	dump(p.get_segment(0))
	dump(p.get_segment(1))
	dump(p.get_segment(2))
	println('---')
	p.delete_segment(0)
	dump(p.get_segment(0))
	dump(p.get_segment(1))
	println('---')
	p.insert_segment(0, b3)
	dump(p.get_segment(0))
	dump(p.get_segment(1))
	dump(p.get_segment(2))
	println('---')
	p.delete_segment(1)
	dump(p.get_segment(0))
	dump(p.get_segment(1))
	//	dump(p.get_segment(2))

	// assert false
}
