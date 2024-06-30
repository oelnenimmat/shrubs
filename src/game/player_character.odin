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

PLAYER_CHARACTER_MOVE_SPEED :: 2.0

PlayerCharacter :: struct {
	physics_position : vec3,
	old_physics_position : vec3,

	pan, tilt 		: f32,
	head_height 	: f32,
}

create_player_character :: proc() -> PlayerCharacter {
	pc : PlayerCharacter
	pc.head_height = 1.8
	pc.physics_position = {0, 0, 5}
	pc.old_physics_position = pc.physics_position

	return pc
}

update_player_character :: proc(pc : ^PlayerCharacter, cam : ^Camera, delta_time : f32) {
	
	// Gather input
	move_right_input 	:= input.DEBUG_get_key_axis(.A, .D)
	move_forward_input 	:= input.DEBUG_get_key_axis(.S, .W)
	
	HACK_move_head_up_input := input.DEBUG_get_key_axis(.F, .R)

	look_right_input 	:= input.DEBUG_get_mouse_movement(0) * 0.005
	look_up_input 		:= input.DEBUG_get_mouse_movement(1) * 0.005

	jump_input := input.DEBUG_get_key_pressed(.Space)

	using linalg

	// Find view directions
	pc.pan 	= mod(pc.pan - look_right_input, 2 * math.PI)
	pc.tilt = clamp(pc.tilt - look_up_input, -1.3, 1.3)

	view_rotation 	:= quaternion_angle_axis_f32(pc.pan, OBJECT_UP) *
						quaternion_angle_axis_f32(pc.tilt, OBJECT_RIGHT)
	view_right 		:= normalize(mul(view_rotation, OBJECT_RIGHT))
	view_forward 	:= normalize(mul(view_rotation, OBJECT_FORWARD))
	view_up 		:= normalize(mul(view_rotation, OBJECT_UP))

	flat_right 		:= normalize(vec3{view_right.x, view_right.y, 0})
	flat_forward 	:= normalize(vec3{view_forward.x, view_forward.y, 0})

	// Move
	move_vector := move_right_input * flat_right +
					move_forward_input * flat_forward
	move_step := PLAYER_CHARACTER_MOVE_SPEED * delta_time
	pc.physics_position += move_vector * move_step
	pc.old_physics_position += move_vector * move_step

	pc.head_height += HACK_move_head_up_input * PLAYER_CHARACTER_MOVE_SPEED * delta_time

	// Physicsy -> apply forces
	for _ in 0..<physics.ticks_this_frame() {
		current_physics_position := pc.physics_position
		old_physics_position := pc.old_physics_position
		new_physics_position := current_physics_position + 
								(current_physics_position - old_physics_position) + 
								vec3{0, 0, -physics.GRAVITATIONAL_ACCELERATION} * physics.DELTA_TIME * physics.DELTA_TIME

		pc.old_physics_position = current_physics_position
		pc.physics_position 	= new_physics_position
	}

	// Collide/constrain
	min_z := sample_height(pc.physics_position.x, pc.physics_position.y)
	GROUNDING_SKIN_WIDTH :: 0.02
	grounded := pc.physics_position.z < (min_z + GROUNDING_SKIN_WIDTH)

	pc.physics_position.z = max(min_z, pc.physics_position.z)

	
	// Start using physics colliders
	{
		collider_height := f32(2)
		collider_radius := f32(0.5)
		collider_position := pc.physics_position + vec3{0, 0, 0.5 * collider_height}

		collider := physics.CapsuleCollider { collider_position, collider_radius, collider_height }

		for c in physics.collide(&collider) {
			correction := c.direction * c.depth
			pc.physics_position += correction

			velocity_vector := pc.physics_position - pc.old_physics_position
			velocity_vector -= linalg.projection(velocity_vector, c.direction)
			pc.old_physics_position = pc.physics_position - velocity_vector
		}

		// ground collider is slimmer to not hit walls and slightly below
		ground_collider := collider
		ground_collider.position.z -= 0.1 + GROUNDING_SKIN_WIDTH
		ground_collider.radius -= 0.1
		ground_collisions := physics.collide(&ground_collider)
		if ground_collisions != nil {
			grounded = true
		}
		for c in ground_collisions {
			pc.physics_position += c.velocity
			pc.old_physics_position += c.velocity
		}
	}

	// No sliding on the ground
	if grounded {
		pc.old_physics_position.xy = pc.physics_position.xy

		if jump_input {
			// Todo(Leo): this is very dependent on physics.DELTA_TIME and GRAVITATIONAL_ACCELERATION
			pc.physics_position.z += physics.GRAVITATIONAL_ACCELERATION * physics.DELTA_TIME * 0.5
		}
	}

	// Set camera position
	cam.position = pc.physics_position + OBJECT_UP * pc.head_height
	cam.rotation = view_rotation
}
