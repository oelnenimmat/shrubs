package game

import "shrubs:assets"
import "shrubs:debug"
import "shrubs:graphics"
import "shrubs:input"
import "shrubs:physics"

import "core:fmt"
import "core:math"
import "core:math/linalg"

/*
Todo/ideas:

tank speed dependent on wheels touching
	- maybe not the case with tracks?

control gear, slide down when on free
	- maybe just back, free and forward?
	- maybe back, free, 1 and 2?

actually different sounds from incidences like springs hitting bottom etc
*/

TANK_HULL_WIDTH :: 3
TANK_HULL_LENGTH :: 6
TANK_HULL_THICKNESS :: 0.3

TANK_FRONT_CAMERA_POSITION_LS :: vec3 {0, 3, 1.5}
TANK_FRONT_CAMERA_SCREEN_POSITION_LS :: vec3{0, 2.2, 2}
TANK_FRONT_CAMERA_SCREEN_SIZE :: vec3{1.7 * 0.6, 0.6, 1}


TANK_WHEEL_WIDTH :: f32(0.4)
TANK_WHEEL_RADIUS :: 0.35
TANK_SPEED :: 2.5

// Even a small number seems to work fine :)
// Todo(Leo): move all this to physics package, were going to do
// more, probably
TANK_CONSTRAINT_ITERATIONS :: 3

L1 :: 0
L2 :: 1
L3 :: 2
L4 :: 3
R1 :: 4
R2 :: 5
R3 :: 6
R4 :: 7

TANK_WHEEL_COUNT :: 8

WheelConstraint :: struct {
	index_a, index_b 	: int,
	distance 			: f32,
}

Tank :: struct {
	wheel_positions 	: [TANK_WHEEL_COUNT]vec3,
	old_wheel_positions : [TANK_WHEEL_COUNT]vec3,
	wheel_constraints 	: [20]WheelConstraint,
	wheel_rotations 	: [TANK_WHEEL_COUNT]mat4,
	wheel_spins 		: [TANK_WHEEL_COUNT]f32,

	body_transform : mat4,
	body_transform_difference : mat4,

	// Todo(Leo): not initialized properly
	body_position : vec3,
	old_body_position : vec3,

	body_rotation : quaternion,
	old_body_rotation : quaternion,

	// rendering
	body_mesh	: ^graphics.Mesh,
	wheel_mesh 	: ^graphics.Mesh,

	// 
	inside_trigger_volume : physics.BoxCollider,

	// Buttons
	buttons_positions : [3]vec3,
	auto_drive_on : bool,
	turn_left : bool,
	turn_right : bool,

	// cameras
	front_camera : Camera,
}



