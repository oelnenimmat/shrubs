package physics

/*
struct AABB and trait Collider wouldn't need to be pub (exceptc pub (in super)), but
since we implement them for pub types, they need to (this maybe could be fixed). But
then this way anyone can make up new kinds of colliders that should just work
*/

import "core:runtime"
import "core:fmt"
import "core:math"
import "core:math/linalg"

// import "../engine"
// import "../graphics/debug"

// these two groups are what matter
get_aabb :: proc {
	get_aabb_box_collider,
	get_aabb_capsule_collider,
	get_aabb_sphere_collider,
	triangle_collider_aabb,
	// heightfield_collider_aabb,
}

get_support_point :: proc {
	get_support_point_box_collider,
	get_support_point_capsule_collider,
	get_support_point_sphere_collider,
	triangle_collider_get_support_point,
}

// there are ones in game too so change everything if you do
RIGHT 	:: vec3{1, 0, 0}
FORWARD :: vec3{0, 1, 0}
UP 		:: vec3{0, 0, 1}

AABB :: struct {
	min : vec3,
	max : vec3,
}

AABB_from_bounds :: proc(center : vec3, extent : vec3) -> AABB {
	return AABB {
		min = center - extent,
		max = center + extent,
	}
}

AABB_from_min_and_max :: proc(min : vec3, max : vec3) -> AABB {
	return { min, max }
}

// ----------------------------------------------------------------------------

//
// BOX COLLIDER
//

BoxCollider :: struct {
	position : vec3,
	rotation : quaternion,
	size : vec3,
}

// Todo(Leo): resulting array seems to be used only as an unmodified reference, maybe
// could just store this in struct itself and pass around as a slice?
// return 8 vectors on stack, should be ok
box_collider_get_corners :: proc(using self : ^BoxCollider) -> [8] vec3 {
	extent := size / 2
	return {
		{-extent.x, -extent.y, -extent.z},
		{extent.x, -extent.y, -extent.z},
		{-extent.x, extent.y, -extent.z},
		{extent.x, extent.y, -extent.z},

		{-extent.x, -extent.y, extent.z},
		{extent.x, -extent.y, extent.z},
		{-extent.x, extent.y, extent.z},
		{extent.x, extent.y, extent.z},
	}
}

get_aabb_box_collider :: proc(using self : ^BoxCollider) -> AABB {
	corners := box_collider_get_corners(self)

	// Rotate all corners to find the extent. Unrotated shape is symmetric about (at least)
	// the origin and so will be the rotated shape and therefore the extent can be deciphered
	// from positive max values. Depending on the rotation however, any corner can end up being
	// the most positive so we cannot skip any.

	bounds_extent : vec3 = 0
	for _, i in corners {
		corner := linalg.quaternion_mul_vector3(rotation, corners[i])

		bounds_extent.x = max(bounds_extent.x, corner.x)
		bounds_extent.y = max(bounds_extent.y, corner.y)
		bounds_extent.z = max(bounds_extent.z, corner.z)
	}

	return AABB_from_bounds(position, bounds_extent)
}

get_support_point_box_collider :: proc(using self :^BoxCollider, direction : vec3) -> vec3 {
	using linalg

	// support point is the point farthest in the direction
	// considering corners is enough, edges cannot be any further than them
	corners := box_collider_get_corners(self)
	direction := quaternion_mul_vector3(
		quaternion_inverse(rotation), 
		direction,
	)

	// considered in local space
	biggest_dot 	:= dot(corners[0], direction)
	farthest_point 	:= corners[0]

	for i in 1..<8 {
		current_dot := dot(corners[i], direction)
		if current_dot > biggest_dot {
			biggest_dot 	= current_dot
			farthest_point 	= corners[i]
		}
	}

	// move farthest_point to global space
	farthest_point = quaternion_mul_vector3(rotation, farthest_point) + position
	return farthest_point
}

// ----------------------------------------------------------------------------

//
// SPHERE COLLIDER
//

SphereCollider :: struct {
	position 	: vec3,
	radius 		: f32,
}

get_aabb_sphere_collider :: proc(sc : ^SphereCollider) -> AABB {
	return AABB_from_bounds (sc.position, sc.radius)
}

