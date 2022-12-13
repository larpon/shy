// Copyright(C) 2020-2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license file distributed with this software package

module vec

import math

pub struct Vec3[T] {
pub mut:
	x f64
	y f64
	z f64
}

pub fn vec3[T](x T, y T, z T) Vec3[T] {
	return Vec3[T]{
		x: x
		y: y
		z: z
	}
}

pub fn (mut v Vec3[T]) zero() {
	v.x = 0.0
	v.y = 0.0
	v.z = 0.0
}

pub fn (mut v Vec3[T]) copy() Vec3[T] {
	return Vec3[T]{v.x, v.y, v.z}
}

pub fn (mut v Vec3[T]) from(u Vec3[T]) {
	v.x = u.x
	v.y = u.y
	v.z = u.z
}

/*
pub fn (mut v Vec3[T]) from_vec2(u Vec2) {
	v.x = u.x
	v.y = u.y
}

pub fn (mut v Vec3[T]) as_vec2() Vec2 {
	return Vec2{v.x, v.y}
}
*/
//
// Addition
//
// + operator overload. Adds two vectors
pub fn (v1 Vec3[T]) + (v2 Vec3[T]) Vec3[T] {
	return Vec3[T]{v1.x + v2.x, v1.y + v2.y, v1.z + v2.z}
}

pub fn (v Vec3[T]) add(u Vec3[T]) Vec3[T] {
	return Vec3[T]{v.x + u.x, v.y + u.y, v.z + u.z}
}

/*
pub fn (v Vec3[T]) add_vec2(u Vec2) Vec3[T] {
	return Vec3[T]{v.x + u.x, v.y + u.y, v.z}
}
*/
pub fn (v Vec3[T]) add_f64(scalar f64) Vec3[T] {
	return Vec3[T]{v.x + scalar, v.y + scalar, v.z + scalar}
}

pub fn (v Vec3[T]) add_f32(scalar f32) Vec3[T] {
	return Vec3[T]{v.x + scalar, v.y + scalar, v.z + scalar}
}

pub fn (mut v Vec3[T]) plus(u Vec3[T]) {
	v.x += u.x
	v.y += u.y
	v.z += u.z
}

pub fn (mut v Vec3[T]) plus_f64(scalar f64) {
	v.x += scalar
	v.y += scalar
	v.z += scalar
}

pub fn (mut v Vec3[T]) plus_f32(scalar f32) {
	v.x += scalar
	v.y += scalar
	v.z += scalar
}

//
// Subtraction
//
pub fn (v1 Vec3[T]) - (v2 Vec3[T]) Vec3[T] {
	return Vec3[T]{v1.x - v2.x, v1.y - v2.y, v1.z - v2.z}
}

pub fn (v Vec3[T]) sub(u Vec3[T]) Vec3[T] {
	return Vec3[T]{v.x - u.x, v.y - u.y, v.z - u.z}
}

pub fn (v Vec3[T]) sub_f64(scalar f64) Vec3[T] {
	return Vec3[T]{v.x - scalar, v.y - scalar, v.z - scalar}
}

pub fn (mut v Vec3[T]) subtract(u Vec3[T]) {
	v.x -= u.x
	v.y -= u.y
	v.z -= u.z
}

pub fn (mut v Vec3[T]) subtract_f64(scalar f64) {
	v.x -= scalar
	v.y -= scalar
	v.z -= scalar
}

//
// Multiplication
//
pub fn (v1 Vec3[T]) * (v2 Vec3[T]) Vec3[T] {
	return Vec3[T]{v1.x * v2.x, v1.y * v2.y, v1.z * v2.z}
}

pub fn (v Vec3[T]) mul(u Vec3[T]) Vec3[T] {
	return Vec3[T]{v.x * u.x, v.y * u.y, v.z * u.z}
}

pub fn (v Vec3[T]) mul_scalar(scalar T) Vec3[T] {
	return Vec3[T]{v.x * scalar, v.y * scalar, v.z * scalar}
}

pub fn (v Vec3[T]) mul_f64(scalar f64) Vec3[T] {
	return Vec3[T]{v.x * scalar, v.y * scalar, v.z * scalar}
}

pub fn (mut v Vec3[T]) multiply(u Vec3[T]) {
	v.x *= u.x
	v.y *= u.y
	v.z *= u.z
}

pub fn (mut v Vec3[T]) multiply_f64(scalar f64) {
	v.x *= scalar
	v.y *= scalar
	v.z *= scalar
}

//
// Division
//
pub fn (v1 Vec3[T]) / (v2 Vec3[T]) Vec3[T] {
	return Vec3[T]{v1.x / v2.x, v1.y / v2.y, v1.z / v2.z}
}

pub fn (v Vec3[T]) div(u Vec3[T]) Vec3[T] {
	return Vec3[T]{v.x / u.x, v.y / u.y, v.z / u.z}
}

pub fn (v Vec3[T]) div_f64(scalar f64) Vec3[T] {
	return Vec3[T]{v.x / scalar, v.y / scalar, v.z / scalar}
}