create_tank :: proc() -> Tank {
	t := Tank{}

	width := TANK_HULL_WIDTH + TANK_WHEEL_WIDTH
	length := cast(f32) TANK_HULL_LENGTH - TANK_WHEEL_RADIUS
	
	// local wheel positions
	hw := width / 2
	row_1 := length / 2
	row_2 := row_1 - length / 3
	row_3 := row_2 - length / 3
	row_4 := row_3 - length / 3
	l1 := vec3{-hw, row_1, 0}
	l2 := vec3{-hw, row_2, 0}
	l3 := vec3{-hw, row_3, 0}
	l4 := vec3{-hw, row_4, 0}
	r1 := vec3{hw, row_1, 0}
	r2 := vec3{hw, row_2, 0}
	r3 := vec3{hw, row_3, 0}
	r4 := vec3{hw, row_4, 0}

	center := vec3{5, 5, 5}

	t.wheel_positions[L1] = center + l1
	t.wheel_positions[L2] = center + l2
	t.wheel_positions[L3] = center + l3
	t.wheel_positions[L4] = center + l4
	t.wheel_positions[R1] = center + r1
	t.wheel_positions[R2] = center + r2
	t.wheel_positions[R3] = center + r3
	t.wheel_positions[R4] = center + r4
	t.old_wheel_positions = t.wheel_positions 

	t.wheel_constraints[0] = {L1, R1, width}
	t.wheel_constraints[1] = {R1, R4, length}
	t.wheel_constraints[2] = {R4, L4, width}
	t.wheel_constraints[3] = {L4, L1, length}

	big_cross_length := math.sqrt(width*width + length*length)
	t.wheel_constraints[4] = {L1, R4, big_cross_length}
	t.wheel_constraints[5] = {R1, L4, big_cross_length}

	small_cross_length := math.sqrt(width*width + (length/3) * (length/3))
	t.wheel_constraints[6] = {L4, R3, small_cross_length}
	t.wheel_constraints[7] = {R4, L3, small_cross_length}
	t.wheel_constraints[8] = {R3, L2, small_cross_length}
	t.wheel_constraints[9] = {L3, R2, small_cross_length}
	t.wheel_constraints[10] = {L2, R1, small_cross_length}
	t.wheel_constraints[11] = {R2, L1, small_cross_length}
	
	t.wheel_constraints[12] = {L3, R3, width}
	t.wheel_constraints[13] = {L2, R2, width}

	small_length := length / 3
	t.wheel_constraints[14] = {L4, L3, small_length}
	t.wheel_constraints[15] = {L3, L2, small_length}
	t.wheel_constraints[16] = {L2, L1, small_length}
	t.wheel_constraints[17] = {R4, R3, small_length}
	t.wheel_constraints[18] = {R3, R2, small_length}
	t.wheel_constraints[19] = {R2, R1, small_length}

	t.body_mesh = &asset_provider.meshes[.Tank_Body]
	t.wheel_mesh = &asset_provider.meshes[.Tank_Wheel]

	t.buttons_positions[0] = {-0.7, 1.9, 1.5}
	t.buttons_positions[1] = {0, 1.9, 1.5}
	t.buttons_positions[2] = {0.7, 1.9, 1.5}

	return t
}

