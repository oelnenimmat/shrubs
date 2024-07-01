package physics

import "core:mem"
import "core:fmt"
import "core:runtime"
import "core:math"
import "core:math/linalg"

import "shrubs:common"
import "shrubs:debug"

vec2 	:: common.vec2
vec3 	:: common.vec3
vec4 	:: common.vec4
quaternion 	:: common.quaternion

matrix4_mul_point 		:: common.matrix4_mul_point
matrix4_mul_vector 		:: common.matrix4_mul_vector
matrix4_mul_rotation 	:: common.matrix4_mul_rotation

Collision :: struct {
	 depth 		: f32,		// distance to move the least amout to get untangled
	 direction 	: vec3, 	// direction to move the least amount to get untangled
	 // normal 	: vec3, 	// not necessarily same as the min move out direction
	 velocity 	: vec3,
	 tag 		: int,
}

// todo(Leo): for now, we usually don't need to loop submitted colliders, so it is okay
// to store them in a union in a heterocontainer, but maybe reconsider
// todo(Leo): also definetly don't always resubmit everything again avery frame
@private
SubmittedCollider :: union {
	BoxCollider,
	SphereCollider,
	CapsuleCollider,
	TriangleCollider,
	// HeightfieldCollider,
}

// Todo(Leo): this is singletong kinda thing, so no need for explicit struct type
// but the old implementation uses a pointer to this so keep it.
// Todo(Leo): counter argument: maybe keep like this for ease of porting to new projects
// like the project could instantiate using any memory allocation, and the "private global"
// instance would be a pointer to that thing.
@private
Physics :: struct {
	aabbs 				: [dynamic]AABB,
	submitted_colliders : [dynamic]SubmittedCollider,
	velocities 			: [dynamic]vec3,
	collider_tags 		: [dynamic]int,

	// Todo(Leo): I am very worried about precision issues on this
	// but for now should work as we are still very much testing phase
	// total_time : f32,

	// Todo(Leo): this should work instead, while avoiding precision issues :)
	left_over_time : f32,
	ticks_this_frame : int,
}

@private
physics : Physics

initialize :: proc (/* capacities etc. */) {
	p := &physics
	p^ = {}

	p.aabbs 				= make([dynamic]AABB)
	p.submitted_colliders 	= make([dynamic]SubmittedCollider)
	p.velocities 			= make([dynamic]vec3)
}

ticks_this_frame :: proc () -> int {
	return physics.ticks_this_frame
}

terminate :: proc () {
	p := &physics
	delete (p.aabbs)
	delete (p.submitted_colliders)
	delete (p.velocities)
	delete (p.collider_tags)
}

submit_colliders :: proc(new_colliders : []$T, velocities : []vec3 = nil, tags : []int = nil) {
	p := &physics

	old_len := len(p.aabbs)
	assert(old_len == len(p.submitted_colliders))
	assert(old_len == len(p.velocities))
	assert(old_len == len(p.collider_tags))
	
	new_len := len(new_colliders)
	assert(velocities == nil || len(velocities) == new_len)
	assert(tags == nil || len(tags) == new_len)

	resize(&p.aabbs, old_len + new_len)
	resize(&p.submitted_colliders, old_len + new_len)
	resize(&p.velocities, old_len + new_len)
	resize(&p.collider_tags, old_len + new_len)
	for i in 0..<new_len {
		p.aabbs[old_len + i] 				= get_aabb(&new_colliders[i])
		p.submitted_colliders[old_len + i] 	= new_colliders[i]
		p.velocities[old_len + i] 			= vec3(0) if velocities == nil else velocities[i]
		p.collider_tags[old_len + i] 		= 0 if tags == nil else tags[i]
	}

	when T == BoxCollider {
		for bc in new_colliders {
			debug.draw_wire_cube(bc.position, bc.rotation, bc.size, debug.RED)
		}
	}

	when T == CapsuleCollider {
		for cc in new_colliders {
			debug.draw_wire_cube(cc.position, quaternion(1), {2 * cc.radius, 2 * cc.radius, cc.height}, debug.RED)
		}
	}

	when T == SphereCollider {
		for sc in new_colliders {
			// debug.draw_wire_cube(sc.position, quaternion(1), vec3(sc.radius * 2), vec4{0.4, 0.0, 0.8, 1})
		}
	}
}

