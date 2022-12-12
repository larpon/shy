// Copyright(C) 2020-2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license file distributed with this software package
//
// NOTE a few of the following functions was adapted from Dario Deleddas excellent
// work on the `gg.m4` vlib module. Here's the Copyright/license text covering that code:
//
// Copyright (c) 2021 Dario Deledda. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module vec

import math

pub struct Vec4[T] {
pub mut:
	x T
	y T
	z T
	w T
}

pub fn vec4[T](x T, y T, z T, w T) Vec4[T] {
	return Vec4[T]{
		x: x
		y: y
		z: z
		w: w
	}
}

pub fn (mut v Vec4[T]) zero() {
	v.x = 0
	v.y = 0
	v.z = 0
	v.w = 0
}

pub fn (mut v Vec4[T]) one() {
	v.x = 1
	v.y = 1
	v.z = 1
	v.w = 1
}

pub fn (v Vec4[T]) copy() Vec4[T] {
	return Vec4[T]{v.x, v.y, v.z, v.w}
}

pub fn (mut v Vec4[T]) from(u Vec4[T]) {
	v.x = u.x
	v.y = u.y
	v.z = u.z
	v.w = u.w
}

pub fn (mut v Vec4[T]) from_vec2(u Vec2[T]) {
	v.x = u.x
	v.y = u.y
	v.z = 0
	v.w = 0
}

pub fn (v Vec4[T]) as_vec2() Vec2[T] {
	return Vec2[T]{v.x, v.y}
}

pub fn (mut v Vec4[T]) from_vec3(u Vec3[T]) {
	v.x = u.x
	v.y = u.y
	v.z = u.z
	v.w = 0
}

pub fn (v Vec4[T]) as_vec3() Vec3[T] {
	return Vec3[T]{v.x, v.y, v.z}
}

//
// Addition
//
// + operator overload. Adds two vectors
pub fn (v1 Vec4[T]) + (v2 Vec4[T]) Vec4[T] {
	return Vec4[T]{v1.x + v2.x, v1.y + v2.y, v1.z + v2.z, v1.w + v2.w}
}

pub fn (v Vec4[T]) add(u Vec4[T]) Vec4[T] {
	return Vec4[T]{v.x + u.x, v.y + u.y, v.z + u.z, v.w + u.w}
}

/*
pub fn (v Vec4[T]) add_vec2(u Vec2) Vec4[T] {
	return Vec4[T]{v.x + u.x, v.y + u.y, 0, 0}
}
*/
pub fn (v Vec4[T]) add_f64(scalar f64) Vec4[T] {
	return Vec4[T]{v.x + scalar, v.y + scalar, v.z + scalar, v.w + scalar}
}

pub fn (v Vec4[T]) add_f32(scalar f32) Vec4[T] {
	return Vec4[T]{v.x + scalar, v.y + scalar, v.z + scalar, v.w + scalar}
}

pub fn (mut v Vec4[T]) plus(u Vec4[T]) {
	v.x += u.x
	v.y += u.y
	v.z += u.z
	v.w += u.w
}

pub fn (mut v Vec4[T]) plus_f64(scalar f64) {
	v.x += scalar
	v.y += scalar
	v.z += scalar
	v.w += scalar
}

pub fn (mut v Vec4[T]) plus_f32(scalar f32) {
	v.x += scalar
	v.y += scalar
	v.z += scalar
	v.w += scalar
}

//
// Subtraction
//
pub fn (v1 Vec4[T]) - (v2 Vec4[T]) Vec4[T] {
	return Vec4[T]{v1.x - v2.x, v1.y - v2.y, v1.z - v2.z, v1.w - v2.w}
}

pub fn (v Vec4[T]) sub(u Vec4[T]) Vec4[T] {
	return Vec4[T]{v.x - u.x, v.y - u.y, v.z - u.z, v.w - u.w}
}

pub fn (v Vec4[T]) sub_f64(scalar f64) Vec4[T] {
	return Vec4[T]{v.x - scalar, v.y - scalar, v.z - scalar, v.w - scalar}
}

pub fn (mut v Vec4[T]) subtract(u Vec4[T]) {
	v.x -= u.x
	v.y -= u.y
	v.z -= u.z
	v.w -= u.w
}

pub fn (mut v Vec4[T]) subtract_f64(scalar f64) {
	v.x -= scalar
	v.y -= scalar
	v.z -= scalar
	v.w -= scalar
}