update_tank :: proc(tank : ^Tank, delta_time : f32) {

	// move_input := input.DEBUG_get_key_axis(.K, .I)
	// turn_input := -input.DEBUG_get_key_axis(.J, .L)

	move_input := cast(f32) 1 if tank.auto_drive_on else 0
	turn_input := cast(f32) (int(tank.turn_left) - int(tank.turn_right))

	// reset these
	tank.turn_left = false
	tank.turn_right = false

	// Todo(Leo): use physics delta time
	step := TANK_SPEED * delta_time * move_input
	forward_left 	:= linalg.normalize(tank.wheel_positions[L1] - tank.wheel_positions[L4])
	forward_right 	:= linalg.normalize(tank.wheel_positions[R1] - tank.wheel_positions[R4])
	forward 		:= (forward_left + forward_right) * 0.5

	across_RL_to_FR := tank.wheel_positions[R1] - tank.wheel_positions[L4]
	across_RR_to_FL := tank.wheel_positions[L1] - tank.wheel_positions[R4]
	up := linalg.normalize(linalg.cross(across_RL_to_FR, across_RR_to_FL))

	center : vec3
	for i in 0..<TANK_WHEEL_COUNT {
		center += tank.wheel_positions[i]
	}
	center /= f32(TANK_WHEEL_COUNT)

	angle := turn_input * delta_time
	rotation := linalg.quaternion_angle_axis(angle, up)
	for i in 0..<TANK_WHEEL_COUNT {
		origined := tank.wheel_positions[i] - center
		turned := linalg.mul(rotation, origined)
		new_position := turned + center

		difference := new_position - tank.wheel_positions[i]

		tank.wheel_positions[i] += difference
		tank.old_wheel_positions[i] += difference

		spin_step := math.sign(linalg.dot(forward, difference)) * linalg.length(difference)
		tank.wheel_spins[i] += spin_step / TANK_WHEEL_RADIUS
	}

	for i in 0..<TANK_WHEEL_COUNT {
		tank.old_wheel_positions[i] += forward * step
		tank.wheel_positions[i] += forward * step
	
		tank.wheel_spins[i] += step / TANK_WHEEL_RADIUS
	}

	for i in 0..<TANK_WHEEL_COUNT {
		tank.wheel_spins[i] = math.mod(tank.wheel_spins[i] + 2 * math.PI, 2 * math.PI)
	}
	// Todo(Leo): this is now using the normal variable delta_time, but we
	// should use fixed, but this is probably same issue as moving this to
	// physics package
	// accelerate by gravity
	gravity_acceleration := vec3{0, 0, -physics.GRAVITATIONAL_ACCELERATION}
	for _ in 0..<physics.ticks_this_frame() {
		for i in 0..<TANK_WHEEL_COUNT {
			current_position 	:= tank.wheel_positions[i]
			old_position 		:= tank.old_wheel_positions[i]
			new_position 		:= current_position + 
									(current_position - old_position) * 0.99 + 
									gravity_acceleration * physics.DELTA_TIME * physics.DELTA_TIME

			tank.old_wheel_positions[i] = current_position
			tank.wheel_positions[i] = new_position
		}

		for _ in 0..<TANK_CONSTRAINT_ITERATIONS {

			// Constrain to ground
			for i in 0..<TANK_WHEEL_COUNT {
				position 	:= tank.wheel_positions[i]
				min_z 		:= sample_height(position.x, position.y, &scene.world) + TANK_WHEEL_RADIUS

				if position.z < min_z {
					position.z = min_z
				}

				tank.wheel_positions[i] = position
			}

			// Constrain to each others
			for c in tank.wheel_constraints {
				a_to_b 				:= tank.wheel_positions[c.index_b] - tank.wheel_positions[c.index_a]
				distance 			:= linalg.length(a_to_b)
				error 				:= distance - c.distance
				error_per_wheel 	:= error / 2

				direction_a := linalg.normalize(a_to_b)
				direction_b := -direction_a

				tank.wheel_positions[c.index_a] += direction_a * error_per_wheel
				tank.wheel_positions[c.index_b] += direction_b * error_per_wheel
			}
		}
	
	}

	// Find the wheel rotations
	right := linalg.normalize(linalg.cross(forward, up))
	base_rotation := mat4{
		right.x, forward.x, up.x, 0,
		right.y, forward.y, up.y, 0,
		right.z, forward.z, up.z, 0,
		0, 0, 0, 1,
	}
	old_body_transform 				:= tank.body_transform
	tank.body_transform 			= linalg.matrix4_translate_f32(center + 0.2 * up) * base_rotation
	tank.body_transform_difference 	= linalg.inverse(old_body_transform) * tank.body_transform

	tank.old_body_position = tank.body_position
	tank.body_position = center
	// body_velocity := tank.body_position - tank.old_body_position

	base_rotation_q 		:= linalg.quaternion_from_matrix4(base_rotation)
	tank.old_body_rotation 	= tank.body_rotation
	tank.body_rotation 		= base_rotation_q

	// debug.draw_wire_sphere(center, 0.3, debug.RED)
	// debug.draw_wire_sphere(center + forward, 0.15, debug.BLUE)
	// debug.draw_wire_sphere(center + up, 0.15, debug.BLUE)

	// debug.draw_wire_cube(tank.wheel_positions[L4] + up, base_rotation_q, vec3(0.2), debug.BLACK)
	// debug.draw_wire_cube(tank.wheel_positions[R4] + up, base_rotation_q, vec3(0.2), debug.RED)
	// debug.draw_wire_cube(tank.wheel_positions[L1] + up, base_rotation_q, vec3(0.2), debug.GREEN)
	// debug.draw_wire_cube(tank.wheel_positions[R1] + up, base_rotation_q, vec3(0.2), debug.YELLOW)

	floor_collider_position := vec3{0, 0, 0.2 + 0.5 * TANK_HULL_THICKNESS}
	floor_collider_size 	:= vec3{TANK_HULL_WIDTH, TANK_HULL_LENGTH, TANK_HULL_THICKNESS}

	wall_collider_position_left := vec3{-(TANK_HULL_WIDTH * 0.5 + 0.05), 0, 1 + 0.2}
	wall_collider_position_righ := vec3{TANK_HULL_WIDTH * 0.5 + 0.05, 0, 1 + 0.2}
	wall_collider_size := vec3{0.1, TANK_HULL_LENGTH, 2}

	front_collider_position := vec3{0, 2.4, 1 + 0.2}
	front_collider_size := vec3{TANK_HULL_WIDTH, 1.2, 2}

	// Cool, this part works great!
	physics.submit_colliders(
		[]physics.BoxCollider{
			{
				center + linalg.quaternion_mul_vector3(base_rotation_q, floor_collider_position), 
				base_rotation_q, 
				floor_collider_size
			},
			{
				center + linalg.quaternion_mul_vector3(base_rotation_q, wall_collider_position_left),
				base_rotation_q,
				wall_collider_size
			},
			{
				center + linalg.quaternion_mul_vector3(base_rotation_q, wall_collider_position_righ),
				base_rotation_q,
				wall_collider_size
			},
			{
				center + linalg.quaternion_mul_vector3(base_rotation_q, front_collider_position),
				base_rotation_q,
				front_collider_size
			},
		},
		nil,
		[]int{int(TEMP_ColliderTag.Tank), 0, 0, 0},
	)

	// spin wheels
	for i in 0..<TANK_WHEEL_COUNT {
		base := base_rotation
		if i < 4 {
			base = base * linalg.matrix4_rotate_f32(math.PI, OBJECT_UP)
			tank.wheel_rotations[i] = base * linalg.matrix4_rotate_f32(tank.wheel_spins[i], OBJECT_RIGHT)
		} else {
			tank.wheel_rotations[i] = base * linalg.matrix4_rotate_f32(-tank.wheel_spins[i], OBJECT_RIGHT)
		}
	}

	// inside trigger volume
	tank.inside_trigger_volume = {
		center + linalg.quaternion_mul_vector3(base_rotation_q, vec3{0, 0, 1}),
		base_rotation_q,
		{TANK_HULL_WIDTH, TANK_HULL_LENGTH, 2},
	}

	// front camera_placement
	tank.front_camera.position = tank.body_position + linalg.quaternion_mul_vector3(tank.body_rotation, TANK_FRONT_CAMERA_POSITION_LS)
	tank.front_camera.rotation = tank.body_rotation
}