pub fn (mut v Vec3[T]) divide(u Vec3[T]) {
	v.x /= u.x
	v.y /= u.y
	v.z /= u.z
}

pub fn (mut v Vec3[T]) divide_f64(scalar f64) {
	v.x /= scalar
	v.y /= scalar
	v.z /= scalar
}

//
// Utility
//
pub fn (v Vec3[T]) length() T {
	if v.x == 0 && v.y == 0 && v.z == 0 {
		return 0.0
	}
	return T(math.sqrt((v.x * v.x) + (v.y * v.y) + (v.z * v.z)))
}

pub fn (v Vec3[T]) dot(u Vec3[T]) T {
	return T((v.x * u.x) + (v.y * u.y) + (v.z * u.z))
}

// cross returns the cross product of v and u
pub fn (v Vec3[T]) cross(u Vec3[T]) Vec3[T] {
	return Vec3[T]{
		x: (v.y * u.z) - (v.z * u.y)
		y: (v.z * u.x) - (v.x * u.z)
		z: (v.x * u.y) - (v.y * u.x)
	}
}

// unit return this vector's unit vector
pub fn (v Vec3[T]) unit() Vec3[T] {
	length := v.length()
	return Vec3[T]{v.x / length, v.y / length, v.z / length}
}

/*
pub fn (v Vec3[T]) perp() Vec3[T] {
	return Vec3[T]{ -v.y, v.x }
}
*/
// perpendicular return the perpendicular vector of this
pub fn (v Vec3[T]) perpendicular(u Vec3[T]) Vec3[T] {
	return v - v.project(u)
}

// project returns the projected vector
pub fn (v Vec3[T]) project(u Vec3[T]) Vec3[T] {
	percent := v.dot(u) / u.dot(v)
	return u.mul_scalar(percent)
}

// eq returns a bool indicating if the two vectors are equal
pub fn (v Vec3[T]) eq(u Vec3[T]) bool {
	return v.x == u.x && v.y == u.y && v.z == u.z
}

/*
// eq_epsilon returns a bool indicating if the two vectors are equal within epsilon
pub fn (v Vec3[T]) eq_epsilon(u Vec3[T]) bool {
	return v.x.eq_epsilon(u.x) && v.y.eq_epsilon(u.y)
}
*/

// eq_approx will return a bool indicating if vectors are approximately equal within the tolerance
pub fn (v Vec3[T]) eq_approx(u Vec3[T], tolerance f64) bool {
	diff_x := math.abs(v.x - u.x)
	diff_y := math.abs(v.y - u.y)
	diff_z := math.abs(v.z - u.z)
	if diff_x <= tolerance && diff_y <= tolerance && diff_z <= tolerance {
		return true
	}

	max_x := math.max(math.abs(v.x), math.abs(u.x))
	max_y := math.max(math.abs(v.y), math.abs(u.y))
	max_z := math.max(math.abs(v.z), math.abs(u.z))
	if diff_x < max_x * tolerance && diff_y < max_y * tolerance && diff_z < max_z * tolerance {
		return true
	}
	return false
}

// is_approx_zero will return a bool indicating if this vector is zero within tolerance
pub fn (v Vec3[T]) is_approx_zero(tolerance f64) bool {
	if math.abs(v.x) <= tolerance && math.abs(v.y) <= tolerance && math.abs(v.z) <= tolerance {
		return true
	}
	return false
}

// eq_scalar returns a bool indicating if the x and y both equals the scalar
pub fn (v Vec3[T]) eq_scalar(scalar T) bool {
	return v.x == scalar && v.y == scalar && v.z == scalar
}

/*
// eq_f64 returns a bool indicating if the x and y both equals the scalar
pub fn (v Vec3[T]) eq_f64(scalar f64) bool {
	return v.x == scalar && v.y == scalar
}

// eq_f32 returns a bool indicating if the x and y both equals the scalar
pub fn (v Vec3[T]) eq_f32(scalar f32) bool {
	return v.eq_f64(f64(scalar))
}v.y /= scalar

// distance returns the distance between the two vectors
pub fn (v Vec3[T]) distance(u Vec3[T]) f64 {
	return math.sqrt( (v.x-u.x) * (v.x-u.x) + (v.y-u.y) * (v.y-u.y) )
}

// manhattan_distance returns the Manhattan distance between the two vectors
pub fn (v Vec3[T]) manhattan_distance(u Vec3[T]) f64 {
	return math.fabs(v.x-u.x) + math.fabs(v.y-u.y)
}

// angle_between returns the angle in radians between the two vectors
pub fn (v Vec3[T]) angle_between(u Vec3[T]) f64 {
	return math.atan2( (v.y-u.y), (v.x-u.x) )
}

// angle returns the angle in radians of the vector
pub fn (v Vec3[T]) angle() f64 {
	return math.atan2(v.y, v.x)
}
*/
// abs will set x and y values to their absolute values
pub fn (mut v Vec3[T]) abs() {
	if v.x < 0 {
		v.x = math.abs(v.x)
	}
	if v.y < 0 {
		v.y = math.abs(v.y)
	}
	if v.z < 0 {
		v.z = math.abs(v.z)
	}
}