get_support_point_sphere_collider :: proc(sc : ^SphereCollider, direction : vec3) -> vec3 {
	// sphere is simple, farthest point is on surface (radius away from position) to the direction
	return sc.position + linalg.normalize(direction) * sc.radius
}

/*
ray_sphere_intersect :: proc(sc : SphereCollider, ray : Ray) -> (hit := false, info := empty_ray_hit_info) {
	dot 		:: linalg.dot
	normalize 	:: linalg.normalize
	sqrt 		:: math.sqrt

	// move ray to sphere local space so we can treat sphere center as origin
	ray_local_start := ray.start - sc.position

	P := ray_local_start			// Point in local space
	d := normalize(ray.direction)	// direction in both spaces
	r := sc.radius 					// radius in both spaces

	// for quadratic formula
	a := dot(d, d) // = 1
	b := 2 * dot(P,d)
	c := dot(P, P) - r*r

	discriminant := b*b - 4*a*c

	// no result for imaginary roots needed
	if discriminant < 0 {
		return
	}

	t := (-b - sqrt(discriminant)) / 2*a

	if t < 0 || t > ray.length {
		return
	}

	hit = true

	local_point := ray_local_start + d * t

	info.point = sc.position + local_point
	info.normal = normalize(local_point)
	info.distance = t

	return
}

*/
// ----------------------------------------------------------------------------

//
// CAPSULE COLLIDER
//

CapsuleCollider :: struct {
	position 	: vec3,
	radius 		: f32,
	height 		: f32,
}

get_aabb_capsule_collider :: proc(using self : ^CapsuleCollider) -> AABB {
	return AABB_from_bounds (position, { radius, radius, height / 2})
}

get_support_point_capsule_collider :: proc(using self : ^CapsuleCollider, direction : vec3) -> vec3 {
	// between p0 and p1 (inclusive) all points are equally far into the direction, so either one
	// of the two is good. Beyond those, it is same as with sphere.

	p0 := position - UP * (height / 2 - radius)
	p1 := position + UP * (height / 2 - radius)

	d0 := linalg.dot(p0, direction)
	d1 := linalg.dot(p1, direction)

	p := p0 if d0 > d1 else p1

	return p + linalg.normalize(direction) * radius
}

/*
ray_capsule_intersect :: proc(cc : CapsuleCollider, ray : Ray) -> (hit := false, info := empty_ray_hit_info) {
	// MEGA TODO
	return
}
*/
//
// TRIANGLE COLLIDER
// 

TriangleCollider :: struct {
	position 	: vec3, // todo(Leo): redundant, used for stupidity
	points 		: [3]vec3, // in world space
}

triangle_collider_aabb :: proc(using self : ^TriangleCollider) -> AABB {
	bounds_min := points[0]
	bounds_max := points[0]

	for i in 1..<3 {
		bounds_min = {
			min(bounds_min.x, points[i].x),
			min(bounds_min.y, points[i].y),
			min(bounds_min.z, points[i].z),
		}
		bounds_max = {
			max(bounds_max.x, points[i].x),
			max(bounds_max.y, points[i].y),
			max(bounds_max.z, points[i].z),
		}
	}

	return AABB_from_min_and_max(bounds_min, bounds_max)
}