// Todo(Leo): Allocates from temp_allocator
tank_get_button_positions :: proc(t : ^Tank) -> []vec3 {

	p := make([]vec3, len(t.buttons_positions), context.temp_allocator)
	for b, i in tank.buttons_positions {
		p[i] = linalg.quaternion_mul_vector3(t.body_rotation, b) + tank.body_position
		debug.draw_wire_sphere(p[i], 0.15, debug.BLUE)	
	}
	return p
}

tank_controls_press_button :: proc(t : ^Tank, index : int) {
	switch index {
		case 1: t.auto_drive_on = !t.auto_drive_on
	}
} 

tank_controls_hold_button :: proc(t : ^Tank, index : int) {
	switch index {
		case 0: t.turn_left = true 
		case 2: t.turn_right = true 
	}
}
 
render_tank :: proc(tank : ^Tank) {
	// // body
	graphics.set_basic_material({0.4, 0.44, 0.5}, &asset_provider.textures[.White])
	graphics.draw_mesh(tank.body_mesh, tank.body_transform)

	// wheels
	graphics.set_basic_material({0.25, 0.22, 0.2}, &asset_provider.textures[.White])
	for p, i in tank.wheel_positions {
		local_transform := linalg.matrix4_translate_f32(p) * tank.wheel_rotations[i]
		graphics.draw_mesh(tank.wheel_mesh, local_transform)
	}
}

tank_get_parent_position :: proc(t : ^Tank) -> vec3 {
	return t.body_position
}