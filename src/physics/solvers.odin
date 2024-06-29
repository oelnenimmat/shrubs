package physics

import "core:fmt"
import "core:math"
import "core:math/linalg"

@(private="file")
Simplex :: struct {
	len 	: int,
	points 	: [4]vec3,
}

@(private="file")
simplex :: proc(points : ..vec3) -> Simplex {
	s : Simplex

	s.len = len(points)
	assert(s.len >= 1 && s.len <= 4)
	copy_slice(s.points[:s.len], points)
	return s
}

@(private="file")
simplex_put_first :: proc(s : ^Simplex, p : vec3) {
	assert(s.len < 4)

	temp 		:= s^
	copy_slice(s.points[1:s.len + 1], temp.points[:s.len])
	s.points[0] = p
	s.len 		+= 1
}

solve_gjk :: proc(a : ^$A, b : ^$B, initial_direction : vec3) -> (bool, Collision) {

	// support is in minkowski sum(difference) solution space
	support := gjk_get_support_point(a, b, initial_direction)

	points 		:= simplex(support)
	direction 	:= -support

	// kinda sanity check. Would not expect to hit this, but it happens still
	// todo(Leo): learn more
	MAX_ITERATIONS :: 20
	for _ in 0..<MAX_ITERATIONS {
		support = gjk_get_support_point(a, b, direction)

		if linalg.dot(support, direction) <= 0.0 {
			return false, {}
		}

		simplex_put_first(&points, support)

		done := false
		switch points.len {
			case 2:	gjk_process_line(&points, &direction)
			case 3: gjk_process_triangle(&points, &direction)
			case 4: done = gjk_process_tetrahedron(&points, &direction)
			case: panic("gjk went bad :(")
		}

		if done {
			return true, solve_epa(points, a, b)
		}
	}

	return false, {}
}

solve_gjk_only :: proc(a : ^$A, b : ^$B, initial_direction : vec3) -> bool {

	// support is in minkowski sum(difference) solution space
	support := gjk_get_support_point(a, b, initial_direction)

	points 		:= simplex(support)
	direction 	:= -support

	// kinda sanity check. Would not expect to hit this, but it happens still
	// todo(Leo): learn more
	MAX_ITERATIONS :: 20
	for _ in 0..<MAX_ITERATIONS {
		support = gjk_get_support_point(a, b, direction)

		if linalg.dot(support, direction) <= 0.0 {
			return false
		}

		simplex_put_first(&points, support)

		done := false
		switch points.len {
			case 2:	gjk_process_line(&points, &direction)
			case 3: gjk_process_triangle(&points, &direction)
			case 4: done = gjk_process_tetrahedron(&points, &direction)
			case: panic("gjk went bad :(")
		}

		if done {
			return true
		}
	}

	return false
}

@(private="file")
gjk_get_support_point :: proc(a: ^$A, b: ^$B, direction: vec3) -> vec3 {
	return get_support_point(a, direction) - get_support_point(b, -direction)
}

@(private="file")
gjk_same_direction :: proc(a, b: vec3) -> bool {
	return linalg.dot(a, b) > 0
}

@(private="file")
gjk_process_line :: proc(s : ^Simplex, direction : ^vec3) {
	cross :: linalg.cross

	a := s.points[0]
	b := s.points[1]

	ab 			:= b - a
	to_origin 	:= 0 - a

	// if b is closer to origin than a
	if gjk_same_direction(ab, to_origin) {
		direction^ = cross(cross(ab, to_origin), ab)

	// if a is closer to orign than b
	} else {
		s^ 			= simplex(a)
		direction^ 	= to_origin
	}
}

@(private="file")
gjk_process_triangle :: proc(s : ^Simplex, direction : ^vec3) {
	cross :: linalg.cross

	a := s.points[0]
	b := s.points[1]
	c := s.points[2]

	// edges
	ab := b - a
	ac := c - a
	
	// normal
	abc := cross(ab, ac)

	to_origin := 0 - a

	if gjk_same_direction(cross(abc, ac), to_origin) {
		if gjk_same_direction(ac, to_origin) {
			s^ 			= simplex(a,c)
			direction^ 	= cross(cross(ac, to_origin), ac)
		} else {
			s^ = simplex(a,b)
			gjk_process_line(s, direction)
		}
	} else {
		if gjk_same_direction(cross(ab, abc), to_origin) {
			s^ = simplex(a,b)
			gjk_process_line(s, direction)
		} else {
			if gjk_same_direction(abc, to_origin) {
				direction^ = abc
			} else {
				s^ 			= simplex(a, c, b)
				direction^ 	= -abc
			}
		}
	}
}