triangle_collider_get_support_point :: proc(using self : ^TriangleCollider, direction : vec3) -> vec3 {
	farthest_point 	:= points[0]
	farthest_dot 	:= linalg.dot(points[0], direction)

	for i in 1..<3 {
		dot := linalg.dot(points[i], direction)
		if dot > farthest_dot {
			farthest_point 	= points[i]
			farthest_dot 	= dot
		}
	}

	return farthest_point
}
/*
HeightfieldCollider :: struct {
	using hf : engine.Heightfield,
	position : vec3,
}

heightfield_collider_aabb :: proc(hfc : ^HeightfieldCollider) -> AABB {
	min_bounds := vec3 {
		-f32(hfc.size[0]) * hfc.scale / 2,
		-f32(hfc.size[1]) * hfc.scale / 2,
		hfc.min_height,
	} + hfc.position
	max_bounds := vec3 {
		f32(hfc.size[0]) * hfc.scale / 2,
		f32(hfc.size[1]) * hfc.scale / 2,
		hfc.max_height,
	} + hfc.position

	return AABB_from_min_and_max(min_bounds, max_bounds)
}

heightfield_collider_generate_triangles :: proc(hfc : ^HeightfieldCollider, target : AABB, allocator : runtime.Allocator) -> []TriangleCollider {
	
	// todo(Leo): draw aabb and "expanded to grid space" aabb for nice visualiztions

	// origin is at center, as is mesh's
	hfc_space_min := Vector2((target.min - hfc.position).xy)
	hfc_space_max := Vector2((target.max - hfc.position).xy)

	// intger coordinate space in height field map
	hw 	:= f32(hfc.size[0]) / 2 // half width
	hh 	:= f32(hfc.size[1]) / 2 // half height
	s 	:= hfc.scale 

	offset 			:= Vector2 { hw * s, hh * s }
	hfc_space_min 	= linalg.floor((hfc_space_min + offset) / s)
	hfc_space_max 	= linalg.ceil((hfc_space_max + offset) / s)

	// todo(Leo): how do floats behave if these are big enough so that the floor/ceil above dont return an exact integer?
	coord_min := [2]int{
		int(max(0, hfc_space_min.x)),
		int(max(0, hfc_space_min.y)),
	}

	coord_max := [2]int {
		min(int(hfc_space_max.x), hfc.size[0] - 1),
		min(int(hfc_space_max.y), hfc.size[1] - 1),
	}

	quad_counts 	:= coord_max - coord_min
	triangle_count 	:= quad_counts.x * quad_counts.y * 2
	triangles 		:= make([]TriangleCollider, triangle_count, allocator)

	for i := 0; i < len(triangles); i += 2 {
		x0 := (i / 2) % quad_counts.x + coord_min.x
		y0 := (i / 2) / quad_counts.x + coord_min.y

		x1 := x0 + 1
		y1 := y0 + 1

		v0 := x0 + y0 * hfc.size[0]
		v1 := x1 + y0 * hfc.size[0]
		v2 := x0 + y1 * hfc.size[0]
		v3 := x1 + y1 * hfc.size[0]

		p := []vec3 {
			vec3 { (f32(x0) - hw) * s, (f32(y0) - hh) * s, hfc.data[v0] } + hfc.position,
			vec3 { (f32(x1) - hw) * s, (f32(y0) - hh) * s, hfc.data[v1] } + hfc.position,
			vec3 { (f32(x0) - hw) * s, (f32(y1) - hh) * s, hfc.data[v2] } + hfc.position,
			vec3 { (f32(x1) - hw) * s, (f32(y1) - hh) * s, hfc.data[v3] } + hfc.position,
		}

		// Note(Leo): here we are defininf winding, and it must be same as with mesh generation
		// todo(Leo): make a function that is used in both that handles this consistently. especially
		// since maybe (probably) we want even triangle triangulation
		center_012 := (p[0] + p[1] + p[2]) / 3
		center_213 := (p[2] + p[1] + p[3]) / 3

		triangles[i + 0] = {center_012, {p[0], p[1], p[2]}}
		triangles[i + 1] = {center_213, {p[2], p[1], p[3]}}

		{
			COLOR :: ColorRGB{0, 0.6, 1}

			// debug.draw_line(p[0], p[1], COLOR)
			// debug.draw_line(p[1], p[2], COLOR)
			// debug.draw_line(p[2], p[0], COLOR)

			// debug.draw_line(p[2], p[1], COLOR)
			// debug.draw_line(p[1], p[3], COLOR)
			// debug.draw_line(p[3], p[2], COLOR)
		}
	}

	return triangles
}
*/
/*
PlaneCollider :: struct {
	point 		: vec3,
	normal 		: vec3,
	bounds_min 	: vec3,
	bounds_max 	: vec3,
}

plane_collider_aabb :: proc(using self : ^PlaneCollider) -> AABB {
	return AABB_from_min_and_max(bounds_min, bounds_max)
}

plane_collider_get_support_point :: proc(using self : ^PlaneCollider, direction : vec3) -> vec3 {
	// compute 4 corners
}
*/