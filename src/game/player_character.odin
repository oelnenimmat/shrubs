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

// get to max speed in 1s
PLAYER_ACCELERATION 	:: 6.0
PLAYER_MAX_SPEED 		:: 6.0

PLAYER_MOVE_SPEED :: 6.0

PLAYER_COLLIDER_RADIUS :: 0.5
PLAYER_COLLIDER_HEIGHT :: 2
// PLAYER_COLLIDER_CENTER :: vec3{0, 0, 0.5 * PLAYER_COLLIDER_HEIGHT}

PLAYER_HEAD_HEIGHT :: 3
PLAYER_CAMERA_DISTANCE :: -8

PlayerCharacter :: struct {
	position 	: vec3,
	z_speed 	: f32,

	up 		: vec3,
	forward : vec3,

	view_forward : vec3,
}

create_player_character :: proc() -> PlayerCharacter {
	p : PlayerCharacter
	p.position = {10, 10, world_radius * 1.2}

	p.view_forward = OBJECT_FORWARD
	p.z_speed = 0;

	return p
}

player_get_position :: proc (p : ^PlayerCharacter) -> vec3 {
	return p.position
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


update_player_character :: proc(p : ^PlayerCharacter, cam : ^Camera, delta_time : f32) {
	
	// Gather input
	move_right_input 	:= input.DEBUG_get_key_axis(.A, .D)
	move_forward_input 	:= input.DEBUG_get_key_axis(.S, .W)
	
	look_right_input 	:= input.DEBUG_get_mouse_movement(0) * 0.005
	look_up_input 		:= input.DEBUG_get_mouse_movement(1) * 0.005

	jump_input 			:= input.DEBUG_get_key_pressed(.Space)

	using linalg

	// Todo(Leo): for now we have flat plane as a world, but this will prob
	// change. To move along the plane, we need to know what is the local
	// up at that point of the world.
	// world_local_up := OBJECT_UP
	world_local_up := -normalize(physics.get_gravitational_pull(p.position))

	view_right 		:= normalize(cross(p.view_forward, world_local_up))
	view_forward 	:= p.view_forward
	view_up 		:= normalize(cross(view_right, p.view_forward))

	// Todo(Leo): use rotors for shits and giggles
	// pan := rotor_angle_axis(-look_right_input, local_plane)
	// tilt := rotor_angle_axis(-look_up_input, tilt_plane)

	pan 	:= quaternion_angle_axis_f32(-look_right_input, world_local_up)
	tilt 	:= quaternion_angle_axis_f32(-look_up_input, view_right)

	p.view_forward = normalize(mul(pan * tilt, view_forward))

	p.up 			= world_local_up
	p.forward 		= normalize(cross(p.up, /*right: */ normalize(cross(p.view_forward, p.up))))

	// Project view vectors on local up (just z-axis for now) to move on a flat plane
	flat_right 		:= normalize(view_right - projection(view_right, world_local_up))
	flat_forward 	:= normalize(view_forward - projection(view_forward, world_local_up))

	// Move
	move_vector := move_right_input * flat_right + move_forward_input * flat_forward

	p.z_speed += -physics.GRAVITATIONAL_ACCELERATION * delta_time

	p.position.xy 	+= (move_vector * PLAYER_MOVE_SPEED * delta_time).xy
	p.position.z 	+= p.z_speed * delta_time

	GROUNDING_SKIN_WIDTH :: 0.02


	// Physicsy -> apply forces
	collision_count := 0
	{
		collider := physics.CapsuleCollider{
			p.position + p.up * PLAYER_COLLIDER_HEIGHT / 2, 
			p.up,
			PLAYER_COLLIDER_RADIUS,
			PLAYER_COLLIDER_HEIGHT,
		}

		// this is cool, but unnecessary now
		// if collisions := physics.collide(collider); collisions != nil {}

		collisions 		:= physics.collide(collider)
		collision_count = len(collisions)
		
		for c in collisions {
			correction := c.depth * c.direction
			p.position += correction

			debug.draw_line(c.DEBUG_position, c.DEBUG_position + c.direction * 4, debug.YELLOW)
		}
	}

	grounded := false

	// Todo(Leo): use gjk_only version
	// Todo(Leo): use sphere collider
	// ground collider is slimmer to not hit walls and slightly below, also put it slighlyt down to hit the ground
	ground_collider := physics.CapsuleCollider {
		p.position + (p.up * (0.5 * PLAYER_COLLIDER_HEIGHT - 0.05)),
		p.up,
		PLAYER_COLLIDER_RADIUS - 0.1,
		PLAYER_COLLIDER_HEIGHT,
	}
	ground_collisions := physics.collide(ground_collider)
	grounded = grounded || (len(ground_collisions) > 0)

	// No sliding on the ground

	if grounded {
		p.z_speed = max(f32(0), p.z_speed)

		if jump_input {

			// kinematic equations
			// v^2 = v0^2 + 2ax | v = 0
			// v0^2 = -2ax
			// v0 = sqrt(-2ax)

			JUMP_HEIGHT :: 3
			p.z_speed = math.sqrt_f32(2 * physics.GRAVITATIONAL_ACCELERATION * JUMP_HEIGHT)
		}
	}

	put_debug_value("grounded", grounded)



	// Done updating the physics position, lets print the values
	put_debug_value("z speed", p.z_speed)
	put_debug_value("position", p.position)

	put_debug_value("collisions", collision_count)
	put_debug_value("ground collisions", len(ground_collisions))

	debug.draw_wire_sphere(p.position, 0.2, debug.RED)

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
		cam.position = p.position +
						 world_local_up * PLAYER_HEAD_HEIGHT +
						 view_forward * PLAYER_CAMERA_DISTANCE
						 // view_forward * eye_depth 
		cam.rotation = view_rotation
	}
	/*
	// Check tank buttons
	{
		button_positions := tank_get_button_positions(&tank)

		biggest_dot 			:= f32(-10000)
		selected_button_index 	:= -1

		for b, index in button_positions {
			// todo(Leo): store this also ourselves somehere here
			view_to_button := b - cam.position
			if length(view_to_button) < 2 {
				debug.draw_wire_sphere(b, 0.2, debug.YELLOW)
				
				d := dot(normalize(view_to_button), view_forward)
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

	debug.draw_wire_capsule(p.position + p.up * 0.5 * PLAYER_COLLIDER_HEIGHT, p.up, PLAYER_COLLIDER_RADIUS * 1.1, PLAYER_COLLIDER_HEIGHT, debug.RED)
	*/
}

