package geom

import "core:math"

sqrt :: math.sqrt
abs :: math.abs

Scalar 		:: f32
Vector 		:: distinct [3]f32 // e1, e2, e3,
Bivector 	:: distinct [3]f32 // Ie1, Ie2, Ie3 == e2e3, e3e1, e1e2
Trivector 	:: distinct f32

Rotor :: struct {
	scalar 	: Scalar,
	plane 	: Bivector,
}
#assert(size_of(Rotor) == 16)

reverse_rotor :: proc(R : Rotor) -> Rotor {
	return {R.scalar, -R.plane}
}

reverse :: proc {
	reverse_rotor
}

// In 3d vector and bivector inner products are numerically same
inner_vector_vector :: proc(a, b : Vector) -> Scalar {
	return a[0]*b[0] + a[1]*b[1] + a[2]*b[2]
}

inner_bivector_bivector :: proc(a, b : Bivector) -> Scalar {
	return a[0]*b[0] + a[1]*b[1] + a[2]*b[2]
}

inner :: proc {
	inner_vector_vector,
	inner_bivector_bivector,
}

outer_vector_vector :: proc(a, b : Vector) -> Bivector {
	return {
		a[1]*b[2] - a[2]*b[1],
		a[2]*b[0] - a[1]*b[0],
		a[0]*b[1] - a[0]*b[2],
	}
}

outer :: proc {
	outer_vector_vector,
}

commutator_bivector_bivector :: proc(a, b : Bivector) -> Bivector {
	// Essentially a cross product/determinant/etc. In 3d numerically same as 
	// outer product, but conseptually different, since in 3d there are three vectors
	// and three bivectors, and complement of bivector is vector.
	return {
		a[1] * b[2] - a[2] * b[1],
		a[2] * b[0] - a[0] * b[2],
		a[0] * b[1] - a[1] * b[0],
	}
}

commutator :: proc {
	commutator_bivector_bivector,
}

rotate_vector :: proc(R : Rotor, v : Vector) -> Vector {
	// return RvR*
	// R := transmute([4]f32)R	
	r0 := R.scalar
	r1 := R.plane[0]
	r2 := R.plane[1]
	r3 := R.plane[2]

	v1 := v[0]
	v2 := v[1]
	v3 := v[2]

	return {
		(r0*r0 + r1*r1 - r2*r2 - r3*r3)*v1 + 2*(r1*r2 + r0*r3)*v2 + 2*(r1*r3 - r0*r2)*v3,
		(r0*r0 - r1*r1 + r2*r2 - r3*r3)*v2 + 2*(r2*r3 + r0*r1)*v3 + 2*(r2*r1 - r0*r3)*v1,
		(r0*r0 - r1*r1 - r2*r2 + r3*r3)*v3 + 2*(r3*r1 + r0*r2)*v1 + 2*(r3*r2 - r0*r1)*v2,
	}

	// return {
	// 	(r0*r0 + r1*r1 - r2*r2 - r3*r3)*v1 + 2*(r1*r2 - r3*r0)*v2 + 2*(r1*r3 + r2*r0)*v3,
	// 	2*(r2*r1 + r0*r3)*v1 + (r0*r0 - r1*r1 + r2*r2 - r3*r3)*v2 + 2*(r2*r3 - r0*r1)*v3,
	// 	2*(r3*r1 - r0*r2)*v1 + 2*(r3*r2 + r0*r1)*v2 + (r0*r0 - r1*r1 - r2*r2 + r3*r3)*v3,
	// }
}

// rotate_bivector :: proc(R : Rotor, B : Bivector) -> Bivector {
// 	return R.scalar * R.scalar * B -
// 			2 * R.scalar * commutator(R.plane, B) -
// 			inner(R.plane, B) * R.plane
// }

rotor_from_a_to_b :: proc(a, b : Vector) -> Rotor {
	/*
	h = (a + b) / |a + b|
	R = hb = h.b + h^b
	*/

	// Todo(Leo): see if could skip half, and just divide or smth the inner and outer products

	a := normalize_vector(a)
	b := normalize_vector(b)

	// Todo(Leo): lets hope its not that a == -b
	half := normalize(a + b)

	return {
		scalar 	= inner(half, b),
		plane 	= -outer(half, b),
	}
}

rotor_plane_angle :: proc(plane : Bivector, angle : f32) -> Rotor {
	
	// Rotors are used from two sides, both rotating the specified amount
	// thus half angle
	half_angle := angle / 2

	return {
		scalar 	= math.cos(half_angle),
		plane 	= -math.sin(half_angle) * normalize(plane),
	}
}

magnitude_vector :: proc(v : Vector) -> f32 {
	return sqrt(v[0]*v[0] + v[1]*v[1] + v[2]*v[2])
}

magnitude_bivector :: proc(b : Bivector) -> f32 {
	return sqrt(b[0]*b[0] + b[1]*b[1] + b[2]*b[2])
}

magnitude :: proc {
	magnitude_vector,
	magnitude_bivector,
}

normalize_vector :: proc(v : Vector) -> Vector {
	return v / magnitude(v)
}

normalize_bivector :: proc(v : Bivector) -> Bivector {
	return v / magnitude(v)
}

normalize :: proc {
	normalize_vector,
	normalize_bivector,
}

mul_rotor_rotor :: proc(a, b : Rotor) -> Rotor {
	return {
		scalar 	= a.scalar * b.scalar + inner(a.plane, b.plane),
		plane 	= (a.scalar * b.plane + b.scalar * a.plane) + commutator(b.plane, a.plane)
		
		// scalar = a.scalar * b.scalar + a.plane.x * b.plane.x + a.plane.y * b.plane.y + a.plane.z * b.plane.z,
		// plane = {
		// 	a.scalar * b.plane.x + b.scalar * a.plane.x + a.plane.y * b.plane.z - a.plane.z * b.plane.y,
		// 	a.scalar * b.plane.y + b.scalar * a.plane.y + a.plane.z * b.plane.x - a.plane.x * b.plane.z,
		// 	a.scalar * b.plane.z + b.scalar * a.plane.z + a.plane.x * b.plane.y - a.plane.y * b.plane.x,
		// }
	}
}

mul :: proc {
	mul_rotor_rotor,
}