@(private="file")
gjk_process_tetrahedron :: proc(s : ^Simplex, direction : ^vec3) -> bool {

	cross :: linalg.vector_cross3

	a := s.points[0]
	b := s.points[1]
	c := s.points[2]
	d := s.points[3]

	// edges on tetrahedron
	ab := b - a
	ac := c - a
	ad := d - a

	to_origin := 0 - a

	// normals on triangles
	abc := cross(ab, ac)
	acd := cross(ac, ad)
	adb := cross(ad, ab)

	// normal points to origin (is same direction as vector to origin) then the origin is outside
	// (so no collision) to that direction. Continue by looking into that direction

	if gjk_same_direction(abc, to_origin) {
		s^ = simplex(a, b, c)
		gjk_process_triangle(s, direction)
		
		return false
	} 

	if gjk_same_direction(acd, to_origin) {
		s^ = simplex(a, c, d)
		gjk_process_triangle(s, direction)
		
		return false
	} 

	if gjk_same_direction(adb, to_origin) {
		s^ = simplex(a, d, b)
		gjk_process_triangle(s, direction)
		
		return false
	}

	return true
}

@(private="file")
solve_epa :: proc(s : Simplex, a : ^$A, b : ^$B) -> Collision {

	// todo(Leo): instead of just using the temp_allocator, get some arena or something
	// and store temp_allocator offset here and return to it on exit
	polytope := make([dynamic]vec3, 0, 20, context.temp_allocator)
	append(&polytope, s.points[0], s.points[1], s.points[2], s.points[3])

	// todo(Leo): for some reason, append_elems does not work, with error:
	// C:\Users\Leo\.odin\Odin\src\llvm_backend_proc.cpp(72): Assertion Failure: `entity->flags & EntityFlag_ProcBodyChecked` append_elems :: proc(^[dynamic]int, ..int, Source_Code_Location) -> int
	// that's why we use single element appends only, except above, where it works.
	// multi element appends did work before adding parapoly parameters
	faces := make([dynamic]int, 0, 100, context.temp_allocator)
	append(&faces, 0)
	append(&faces, 1)
	append(&faces, 2)
	append(&faces, 0)
	append(&faces, 3)
	append(&faces, 1)
	append(&faces, 0)
	append(&faces, 2)
	append(&faces, 3)
	append(&faces, 1)
	append(&faces, 3)
	append(&faces, 2)
	// append(&faces,
	// 	0, 1, 2,
	// 	0, 3, 1,
	// 	0, 2, 3,
	// 	1, 3, 2,
	// )

	normals, closest_face_index := get_face_normals(polytope[:], faces[:])
	defer delete(normals)

	out_min_normal 		: vec3 = ---
	out_min_distance 	: f32 = ---

	EPSILON : f32 : 0.001

	// allocate these from arena thing too
	new_unique_edges 	:= make([dynamic]Edge)
	new_faces 			:= make([dynamic]int)

	defer delete(new_unique_edges)
	defer delete(new_faces)

	for {
		min_normal 		: vec3 = normals[closest_face_index].xyz
		min_distance 	:= normals[closest_face_index].w

		support 	:= gjk_get_support_point(a, b, min_normal)
		s_distance 	:= linalg.dot(min_normal, support)

		if abs(s_distance - min_distance) < EPSILON {
			out_min_normal 		= min_normal
			out_min_distance 	= min_distance
			break
		}

		// this seems to be super crucial, terminate if a duplicate support point is generated
		// though this could also mean, that the elements are not kept in the correct order and
		// we should actually test against the previous one
		done := false
		for v in polytope {
			if linalg.length(v - support) < EPSILON {
				done = true
				// break // do break here, but this also wasn't in the working reference implementation
			}
		}

		if done {
			out_min_normal 		= min_normal
			out_min_distance 	= min_distance
			break
		}

		clear(&new_unique_edges)

		for i := 0; i < len(normals); i += 1 {

			if gjk_same_direction(normals[i].xyz, support) {
				f := 3 * i

				add_if_unique(&new_unique_edges, faces[:], f + 0, f + 1)
				add_if_unique(&new_unique_edges, faces[:], f + 1, f + 2)
				add_if_unique(&new_unique_edges, faces[:], f + 2, f + 0)

				faces[f + 2] 	= pop(&faces)
				faces[f + 1] 	= pop(&faces)
				faces[f + 0] 	= pop(&faces)
				normals[i] 		= pop(&normals)

				i -= 1
			}
		}

		// todo(Leo): this relates to two breaks below. It has to do with us not finding any new solutions or something
		if len(new_unique_edges) == 0 {
			out_min_normal 		= min_normal
			out_min_distance 	= min_distance
			break
		}

		clear(&new_faces)

		for edge in new_unique_edges {
			append(&new_faces, edge.a)
			append(&new_faces, edge.b)
			append(&new_faces, len(polytope))
			// append(&new_faces, edge.a, edge.b, len(polytope))
		}

		// // todo(Leo): this is less suspicious than disabled break below
		// if len(new_faces) == 0 {
		// 	out_min_normal 		= min_normal
		// 	out_min_distance 	= min_distance
		// 	break
		// }

		append(&polytope, support)

		// "old" as in before new_faces
		old_min_distance : f32 = math.F32_MAX
		for _, i in normals {
			if normals[i].w < old_min_distance {
				old_min_distance 	= normals[i].w
				closest_face_index 	= i
			}
		}

		new_normals, new_min_face := get_face_normals(polytope[:], new_faces[:])
		defer delete(new_normals)

		// // todo(Leo): this is suspicious. I added it to solve rare issue where no new normals would be found
		// if len(new_normals) == 0 {
		// 	out_min_normal 		= min_normal
		// 	out_min_distance 	= min_distance
		// 	break
		// }

		if new_normals[new_min_face].w < old_min_distance {
			closest_face_index = len(normals) + new_min_face
		}

		for f in new_faces {
			append(&faces, f)
		}
		// append(&faces, ..new_faces[:])

		for n in new_normals {
			append(&normals, n)
		}
		// append(&normals, ..new_normals[:])

	}

	SKIN_WIDTH : f32 : 0.0001

	return {
		out_min_distance + SKIN_WIDTH,
		-linalg.normalize(out_min_normal),
		{ /* velocity here, but rn we dont have access to it so it is filled later */ }
	}
}