/*
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

// get to max speed in 1s
PLAYER_ACCELERATION 	:: 6.0
PLAYER_MAX_SPEED 		:: 6.0

PLAYER_MOVE_SPEED :: 6.0

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
	p : PlayerCharacter
	p.physics_position = {10, 10, world_radius * 1.2}
	p.old_physics_position = p.physics_position

	p.view_forward = OBJECT_FORWARD

	return p
}

player_get_position :: proc (p : ^PlayerCharacter) -> vec3 {
	return p.physics_position
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


update_player_character :: proc(p : ^PlayerCharacter, cam : ^Camera, delta_time : f32) {
	
	// Gather input
	move_right_input 	:= input.DEBUG_get_key_axis(.A, .D)
	move_forward_input 	:= input.DEBUG_get_key_axis(.S, .W)
	
	look_right_input 	:= input.DEBUG_get_mouse_movement(0) * 0.005
	look_up_input 		:= input.DEBUG_get_mouse_movement(1) * 0.005

	jump_input := input.DEBUG_get_key_pressed(.Space)

	toggle_attach_on_tank := input.DEBUG_get_key_pressed(.T)
	
	if toggle_attach_on_tank {
		p.is_attached_on_tank = !p.is_attached_on_tank



		// // we are freshly bound to the tank
		// if p.is_attached_on_tank {
		// 	parent_position 		:= tank_get_parent_position(&tank)
		// 	p.physics_position 	-= parent_position
		// 	p.old_physics_position -= parent_position
		// } else 
		// // we are freshly separated from the tank 
		// {
		// 	parent_position 		:= tank_get_parent_position(&tank)
		// 	p.physics_position 	+= parent_position
		// 	p.old_physics_position += parent_position
		// }
	}

	using linalg

	// Todo(Leo): for now we have flat plane as a world, but this will prob
	// change. To move along the plane, we need to know what is the local
	// up at that point of the world.
	// world_local_up := OBJECT_UP
	world_local_up := -linalg.normalize(physics.get_gravitational_pull(p.physics_position))

	view_right 		:= normalize(cross(p.view_forward, world_local_up))
	view_forward 	:= p.view_forward
	view_up 		:= normalize(cross(view_right, p.view_forward))

	pan 	:= quaternion_angle_axis_f32(-look_right_input, world_local_up)
	tilt 	:= quaternion_angle_axis_f32(-look_up_input, view_right)

	p.view_forward = normalize(mul(pan * tilt, view_forward))

	p.up 			= world_local_up
	p.forward 		= normalize(cross(p.up, /*right: */ normalize(cross(p.view_forward, p.up))))

	// Project view vectors on local up (just z-axis for now) to move on a flat plane
	flat_right 		:= normalize(view_right - projection(view_right, world_local_up))
	flat_forward 	:= normalize(view_forward - projection(view_forward, world_local_up))

	// Move
	move_vector := move_right_input * flat_right + move_forward_input * flat_forward

	GROUNDING_SKIN_WIDTH :: 0.02
	// Physicsy -> apply forces

	for _ in 0..<physics.ticks_this_frame() {
		player_physics_update(p, move_vector)
	}

	// min_z 		:= sample_height(p.physics_position.x, p.physics_position.y, &scene.world)
	grounded 	:= false // p.physics_position.z < (min_z + GROUNDING_SKIN_WIDTH)

	// ground collider is slimmer to not hit walls and slightly below, also put it slighlyt down to hit the ground
	ground_collider := physics.CapsuleCollider {
		p.physics_position + (p.up * (0.5 * PLAYER_COLLIDER_HEIGHT - 0.05)),
		p.up,
		PLAYER_COLLIDER_RADIUS - 0.1,
		PLAYER_COLLIDER_HEIGHT,
	}
	grounded = grounded || (physics.collide(&ground_collider) != nil)

	if p.is_attached_on_tank {

		// pc_local_position 		:= matrix4_mul_point(inverse(tank.body_transform), p.physics_position)
		// pc_local_position 		= matrix4_mul_point(tank.body_transform_difference, pc_local_position)
		// p.physics_position 	= pc_local_position
		// p.old_physics_position = pc_local_position


		// for c in ground_collisions {
		// 	if cast(TEMP_ColliderTag)c.tag == .Tank {
				tank_position_change := tank.body_position - tank.old_body_position

				tank_rotation_change := normalize(quaternion_inverse(tank.old_body_rotation) * tank.body_rotation)
				p.view_forward = mul(tank_rotation_change, p.view_forward)

				pc_local_position := p.physics_position - tank.body_position
				rotation_matrix := matrix4_from_quaternion(tank_rotation_change)

				pc_local_position = matrix4_mul_point(rotation_matrix, pc_local_position)
				pc_position := pc_local_position + tank.body_position

				diff := pc_position - p.physics_position + tank_position_change
				p.physics_position += diff
				p.old_physics_position += diff
		// 	}
		// }
	}

	// No sliding on the ground
	if grounded {
		G 			:= physics.get_gravitational_pull(p.physics_position)
		G_direction := linalg.normalize(G)
		G_magnitude := linalg.length(G)

		// project difference to G_direction and subtract that from the difference
		// p.old_physics_position.xy = p.physics_position.xy

		if jump_input {
			// Todo(Leo): this is very dependent on physics.DELTA_TIME and GRAVITATIONAL_ACCELERATION. Duh, obviously
			// p.physics_position.z += physics.GRAVITATIONAL_ACCELERATION * physics.DELTA_TIME * 0.5
			p.physics_position += -G * physics.DELTA_TIME * 0.5
		}
	}


	// Done updating the physics position, lets print the values
	speed := linalg.length(p.physics_position - p.old_physics_position) / delta_time
	z_speed := (p.physics_position.z - p.old_physics_position.z) / delta_time
	smooth_value_put(&player_debug.speed, speed)
	smooth_value_put(&player_debug.z_speed, z_speed)
	smooth_value_put(&player_debug.physticks, f32(physics.ticks_this_frame()))

	// put_debug_value("player speed", player_debug.speed.value)
	// put_debug_value("z speed", player_debug.z_speed.value)
	// put_debug_value("ground correction", player_debug.ground_correction.value)
	// put_debug_value("physics ticks", int(math.round(player_debug.physticks.value)))
	// put_debug_value("grounded", grounded)
	put_debug_value("position", p.physics_position)
	// put_debug_value("old position", p.old_physics_position)
	put_debug_value("is attached on tank", p.is_attached_on_tank)

	debug.draw_wire_sphere(p.physics_position, 0.2, debug.RED)

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
		cam.position = p.physics_position +
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
	checking_collider := physics.SphereCollider { p.physics_position + {0, 0, 0.5 * PLAYER_COLLIDER_HEIGHT}, 0.1}
	if physics.is_colliding (&checking_collider, &tank.inside_trigger_volume) {
		p.is_attached_on_tank = true
		debug.draw_wire_cube(tank.inside_trigger_volume.position, tank.inside_trigger_volume.rotation, tank.inside_trigger_volume.size, debug.GREEN)
	} else {
		p.is_attached_on_tank = false
		debug.draw_wire_cube(tank.inside_trigger_volume.position, tank.inside_trigger_volume.rotation, tank.inside_trigger_volume.size, debug.RED)
	}


	debug.draw_wire_capsule(p.physics_position + p.up * 0.5 * PLAYER_COLLIDER_HEIGHT, p.up, PLAYER_COLLIDER_RADIUS * 1.1, PLAYER_COLLIDER_HEIGHT, debug.RED)
}

