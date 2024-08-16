package geom

/*
multiplication tests:
	rotor-rotor
	commutators
*/

import "core:testing"

import "core:math"
import "core:math/linalg"

EPSILON :: 1e-7

almost_same :: proc(a, b : $T, epsilon : f32 = EPSILON) -> bool {

	when T == Scalar || T == Trivector {
		a := f32(a)
		b := f32(b)

		return math.abs(a - b) < epsilon
	}

	when T == Vector || T == Bivector	 {
		diff 		:= linalg.abs(a - b)
		max_diff 	:= linalg.max(diff)

		return max_diff < epsilon
	}

	unreachable()
}

@test
rotate_test :: proc(t : ^testing.T) {
	
	{
		a := Vector {1, 0, 0}
		b := Vector {0, 1, 0}

		R := rotor_from_a_to_b(a, b)

		testing.expectf(t, R.scalar == math.cos_f32(45 * math.PI / 180), "Scalar: {}", R.scalar)
		testing.expectf(t, R.plane.z == math.sin_f32(45 * math.PI / 180), "Plane: {}", R.plane)

		// R := rotor_from_a_to_b(a, b)
		ap := rotate_vector(R, a)

		// value := 5
		testing.expectf(t, almost_same(ap, b), "Vector was not rotated correctly. b = {}, ap = {}, R = {}", b, ap, R)
	}

	{
		a := Vector {0, 1, 0}
		b := Vector {0, 0, 1}

		R := rotor_from_a_to_b(a, b)

		testing.expectf(t, R.scalar == math.cos_f32(45 * math.PI / 180), "Scalar: {}", R.scalar)
		testing.expectf(t, R.plane.x == math.sin_f32(45 * math.PI / 180), "Plane: {}", R.plane)

		// R := rotor_from_a_to_b(a, b)
		ap := rotate_vector(R, a)

		// value := 5
		testing.expectf(t, almost_same(ap, b), "Vector was not rotated correctly. b = {}, ap = {}, R = {}", b, ap, R)
	}
}

@test
normalize_test :: proc(t : ^testing.T) {
	a := Vector{2, 0, 0}
	ap := normalize_vector(a)

	testing.expectf(t, ap == {1, 0, 0}, "Ill-normalized vector: {}", ap)
}

@test 
rotor_test :: proc(t : ^testing.T) {
	R := rotor_from_a_to_b({1, 0, 0}, {1, 0, 0})

	testing.expect(t, almost_same(R.scalar, 1))
	testing.expect(t, almost_same(R.plane, Bivector{0, 0, 0}))

	R = rotor_plane_angle(outer({1, 0, 0}, {0, 1, 0}), math.PI/2)
	testing.expectf(t, almost_same(R.scalar, 0), "Scalar: {}", R.scalar)
	testing.expectf(t, almost_same(R.plane.z, 1), "Plane: {}", R.plane)
}

@test
stability :: proc(t : ^testing.T) {
	iterations := 1000

	plane 	:= outer(Vector{1, 0, 0}, Vector{0, 1, 0})
	R 		:= rotor_plane_angle(plane, 0.1)
	v 		:= normalize_vector({1,1,1})

	for i in 0..<iterations {
		v = rotate_vector(R, v)
		l := magnitude(v)

		if !almost_same(l, 1, 1e-4) {
			testing.logf(t, "Rotated magnitude wrong after {} iterations: {} (v = {})", i, l, v)
			testing.fail_now(t)
		}
	}
}