@(private="file")
Edge :: struct { 
	a : int, 
	b : int,
}

// todo(Leo): do not return dynamic array from normal allocator
@(private="file")
get_face_normals :: proc(polytope : []vec3, faces : []int) -> ([dynamic]vec4, int) {
	using linalg

	output_normals 	:= make([dynamic]vec4)
	min_face_index 	:= 0
	min_distance 	: f32 = math.F32_MAX

	for i := 0; i < len(faces); i += 3 {
		a := polytope[faces[i + 0]]
		b := polytope[faces[i + 1]]
		c := polytope[faces[i + 2]]

		ab := b - a
		ac := c - a

		normal := normalize(cross(ab, ac))
		distance := dot(normal, a) // is this really a distance

		if distance < 0.0 {
			normal = -normal
			distance = -distance
		}

		append(&output_normals, vec4	{ normal.x, normal.y, normal.z, distance })

		if distance < min_distance {
			min_face_index 	= i / 3
			min_distance 	= distance
		}
	}

	return output_normals, min_face_index
}

@(private="file")
add_if_unique :: proc (
	unique_edges 	: ^[dynamic]Edge,
	faces 			: []int,
	face_index_0	: int,
	face_index_1	: int,
) {
	f0 := faces[face_index_0]
	f1 := faces[face_index_1]

	// find if same edge already exists
	// apparently it must be in reverse position, if it is here
	reverse_index := -1
	for edge, i in unique_edges {
		if edge == { f1, f0 } {
			reverse_index = i
			break
		}
	}

	// reverse edge found, so either current edge or that are not unique
	if reverse_index >= 0 {
		// todo(Leo) maybe don't need to be ordered, but it was in the reference
		ordered_remove(unique_edges, reverse_index)
	} else {
		append(unique_edges, Edge { f0, f1 })
	}


}