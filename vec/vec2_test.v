import shy.lib as shy

fn test_vec2_int() {
	mut v1 := shy.vec2(0, 0)
	mut v2 := shy.vec2(0, 0)
	assert v1 == v2
	v1.one()
	v2.one()
	assert v1.x == 1
	assert v1.y == 1
	assert v1 == v2

	v3 := v1 + v2
	assert typeof(v3).name == 'vec.Vec2[int]'
	assert v3.x == 2
	assert v3.y == 2
}

fn test_vec2_f32() {
	mut v1 := shy.vec2(f32(0), 0)
	mut v2 := shy.vec2(f32(0), 0)
	assert v1 == v2
	v1.one()
	v2.one()
	assert v1.x == 1
	assert v1.y == 1
	assert v1 == v2

	v3 := v1 + v2
	assert typeof(v3).name == 'vec.Vec2[f32]'
	assert v3.x == 2
	assert v3.y == 2
}

fn test_vec2_f64() {
	mut v1 := shy.vec2(0.0, 0)
	mut v2 := shy.vec2(0.0, 0)
	assert v1 == v2
	v1.one()
	v2.one()
	assert v1.x == 1
	assert v1.y == 1
	assert v1 == v2

	v3 := v1 + v2
	assert typeof(v3).name == 'vec.Vec2[f64]'
	assert v3.x == 2
	assert v3.y == 2
}

fn test_vec2_f64_utils_1() {
	mut v1 := shy.vec2(2.0, 3.0)
	mut v2 := shy.vec2(1.0, 4.0)

	v3 := v1 + v2
	assert v3.x == 3
	assert v3.y == 7

	assert v1.dot(v2) == 14
	assert v1.cross(v2) == 5

	v1l := shy.vec2(40.0, 9.0)
	assert v1l.length() == 41
}

fn test_vec2_f64_utils_2() {
	mut v1 := shy.vec2(4.0, 4.0)
	assert v1.unit().length() == 1
	v2 := v1.mul_scalar(0.5)
	assert v2.x == 2
	assert v2.y == 2
	assert v2.unit().length() == 1

	invv2 := v2.inv()
	assert invv2.x == 0.5
	assert invv2.y == 0.5
}
