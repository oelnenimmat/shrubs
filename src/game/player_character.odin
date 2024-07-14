/*
Player controller for the application.

PlayerCharacter acts as an camera controller. There might be other
types of camera controllers. Camera itself does not ever really control
itself.

Todo/ideas:
	camera view not centered in the center of the skull but
	forward to eye level

*/

// +private
package game

import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:math/linalg/glsl"

import "shrubs:debug"
import "shrubs:input"
import "shrubs:physics"

PLAYER_CHARACTER_MOVE_SPEED :: 6.0

PlayerCharacter :: struct {
	physics_position 		: vec3,
	old_physics_position 	: vec3,

	view_forward 			: vec3,
	head_height 			: f32,
}

create_player_character :: proc() -> PlayerCharacter {
	pc : PlayerCharacter
	pc.head_height = 1.8
	pc.physics_position = {0, 0, 5}
	pc.old_physics_position = pc.physics_position

	pc.view_forward = OBJECT_FORWARD

	return pc
}

player_get_position :: proc (pc : ^PlayerCharacter) -> vec3 {
	return pc.physics_position
}

// //https://stackoverflow.com/questions/3684269/component-of-a-quaternion-rotation-around-an-axis
// swing_twist_decomposition :: proc(rotation : quaternion, direction : vec3) -> (swing, twist : quaternion) {
// 	angle, rotation_axis := linalg.angle_axis_from_quaternion(rotation)
// 	p := linalg.projection(rotation_axis, direction)
// 	t := cast(^vec4) &twist
// 	t^ = {real(rotation), p.x, p.y, p.z}
// 	twist = linalg.normalize(twist)
// 	return
// }