//
// Multiplication
//
pub fn (v1 Vec4[T]) * (v2 Vec4[T]) Vec4[T] {
	return Vec4[T]{v1.x * v2.x, v1.y * v2.y, v1.z * v2.z, v1.w * v2.w}
}

pub fn (v Vec4[T]) mul(u Vec4[T]) Vec4[T] {
	return Vec4[T]{v.x * u.x, v.y * u.y, v.z * u.z, v.w * u.w}
}

pub fn (v Vec4[T]) mul_f64(scalar f64) Vec4[T] {
	return Vec4[T]{v.x * scalar, v.y * scalar, v.z * scalar, v.w * scalar}
}

pub fn (mut v Vec4[T]) multiply(u Vec4[T]) {
	v.x *= u.x
	v.y *= u.y
	v.z *= u.z
	v.w *= u.w
}

pub fn (mut v Vec4[T]) multiply_f64(scalar f64) {
	v.x *= scalar
	v.y *= scalar
	v.z *= scalar
	v.w *= scalar
}

//
// Division
//
pub fn (v1 Vec4[T]) / (v2 Vec4[T]) Vec4[T] {
	return Vec4[T]{v1.x / v2.x, v1.y / v2.y, v1.z / v2.z, v1.w / v2.w}
}

pub fn (v Vec4[T]) div(u Vec4[T]) Vec4[T] {
	return Vec4[T]{v.x / u.x, v.y / u.y, v.z / u.z, v.w / u.w}
}

pub fn (v Vec4[T]) div_f64(scalar f64) Vec4[T] {
	return Vec4[T]{v.x / scalar, v.y / scalar, v.z / scalar, v.w / scalar}
}

pub fn (mut v Vec4[T]) divide(u Vec4[T]) {
	v.x /= u.x
	v.y /= u.y
	v.z /= u.z
	v.w /= u.w
}

pub fn (mut v Vec4[T]) divide_f64(scalar f64) {
	v.x /= scalar
	v.y /= scalar
	v.z /= scalar
	v.w /= scalar
}

/*
TODO
//
// Utility
//
pub fn (v Vec4[T]) length() f64 {
	if v.x == 0 && v.y == 0 { return 0.0 }
	return math.sqrt((v.x*v.x) + (v.y*v.y))
}
*/
pub fn (v Vec4[T]) dot(u Vec4[T]) T {
	return T((v.x * u.x) + (v.y * u.y) + (v.z * u.z) + (v.w * u.w))
}

/*
// unit return this vector's unit vector
pub fn (v Vec4[T]) unit() Vec4[T] {
	length := v.length()
	return Vec4[T]{ v.x/length, v.y/length }
}

pub fn (v Vec4[T]) perp() Vec4[T] {
	return Vec4[T]{ -v.y, v.x }
}

// perpendicular return the perpendicular vector of this
pub fn (v Vec4[T]) perpendicular(u Vec4[T]) Vec4[T] {
	return v - v.project(u)
}

// project returns the projected vector
pub fn (v Vec4[T]) project(u Vec4[T]) Vec4[T] {
	percent := v.dot(u) / u.dot(v)
	return u.mul_f64(percent)
}
*/
// eq returns a bool indicating if the two vectors are equal
pub fn (v Vec4[T]) eq(u Vec4[T]) bool {
	return v.x == u.x && v.y == u.y && v.z == u.z && v.w == u.w
}

/*
// eq_epsilon returns a bool indicating if the two vectors are equal within epsilon
pub fn (v Vec4[T]) eq_epsilon(u Vec4[T]) bool {
	return v.x.eq_epsilon(u.x) && v.y.eq_epsilon(u.y)
}
*/
// eq_approx will return a bool indicating if vectors are approximately equal within the tolerance
pub fn (v Vec4[T]) eq_approx(u Vec4[T], tolerance f64) bool {
	diff_x := math.abs(v.x - u.x)
	diff_y := math.abs(v.y - u.y)
	diff_z := math.abs(v.z - u.z)
	diff_w := math.abs(v.w - u.w)
	if diff_x <= tolerance && diff_y <= tolerance && diff_z <= tolerance && diff_w <= tolerance {
		return true
	}

	max_x := math.max(math.abs(v.x), math.abs(u.x))
	max_y := math.max(math.abs(v.y), math.abs(u.y))
	max_z := math.max(math.abs(v.z), math.abs(u.z))
	max_w := math.max(math.abs(v.w), math.abs(u.w))
	if diff_x < max_x * tolerance && diff_y < max_y * tolerance && diff_z < max_z * tolerance
		&& diff_w < max_w * tolerance {
		return true
	}
	return false
}