player_physics_update :: proc(p : ^PlayerCharacter, move_vector : vec3) {
	
	// collider_position := p.physics_position + vec3{0, 0, 0.5 * collider_height}
	// Todo(Leo): recalculate p.up here

	collider := physics.CapsuleCollider {
		{},
		p.up,
		PLAYER_COLLIDER_RADIUS,
		PLAYER_COLLIDER_HEIGHT,
	}

	move_step := cast(f32) PLAYER_MOVE_SPEED * physics.DELTA_TIME
	p.physics_position 	+= move_vector * move_step * 0.1
	// p.old_physics_position += move_vector * move_step


	current_physics_position := p.physics_position
	old_physics_position := p.old_physics_position
	new_physics_position := current_physics_position + 
							(current_physics_position - old_physics_position) + 
							// Todo(Leo): gravity is approximated same for the duration of the frame, maybe is good enough, maybe is not
							physics.get_gravitational_pull(current_physics_position) * physics.DELTA_TIME * physics.DELTA_TIME

	// Collide/constrain
	min_z := sample_height(new_physics_position.x, new_physics_position.y, &scene.world)
	correction := math.max(0, min_z - new_physics_position.z)
	new_physics_position.z += correction


	collider.position = new_physics_position + p.up * (0.5 * PLAYER_COLLIDER_HEIGHT)
	for c in physics.collide(&collider) {
		correction := c.direction * c.depth

		new_physics_position += correction

		velocity_vector := new_physics_position - current_physics_position
		velocity_vector -= linalg.projection(velocity_vector, c.direction)
		current_physics_position = new_physics_position - velocity_vector
	}

	p.old_physics_position = current_physics_position
	p.physics_position 	= new_physics_position
}


@(private = "file")
player_debug : struct {
	speed 				: SmoothValue(10),
	z_speed 			: SmoothValue(1),
	ground_correction 	: SmoothValue(10),
	physticks 			: SmoothValue(10),
}
*/