update_player_character :: proc(pc : ^PlayerCharacter, cam : ^Camera, delta_time : f32) {
	
	// Gather input
	move_right_input 	:= input.DEBUG_get_key_axis(.A, .D)
	move_forward_input 	:= input.DEBUG_get_key_axis(.S, .W)
	
	HACK_move_head_up_input := input.DEBUG_get_key_axis(.F, .R)

	look_right_input 	:= input.DEBUG_get_mouse_movement(0) * 0.005
	look_up_input 		:= input.DEBUG_get_mouse_movement(1) * 0.005

	jump_input := input.DEBUG_get_key_pressed(.Space)

	using linalg

	// Todo(Leo): for now we have flat plane as a world, but this will prob
	// change. To move along the plane, we need to know what is the local
	// up at that point of the world.
	world_local_up := OBJECT_UP

	view_right 		:= normalize(cross(pc.view_forward, world_local_up))
	view_forward 	:= pc.view_forward
	view_up 		:= normalize(cross(view_right, pc.view_forward))

	pan 	:= quaternion_angle_axis_f32(-look_right_input, world_local_up)
	tilt 	:= quaternion_angle_axis_f32(-look_up_input, view_right)

	pc.view_forward = normalize(mul(pan * tilt, view_forward))

	// Project view vectors on local up (just z-axis for now) to move on a flat plane
	flat_right 		:= normalize(view_right - projection(view_right, world_local_up))
	flat_forward 	:= normalize(view_forward - projection(view_forward, world_local_up))

	// Move
	move_vector := move_right_input * flat_right +
					move_forward_input * flat_forward
	// move_step := PLAYER_CHARACTER_MOVE_SPEED * delta_time
	// pc.physics_position 	+= move_vector * move_step
	// pc.old_physics_position += move_vector * move_step

	pc.head_height += HACK_move_head_up_input * PLAYER_CHARACTER_MOVE_SPEED * delta_time

	GROUNDING_SKIN_WIDTH :: 0.02
	// Physicsy -> apply forces
	grounded := false
	collider_height := f32(2)
	collider_radius := f32(0.5)
	collider_offset := vec3{0, 0, 0.5 * collider_height}
	// collider_position := pc.physics_position + vec3{0, 0, 0.5 * collider_height}

	collider := physics.CapsuleCollider { {}, collider_radius, collider_height }

	for _ in 0..<physics.ticks_this_frame() {

		move_step := cast(f32) PLAYER_CHARACTER_MOVE_SPEED * physics.DELTA_TIME
		pc.physics_position 	+= move_vector * move_step
		pc.old_physics_position += move_vector * move_step

		current_physics_position := pc.physics_position
		old_physics_position := pc.old_physics_position
		new_physics_position := current_physics_position + 
								(current_physics_position - old_physics_position) + 
								vec3{0, 0, -physics.GRAVITATIONAL_ACCELERATION} * physics.DELTA_TIME * physics.DELTA_TIME


		// Collide/constrain
		min_z := sample_height(new_physics_position.x, new_physics_position.y, &scene.world)
		correction := math.max(0, min_z - new_physics_position.z)
		new_physics_position.z += correction

		grounded = new_physics_position.z < (min_z + GROUNDING_SKIN_WIDTH)
		// pc.physics_position.z = max(min_z, pc.physics_position.z)

		collider.position = new_physics_position + collider_offset
		for c in physics.collide(&collider) {
			correction := c.direction * c.depth

			new_physics_position += correction

			velocity_vector := new_physics_position - current_physics_position
			velocity_vector -= linalg.projection(velocity_vector, c.direction)
			current_physics_position = new_physics_position - velocity_vector
		}



		pc.old_physics_position = current_physics_position
		pc.physics_position 	= new_physics_position
	}

	
	// grounded := pc.physics_position.z < (min_z + GROUNDING_SKIN_WIDTH)
	// Start using physics colliders
	if true
	{
		// collider_height := f32(2)
		// collider_radius := f32(0.5)
		// collider_position := pc.physics_position + vec3{0, 0, 0.5 * collider_height}

		// collider := physics.CapsuleCollider { collider_position, collider_radius, collider_height }

		// for c in physics.collide(&collider) {
		// 	correction := c.direction * c.depth
		// 	pc.physics_position += correction

		// 	velocity_vector := pc.physics_position - pc.old_physics_position
		// 	velocity_vector -= linalg.projection(velocity_vector, c.direction)
		// 	pc.old_physics_position = pc.physics_position - velocity_vector
		// }

		// ground collider is slimmer to not hit walls and slightly below, also put it slighlyt down to hit the ground
		ground_collider := collider
		ground_collider.position = pc.physics_position + collider_offset + {0, 0, -0.05}; // - GROUNDING_SKIN_WIDTH
		ground_collider.radius -= 0.1
		ground_collisions := physics.collide(&ground_collider)
		if ground_collisions != nil {
			grounded = true
		}
		// for c in ground_collisions {
		// 	if cast(TEMP_ColliderTag)c.tag == .Tank {
		// 		tank_position_change := tank.body_position - tank.old_body_position

		// 		tank_rotation_change := normalize(quaternion_inverse(tank.old_body_rotation) * tank.body_rotation)
		// 		pc.view_forward = mul(tank_rotation_change, pc.view_forward)

		// 		pc_local_position := pc.physics_position - tank.body_position
		// 		rotation_matrix := matrix4_from_quaternion(tank_rotation_change)

		// 		pc_local_position = matrix4_mul_point(rotation_matrix, pc_local_position)
		// 		pc_position := pc_local_position + tank.body_position

		// 		diff := pc_position - pc.physics_position + tank_position_change
		// 		pc.physics_position += diff
		// 		pc.old_physics_position += diff
		// 	}
		// }
	}

	// No sliding on the ground
	if grounded {
		pc.old_physics_position.xy = pc.physics_position.xy

		if jump_input {
			// Todo(Leo): this is very dependent on physics.DELTA_TIME and GRAVITATIONAL_ACCELERATION. Duh, obviously
			pc.physics_position.z += physics.GRAVITATIONAL_ACCELERATION * physics.DELTA_TIME * 0.5
		}
	}


	// Done updating the physics position, lets print the values
	speed := linalg.length(pc.physics_position - pc.old_physics_position) / delta_time
	z_speed := (pc.physics_position.z - pc.old_physics_position.z) / delta_time
	smooth_value_put(&player_debug.speed, speed)
	smooth_value_put(&player_debug.z_speed, z_speed)
	smooth_value_put(&player_debug.physticks, f32(physics.ticks_this_frame()))

	put_debug_value("player speed", player_debug.speed.value)
	put_debug_value("z speed", player_debug.z_speed.value)
	put_debug_value("ground correction", player_debug.ground_correction.value)
	put_debug_value("physics ticks", int(math.round(player_debug.physticks.value)))
	put_debug_value("grounded", grounded)
	put_debug_value("position", pc.physics_position)
	put_debug_value("old position", pc.old_physics_position)

	debug.draw_wire_sphere(pc.physics_position, 0.2, debug.RED)

	// Set camera position
	{
		r := view_right
		f := view_forward
		u := view_up
		m := mat4{
			r.x, f.x, u.x, 0,
			r.y, f.y, u.y, 0,
			r.z, f.z, u.z, 0,
			0, 0, 0, 1,
		}
		view_rotation := quaternion_from_matrix4(m)

		// Move eyes a tiny bit outside
		eye_depth := f32(0.15)
		cam.position = pc.physics_position + world_local_up * pc.head_height + view_forward * eye_depth 
		cam.rotation = view_rotation

	}
}

@(private = "file")
player_debug : struct {
	speed 				: SmoothValue(10),
	z_speed 			: SmoothValue(1),
	ground_correction 	: SmoothValue(10),
	physticks 			: SmoothValue(10),
}