begin_frame :: proc(delta_time : f32) {
	p := &physics

	resize(&p.aabbs, 0)
	resize(&p.submitted_colliders, 0)
	resize(&p.velocities, 0)
	resize(&p.collider_tags, 0)

	delta_time := delta_time + p.left_over_time
	p.ticks_this_frame 	= int(delta_time / DELTA_TIME)
	p.left_over_time 	= math.mod(delta_time, DELTA_TIME)
}

is_colliding :: proc(a : ^$A, b : ^$B) -> bool {
	a_aabb := get_aabb(a)
	b_aabb := get_aabb(b)

	if collide_aabb_against_aabb(&a_aabb, &b_aabb) {
		return solve_gjk_only(a, b, linalg.normalize(b.position - a.position))
	}

	return false
}

@(private)
get_aabb_collisions :: proc(p : ^Physics, aabb : AABB) -> []int {
	// todo(Leo): this will reallocate from temp_allocator if 50 is not enough (which it should be)
	// make sure that that is okay
	// note(Leo): quite sure that it is okay (assuming there is available space); this is discarded, new allocation
	// is made and the old are copied to
	// todo(Leo): dedicated physics temp allocator
	collision_indices := make([dynamic]int, 0, 50, context.temp_allocator)

	aabb := aabb

	for _, i in p.aabbs {
		if collide_aabb_against_aabb(&aabb, &p.aabbs[i]) {
			append(&collision_indices, i)
		}
	}

	// note(Leo): okay to return slice even though it was allocated as dynamic array, since
	// it was allocated from temp_allocator that gets cleared "automatically" elsewhere
	// todo(Leo): use dedicated physics temp allocator especially for this since these are
	// not ever going to leave physics functions, and preferably should not interfere with
	// other allocations
	return collision_indices[:]
}

/*
Tests provided collider against all submitted colliders.

Allocates memory from context.temp_allocator (so modify that if needed) to a dynamic
array and returns slice from that. Idea is that this would not need to be explicitly
deleted, but free_all in the beginning of a frame would take care of this.
*/
collide :: proc(collider : ^$Collider) -> []Collision {
	p := &physics

	aabb := get_aabb(collider)
	collision_indices := get_aabb_collisions(p, aabb)

	// obsolete_comment: we only ever possibly need as many as collision indices number of these
	// todo(Leo): with the introduction of heightfield collider, the number of collisions is quite arbitrary
	collisions := make([dynamic]Collision, 0, len(collision_indices), context.temp_allocator)

	// todo(Leo): while it is somewhat ok to branch and question here, think more. this is not supposed to be a hot
	// loop, but only entered with small number of possible collisions
	for i in collision_indices {
		did_collide := false
		collision 	: Collision

		switch c in &p.submitted_colliders[i] {
			case BoxCollider: 		did_collide, collision = solve_gjk(collider, &c, c.position - collider.position)
			case SphereCollider: 	did_collide, collision = solve_gjk(collider, &c, c.position - collider.position)
			case CapsuleCollider: 	did_collide, collision = solve_gjk(collider, &c, c.position - collider.position)
			case TriangleCollider:	did_collide, collision = solve_gjk(collider, &c, c.position - collider.position)

			// case HeightfieldCollider:
			// 	triangles := heightfield_collider_generate_triangles(&c, aabb, context.temp_allocator)
			// 	for t in &triangles {
			// 		did_collide, collision = solve_gjk(collider, &t, t.position - collider.position)

			// 		if did_collide {
			// 			append(&collisions, collision)
			// 		}
			// 	}

			// 	// every thing is already handled
			// 	did_collide := false
		}

		if did_collide {
			collision.velocity = p.velocities[i]
			collision.tag = p.collider_tags[i]
			append(&collisions, collision)
		}
	}

	// // for now, this should be from context.allocator, so we know where to deallocate from
	// slice := make([]Collision, len(collisions))
	// copy_slice(slice, collisions[:])
	slice := collisions[:]

	return slice
}

collide_aabb_against_aabb :: proc (a : ^AABB, b: ^AABB) -> bool {
	d1x := b.min.x - a.max.x
	d1y := b.min.y - a.max.y
	d1z := b.min.z - a.max.z

	d2x := a.min.x - b.max.x
	d2y := a.min.y - b.max.y
	d2z := a.min.z - b.max.z

	if (d1x < 0.0) && (d1y < 0.0) && (d1z < 0.0) && (d2x < 0.0) && (d2y < 0.0) && (d2z < 0.0) {
		return true
	} else {
		return false
	}
}