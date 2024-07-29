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

PLAYER_COLLIDER_RADIUS :: 0.5
PLAYER_COLLIDER_HEIGHT :: 2
// PLAYER_COLLIDER_CENTER :: vec3{0, 0, 0.5 * PLAYER_COLLIDER_HEIGHT}

PLAYER_HEAD_HEIGHT :: 3
PLAYER_CAMERA_DISTANCE :: -8

PlayerCharacter :: struct {
	physics_position 		: vec3,
	old_physics_position 	: vec3,

	up 		: vec3,
	forward : vec3,

	view_forward 			: vec3,

	is_attached_on_tank : bool,
}

create_player_character :: proc() -> PlayerCharacter {
	pc : PlayerCharacter
	pc.physics_position = {10, 10, world_radius * 1.2}
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
	
	look_right_input 	:= input.DEBUG_get_mouse_movement(0) * 0.005
	look_up_input 		:= input.DEBUG_get_mouse_movement(1) * 0.005

	jump_input := input.DEBUG_get_key_pressed(.Space)

	toggle_attach_on_tank := input.DEBUG_get_key_pressed(.T)
	
	if toggle_attach_on_tank {
		pc.is_attached_on_tank = !pc.is_attached_on_tank



		// // we are freshly bound to the tank
		// if pc.is_attached_on_tank {
		// 	parent_position 		:= tank_get_parent_position(&tank)
		// 	pc.physics_position 	-= parent_position
		// 	pc.old_physics_position -= parent_position
		// } else 
		// // we are freshly separated from the tank 
		// {
		// 	parent_position 		:= tank_get_parent_position(&tank)
		// 	pc.physics_position 	+= parent_position
		// 	pc.old_physics_position += parent_position
		// }
	}

	using linalg

	// Todo(Leo): for now we have flat plane as a world, but this will prob
	// change. To move along the plane, we need to know what is the local
	// up at that point of the world.
	// world_local_up := OBJECT_UP
	world_local_up := -linalg.normalize(physics.get_gravitational_pull(pc.physics_position))

	view_right 		:= normalize(cross(pc.view_forward, world_local_up))
	view_forward 	:= pc.view_forward
	view_up 		:= normalize(cross(view_right, pc.view_forward))

	pan 	:= quaternion_angle_axis_f32(-look_right_input, world_local_up)
	tilt 	:= quaternion_angle_axis_f32(-look_up_input, view_right)

	pc.view_forward = normalize(mul(pan * tilt, view_forward))

	pc.up 			= world_local_up
	pc.forward 		= normalize(cross(pc.up, /*right: */ normalize(cross(pc.view_forward, pc.up))))

	// Project view vectors on local up (just z-axis for now) to move on a flat plane
	flat_right 		:= normalize(view_right - projection(view_right, world_local_up))
	flat_forward 	:= normalize(view_forward - projection(view_forward, world_local_up))

	// Move
	move_vector := move_right_input * flat_right + move_forward_input * flat_forward

	GROUNDING_SKIN_WIDTH :: 0.02
	// Physicsy -> apply forces

	for _ in 0..<physics.ticks_this_frame() {
		player_physics_update(pc, move_vector)
	}

	// min_z 		:= sample_height(pc.physics_position.x, pc.physics_position.y, &scene.world)
	grounded 	:= false // pc.physics_position.z < (min_z + GROUNDING_SKIN_WIDTH)

	// ground collider is slimmer to not hit walls and slightly below, also put it slighlyt down to hit the ground
	ground_collider := physics.CapsuleCollider {
		pc.physics_position + (pc.up * (0.5 * PLAYER_COLLIDER_HEIGHT - 0.05)),
		PLAYER_COLLIDER_RADIUS - 0.1,
		PLAYER_COLLIDER_HEIGHT,
	}
	grounded = grounded || (physics.collide(&ground_collider) != nil)

	if pc.is_attached_on_tank {

		// pc_local_position 		:= matrix4_mul_point(inverse(tank.body_transform), pc.physics_position)
		// pc_local_position 		= matrix4_mul_point(tank.body_transform_difference, pc_local_position)
		// pc.physics_position 	= pc_local_position
		// pc.old_physics_position = pc_local_position


		// for c in ground_collisions {
		// 	if cast(TEMP_ColliderTag)c.tag == .Tank {
				tank_position_change := tank.body_position - tank.old_body_position

				tank_rotation_change := normalize(quaternion_inverse(tank.old_body_rotation) * tank.body_rotation)
				pc.view_forward = mul(tank_rotation_change, pc.view_forward)

				pc_local_position := pc.physics_position - tank.body_position
				rotation_matrix := matrix4_from_quaternion(tank_rotation_change)

				pc_local_position = matrix4_mul_point(rotation_matrix, pc_local_position)
				pc_position := pc_local_position + tank.body_position

				diff := pc_position - pc.physics_position + tank_position_change
				pc.physics_position += diff
				pc.old_physics_position += diff
		// 	}
		// }
	}

	// No sliding on the ground
	if grounded {
		G 			:= physics.get_gravitational_pull(pc.physics_position)
		G_direction := linalg.normalize(G)
		G_magnitude := linalg.length(G)

		// project difference to G_direction and subtract that from the difference
		// pc.old_physics_position.xy = pc.physics_position.xy

		if jump_input {
			// Todo(Leo): this is very dependent on physics.DELTA_TIME and GRAVITATIONAL_ACCELERATION. Duh, obviously
			// pc.physics_position.z += physics.GRAVITATIONAL_ACCELERATION * physics.DELTA_TIME * 0.5
			pc.physics_position += -G * physics.DELTA_TIME * 0.5
		}
	}


	// Done updating the physics position, lets print the values
	speed := linalg.length(pc.physics_position - pc.old_physics_position) / delta_time
	z_speed := (pc.physics_position.z - pc.old_physics_position.z) / delta_time
	smooth_value_put(&player_debug.speed, speed)
	smooth_value_put(&player_debug.z_speed, z_speed)
	smooth_value_put(&player_debug.physticks, f32(physics.ticks_this_frame()))

	// put_debug_value("player speed", player_debug.speed.value)
	// put_debug_value("z speed", player_debug.z_speed.value)
	// put_debug_value("ground correction", player_debug.ground_correction.value)
	// put_debug_value("physics ticks", int(math.round(player_debug.physticks.value)))
	// put_debug_value("grounded", grounded)
	// put_debug_value("position", pc.physics_position)
	// put_debug_value("old position", pc.old_physics_position)
	put_debug_value("is attached on tank", pc.is_attached_on_tank)

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
		// eye_depth := f32(0.15)
		cam.position = pc.physics_position +
						 world_local_up * PLAYER_HEAD_HEIGHT +
						 view_forward * PLAYER_CAMERA_DISTANCE
						 // view_forward * eye_depth 
		cam.rotation = view_rotation
	}

	// Check tank buttons
	{
		button_positions := tank_get_button_positions(&tank)

		biggest_dot 			:= f32(-10000)
		selected_button_index 	:= -1

		for b, index in button_positions {
			// todo(Leo): store this also ourselves somehere here
			view_to_button := b - cam.position
			if linalg.length(view_to_button) < 2 {
				debug.draw_wire_sphere(b, 0.2, debug.YELLOW)
				
				d := linalg.dot(linalg.normalize(view_to_button), view_forward)
				if d > 0.707 && d > biggest_dot {
					biggest_dot = d
					selected_button_index = index
				}
			}
		}

		if selected_button_index >= 0 {
			debug.draw_wire_sphere(button_positions[selected_button_index], 0.3, debug.GREEN)

			if input.DEBUG_get_mouse_button_pressed(0) {
				tank_controls_press_button(&tank, selected_button_index)
			} else if input.DEBUG_get_mouse_button_held(0) {
				tank_controls_hold_button(&tank, selected_button_index)
			}
		}
	}

	// check being inside the tank
	checking_collider := physics.SphereCollider { pc.physics_position + {0, 0, 0.5 * PLAYER_COLLIDER_HEIGHT}, 0.1}
	if physics.is_colliding (&checking_collider, &tank.inside_trigger_volume) {
		pc.is_attached_on_tank = true
		debug.draw_wire_cube(tank.inside_trigger_volume.position, tank.inside_trigger_volume.rotation, tank.inside_trigger_volume.size, debug.GREEN)
	} else {
		pc.is_attached_on_tank = false
		debug.draw_wire_cube(tank.inside_trigger_volume.position, tank.inside_trigger_volume.rotation, tank.inside_trigger_volume.size, debug.RED)
	}


	debug.draw_wire_capsule(pc.physics_position + pc.up * 0.5 * PLAYER_COLLIDER_HEIGHT, pc.up, PLAYER_COLLIDER_RADIUS * 1.1, PLAYER_COLLIDER_HEIGHT, debug.RED)
}

