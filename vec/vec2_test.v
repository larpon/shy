import shy.lib as shy
import math

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

fn test_vec2_middle() {
	mut v1 := shy.vec2(10, 10)
	mut v2 := shy.vec2(20, 20)
	v3 := v1.middle(v2)
	assert v3 == shy.vec2(15, 15)
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

	mut zv := shy.vec2(5.0, 5.0)
	zv.zero()

	v3 := v1 + v2
	assert v3.x == 3
	assert v3.y == 7

	assert v1.dot(v2) == 14
	assert v1.cross(v2) == 5

	v1l := shy.vec2(40.0, 9.0)
	assert v1l.magnitude() == 41

	mut ctv1 := shy.vec2(0.000001, 0.000001)
	ctv1.clean_tolerance(0.00001)
	assert ctv1 == zv
}

fn test_vec2_f64_utils_2() {
	mut v1 := shy.vec2(4.0, 4.0)
	assert math.veryclose(v1.unit().magnitude(), 1)
	// assert v1.unit().magnitude() == 1
	v2 := v1.mul_scalar(0.5)
	assert v2.x == 2
	assert v2.y == 2
	assert math.veryclose(v2.unit().magnitude(), 1)
	// assert v2.unit().magnitude() == 1

	invv2 := v2.inv()
	assert invv2.x == 0.5
	assert invv2.y == 0.5
}

fn test_vec2_as_vec2() {
	mut v1_f64 := shy.vec2(4.0, 9.0)
	v2_int := v1_f64.as_vec2[int]()
	assert v2_int.x == int(4)
	assert v2_int.y == int(9)
}