// is_approx_zero will return a bool indicating if this vector is zero within tolerance
pub fn (v Vec4[T]) is_approx_zero(tolerance f64) bool {
	if math.abs(v.x) <= tolerance && math.abs(v.y) <= tolerance && math.abs(v.z) <= tolerance
		&& math.abs(v.w) <= tolerance {
		return true
	}
	return false
}

/*
// eq_f64 returns a bool indicating if the x and y both equals the scalar
pub fn (v Vec4[T]) eq_f64(scalar f64) bool {
	return v.x == scalar && v.y == scalar
}

// eq_f32 returns a bool indicating if the x and y both equals the scalar
pub fn (v Vec4[T]) eq_f32(scalar f32) bool {
	return v.eq_f64(f64(scalar))
}v.y /= scalar

// distance returns the distance between the two vectors
pub fn (v Vec4[T]) distance(u Vec4[T]) f64 {
	return math.sqrt( (v.x-u.x) * (v.x-u.x) + (v.y-u.y) * (v.y-u.y) )
}

// manhattan_distance returns the Manhattan distance between the two vectors
pub fn (v Vec4[T]) manhattan_distance(u Vec4[T]) f64 {
	return math.fabs(v.x-u.x) + math.fabs(v.y-u.y)
}

// angle_between returns the angle in radians between the two vectors
pub fn (v Vec4[T]) angle_between(u Vec4[T]) f64 {
	return math.atan2( (v.y-u.y), (v.x-u.x) )
}

// angle returns the angle in radians of the vector
pub fn (v Vec4[T]) angle() f64 {
	return math.atan2(v.y, v.x)
}
*/

// abs will set x and y values to their absolute values
pub fn (mut v Vec4[T]) abs() {
	if v.x < 0 {
		v.x = math.abs(v.x)
	}
	if v.y < 0 {
		v.y = math.abs(v.y)
	}
	if v.z < 0 {
		v.z = math.abs(v.z)
	}
	if v.w < 0 {
		v.w = math.abs(v.w)
	}
}

// clean removes all the raw zeros
pub fn (v Vec4[T]) clean(tolerance f64) Vec4[T] {
	mut r := v.copy()
	if math.abs(v.x) < tolerance {
		r.x = 0
	}
	if math.abs(v.y) < tolerance {
		r.y = 0
	}
	if math.abs(v.z) < tolerance {
		r.z = 0
	}
	if math.abs(v.w) < tolerance {
		r.w = 0
	}
	return r
}

// inv returns the reciprocal of the vector
pub fn (v Vec4[T]) inv() Vec4[T] {
	return Vec4[T]{
		x: if v.x != 0 { 1.0 / v.x } else { 0 }
		y: if v.y != 0 { 1.0 / v.y } else { 0 }
		z: if v.z != 0 { 1.0 / v.z } else { 0 }
		w: if v.w != 0 { 1.0 / v.w } else { 0 }
	}
}

// mod returns module of the vector xyzw
pub fn (v Vec4[T]) mod() T {
	return T(math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z + v.w * v.w))
}

// mod_xyz returns module for 3d vector xyz, w ignored
pub fn (v Vec4[T]) mod_xyz() T {
	return T(math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z))
}

// normalize normalizes the vector
pub fn (v Vec4[T]) normalize() Vec4[T] {
	m := v.mod()
	if m == 0 {
		return vec4[T](0, 0, 0, 0)
	}
	return Vec4[T]{
		x: v.x * (1 / m)
		y: v.y * (1 / m)
		z: v.z * (1 / m)
		w: v.w * (1 / m)
	}
}

//  normalize normalizes only the xyz components, w is set to 0
pub fn (v Vec4[T]) normalize_xyz() Vec4[T] {
	m := v.mod_xyz()
	if m == 0 {
		return vec4[T](0, 0, 0, 0)
	}
	return Vec4[T]{
		x: v.x * (1 / m)
		y: v.y * (1 / m)
		z: v.z * (1 / m)
		w: 0
	}
}

// sum returns a sum of all the elements
pub fn (v Vec4[T]) sum() T {
	return v.x + v.y + v.z + v.w
}

// cross returns the cross product of v and u's xyz components
pub fn (v Vec4[T]) cross(u Vec4[T]) Vec4[T] {
	return Vec4[T]{
		x: (v.y * u.z) - (v.z * u.y)
		y: (v.z * u.x) - (v.x * u.z)
		z: (v.x * u.y) - (v.y * u.x)
		w: 0
	}
}