player_physics_update :: proc(pc : ^PlayerCharacter, move_vector : vec3) {
	
	// collider_position := pc.physics_position + vec3{0, 0, 0.5 * collider_height}

	collider := physics.CapsuleCollider {
		{},
		PLAYER_COLLIDER_RADIUS,
		PLAYER_COLLIDER_HEIGHT,
	}

	move_step := cast(f32) PLAYER_CHARACTER_MOVE_SPEED * physics.DELTA_TIME
	pc.physics_position 	+= move_vector * move_step * 0.01
	// pc.old_physics_position += move_vector * move_step

	current_physics_position := pc.physics_position
	old_physics_position := pc.old_physics_position
	new_physics_position := current_physics_position + 
							(current_physics_position - old_physics_position) + 
							// Todo(Leo): gravity is approximated same for the duration of the frame, maybe is good enough, maybe is not
							physics.get_gravitational_pull(current_physics_position) * physics.DELTA_TIME * physics.DELTA_TIME

	// Collide/constrain
	// min_z := sample_height(new_physics_position.x, new_physics_position.y, &scene.world)
	// correction := math.max(0, min_z - new_physics_position.z)
	// new_physics_position.z += correction



	collider.position = new_physics_position + pc.up * (0.5 * PLAYER_COLLIDER_HEIGHT)
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


@(private = "file")
player_debug : struct {
	speed 				: SmoothValue(10),
	z_speed 			: SmoothValue(1),
	ground_correction 	: SmoothValue(10),
	physticks 			: SmoothValue(10),
}