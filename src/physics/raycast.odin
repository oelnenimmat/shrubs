/*
Note(Leo): Currently, hits when t < 0 are disregarded, but in principle there are no reasons
to really do this. But it is conventional for now, so be mindful if changing that

All xxx_intersect functions should return hit : bool and info : RayHitInfo and only return hit = true
if the hit is inside the ray's range i.e between 0 and ray.length. To cast "infinite" ray, set ray.length
to F32_MAX
*/

package physics

import "core:math"
import "core:math/linalg"

// import "../graphics/debug"

Ray :: struct {
	start 		: vec3,
	direction 	: vec3,
	length 		: f32,
}

RayHitInfo :: struct {
	point 		: vec3,
	normal 		: vec3,
	distance 	: f32,
}

empty_ray_hit_info :: RayHitInfo {0, 0, f32(math.F32_MAX)}

/*
raycast :: proc(p : ^Physics, ray : Ray) -> (hit := false, info := empty_ray_hit_info) {
		
	ray_end := ray.start + ray.direction * ray.length
	ray_aabb := AABB_from_bounds(
		(ray.start + ray_end) / 2,
		linalg.abs((ray_end - ray.start) / 2),
	)

	collision_indices := get_aabb_collisions(p, ray_aabb)

	for i in collision_indices {
		// todo(Leo): make not partial, all colliders need to dealt with
		current_hit := false
		current_info := empty_ray_hit_info

		switch c in p.submitted_colliders[i] {
			case BoxCollider: 		current_hit, current_info = ray_box_intersect(c, ray)
			case TriangleCollider:	current_hit, current_info = ray_triangle_intersect(c, ray)
			case SphereCollider:	current_hit, current_info = ray_sphere_intersect(c, ray)
			case CapsuleCollider:	current_hit, current_info = ray_capsule_intersect(c, ray)

			case HeightfieldCollider:
				cc := c
				triangles := heightfield_collider_generate_triangles(&cc, ray_aabb, context.temp_allocator)
				for t in triangles {
					hit, info := ray_triangle_intersect(t, ray)
					if hit && info.distance < current_info.distance {
						current_hit = true
						current_info = info
					}
				}
		}

		if current_hit && current_info.distance < info.distance {
			hit = true
			info = current_info
		}
	}

	return hit, info
}
*/

// ray_triangle_intersect :: proc(tc : TriangleCollider, ray : Ray) -> (hit := false, normal : vec3, distance : f32) {
ray_triangle_intersect :: proc(tc : TriangleCollider, ray : Ray) -> (hit := false, info := empty_ray_hit_info) {
	// using linalg
	dot 		:: linalg.dot
	cross 		:: linalg.cross
	normalize 	:: linalg.normalize

	v01 := tc.points[1] - tc.points[0]
	v02 := tc.points[2] - tc.points[0]

	normal 			:= normalize(cross(v01, v02))
	point_in_plane 	:= tc.points[0] 

	// t from ray.start to the plane along ray.direction
	// assert(abs(1 - linalg.length(ray_direction)) < 0.0001) // at least almost unit length
	// todo(Leo): should we assume unit length ray.direction
	t := (dot(normal, point_in_plane - ray.start)) / dot(normal, normalize(ray.direction))

	// return if behind or if too long
	if t < 0 || t > ray.length {
		return
	}

	intersect_point := ray.start + t * ray.direction

	v01 = v01
	v12 := tc.points[2] - tc.points[1]
	v20 := tc.points[0] - tc.points[2]

	p01 := intersect_point - tc.points[0]
	p12 := intersect_point - tc.points[1]
	p20 := intersect_point - tc.points[2]

	no_hit := false

	// todo(Leo): I kinda think this can be better
	if dot(cross(v01, p01), normal) < 0 { no_hit = true }
	if dot(cross(v12, p12), normal) < 0 { no_hit = true }
	if dot(cross(v20, p20), normal) < 0 { no_hit = true }

	hit = !no_hit

	if hit {
		info.point = intersect_point
		info.normal = normal if dot(normal, ray.direction) < 0 else -normal
		info.distance = t

		// debug.draw_line(tc.points[0], intersect_point, ColorRGB{1, 0, 0})
		// debug.draw_line(tc.points[1], intersect_point, ColorRGB{1, 0, 0})
		// debug.draw_line(tc.points[2], intersect_point, ColorRGB{1, 0, 0})
	}

	return
}

ray_box_intersect :: proc(bc : BoxCollider, ray : Ray) -> (hit := false, info : RayHitInfo) {
	using linalg

	world_to_local := matrix4_from_quaternion(quaternion_inverse(bc.rotation)) * matrix4_translate(-bc.position)

	local_ray_start 	:= matrix4_mul_point(world_to_local, ray.start)
	local_ray_direction := matrix4_mul_vector(world_to_local, normalize(ray.direction))

	hit, info = ray_aa_box_intersect(local_ray_start, local_ray_direction, 0, bc.size)

	if hit {
		local_to_world := matrix4_from_trs(bc.position, bc.rotation, 1)

		info.point = matrix4_mul_point(local_to_world, info.point)
		info.normal = matrix4_mul_vector(local_to_world, info.normal)
	}

	if hit && (info.distance < 0 || info.distance > ray.length) {
		hit = false
		info = empty_ray_hit_info
	}

	return
}

// https://www.scratchapixel.com/lessons/3d-basic-rendering/minimal-ray-tracer-rendering-simple-shapes/ray-box-intersection.html
// note(Leo): no support for rotations here. to use with rotated boxes, just rotate ray first to box local space
ray_aa_box_intersect :: proc(
	ray_start 		: vec3,
	ray_direction 	: vec3,
	box_position 	: vec3,
	box_size 		: vec3,
) -> (hit : bool, info : RayHitInfo) {

	b_min := box_position - box_size / 2
	b_max := box_position + box_size / 2

	t_min := (b_min - ray_start) / ray_direction
	t_max := (b_max - ray_start) / ray_direction

	t_min, t_max = linalg.min(t_min, t_max), linalg.max(t_min, t_max)

	if t_min.x > t_max.y || t_min.x > t_max.z {	return false, empty_ray_hit_info }
	if t_min.y > t_max.x || t_min.y > t_max.z {	return false, empty_ray_hit_info }
	if t_min.z > t_max.x || t_min.z > t_max.y {	return false, empty_ray_hit_info }

	normal : vec3
	distance : f32

	if t_min.x > t_min.y && t_min.x > t_min.z {
		normal = {1, 0, 0} if ray_direction.x < 0 else {-1, 0, 0}
		distance = t_min.x
	} else if t_min.y > t_min.z {
		normal = {0, 1, 0} if ray_direction.y < 0 else {0, -1, 0}
		distance = t_min.y
	} else {
		normal = {0, 0, 1} if ray_direction.z < 0 else {0, 0, -1}
		distance = t_min.z
	}

	// todo(Leo): the note below may be incorrect
	// note(Leo): t_min may be less than 0, in which case we are either inside the box or
	// completely on the other side. depending on the case, these may be valid outcomes, so
	// caller must make that distinction
	// return true, normal, distance
	point := ray_start + ray_direction * distance
	return true, {point, normal, distance}
}

