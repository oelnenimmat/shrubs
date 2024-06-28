package game

import "shrubs:assets"
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

TANK_HULL_WIDTH :: 2
TANK_WHEEL_WIDTH :: f32(0.4)
TANK_WHEEL_RADIUS :: 0.35
TANK_SPEED :: 2.5

// Even a small number seems to work fine :)
// Todo(Leo): move all this to physics package, were going to do
// more, probably
CONSTRAINT_ITERATIONS :: 3

FL :: 0
MFL :: 1
MRL :: 2
RL :: 3
FR :: 4
MFR :: 5
MRR :: 6
RR :: 7

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

	// rendering
	body_mesh	: graphics.Mesh,
	wheel_mesh 	: graphics.Mesh,
}

create_tank :: proc() -> Tank {
	t := Tank{}

	t.wheel_positions[FL] = {4, 7, 5}
	t.wheel_positions[FR] = {6, 7, 5}
	t.wheel_positions[RL] = {4, 4, 5}
	t.wheel_positions[RR] = {6, 4, 5}
	t.wheel_positions[MRL] = {4, 5, 5}
	t.wheel_positions[MRR] = {6, 5, 5}
	t.wheel_positions[MFL] = {4, 6, 5}
	t.wheel_positions[MFR] = {6, 6, 5}
	t.old_wheel_positions = t.wheel_positions 


	width := TANK_HULL_WIDTH + TANK_WHEEL_WIDTH
	length := f32(3)
	t.wheel_constraints[0] = {FL, FR, width}
	t.wheel_constraints[1] = {FR, RR, length}
	t.wheel_constraints[2] = {RR, RL, width}
	t.wheel_constraints[3] = {RL, FL, length}

	big_cross_length := math.sqrt(width*width + length*length)
	t.wheel_constraints[4] = {FL, RR, big_cross_length}
	t.wheel_constraints[5] = {FR, RL, big_cross_length}

	small_cross_length := math.sqrt(width*width + (length/3) * (length/3))
	t.wheel_constraints[6] = {RL, MRR, small_cross_length}
	t.wheel_constraints[7] = {RR, MRL, small_cross_length}
	t.wheel_constraints[8] = {MRR, MFL, small_cross_length}
	t.wheel_constraints[9] = {MRL, MFR, small_cross_length}
	t.wheel_constraints[10] = {MFL, FR, small_cross_length}
	t.wheel_constraints[11] = {MFR, FL, small_cross_length}
	
	t.wheel_constraints[12] = {MRL, MRR, width}
	t.wheel_constraints[13] = {MFL, MFR, width}

	small_length := f32(1)
	t.wheel_constraints[14] = {RL, MRL, small_length}
	t.wheel_constraints[15] = {MRL, MFL, small_length}
	t.wheel_constraints[16] = {MFL, FL, small_length}
	t.wheel_constraints[17] = {RR, MRR, small_length}
	t.wheel_constraints[18] = {MRR, MFR, small_length}
	t.wheel_constraints[19] = {MFR, FR, small_length}

	{
		positions, normals, elements := assets.NOT_MEMORY_SAFE_gltf_load_node("assets/tank.glb", "tank_body")
		t.body_mesh = graphics.create_mesh(positions, normals, nil, elements)

		delete(positions)
		delete(normals)
		delete(elements)
	}

	{
		positions, normals, elements := assets.NOT_MEMORY_SAFE_gltf_load_node("assets/tank.glb", "tank_wheel")
		t.wheel_mesh = graphics.create_mesh(positions, normals, nil, elements)

		delete(positions)
		delete(normals)
		delete(elements)
	}

	return t
}

transform_position :: proc(transform : mat4, v : vec3) -> vec3 {
	v := vec4{v.x, v.y, v.z, 1}
	v = transform * v
	return {v.x, v.y, v.z}
}

update_tank :: proc(tank : ^Tank, delta_time : f32) {
	gravity_acceleration := vec3{0, 0, -physics.GRAVITATIONAL_ACCELERATION}

	move_input := input.DEBUG_get_key_axis(.K, .I)
	turn_input := -input.DEBUG_get_key_axis(.J, .L)

	step := TANK_SPEED * delta_time * move_input
	forward_left 	:= linalg.normalize(tank.wheel_positions[FL] - tank.wheel_positions[RL])
	forward_right 	:= linalg.normalize(tank.wheel_positions[FR] - tank.wheel_positions[RR])
	forward 		:= (forward_left + forward_right) * 0.5

	across_RL_to_FR := tank.wheel_positions[FR] - tank.wheel_positions[RL]
	across_RR_to_FL := tank.wheel_positions[FL] - tank.wheel_positions[RR]
	up := linalg.normalize(linalg.cross(across_RL_to_FR, across_RR_to_FL))

	center : vec3
	for i in 0..<TANK_WHEEL_COUNT {
		center += tank.wheel_positions[i]
	}
	center /= f32(TANK_WHEEL_COUNT)

	debug_draw_sphere(center, 0.3, DEBUG_RED)
	debug_draw_sphere(center + forward, 0.15, DEBUG_BLUE)
	debug_draw_sphere(center + up, 0.15, DEBUG_BLUE)

	debug_draw_sphere(tank.wheel_positions[RL] + up, 0.2, DEBUG_BLACK)
	debug_draw_sphere(tank.wheel_positions[RR] + up, 0.2, DEBUG_RED)
	debug_draw_sphere(tank.wheel_positions[FL] + up, 0.2, DEBUG_GREEN)
	debug_draw_sphere(tank.wheel_positions[FR] + up, 0.2, DEBUG_YELLOW)

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
	for i in 0..<TANK_WHEEL_COUNT {
		current_position 	:= tank.wheel_positions[i]
		old_position 		:= tank.old_wheel_positions[i]
		new_position 		:= current_position + 
								(current_position - old_position) * 0.99 + 
								gravity_acceleration * delta_time * delta_time

		tank.old_wheel_positions[i] = current_position
		tank.wheel_positions[i] = new_position
	}

	for _ in 0..<CONSTRAINT_ITERATIONS {

		// Constrain to ground
		for i in 0..<TANK_WHEEL_COUNT {
			position 	:= tank.wheel_positions[i]
			min_z 		:= sample_height(position.x, position.y) + TANK_WHEEL_RADIUS

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

	// Find the wheel rotations
	right := linalg.normalize(linalg.cross(forward, up))
	base_rotation := mat4{
		right.x, forward.x, up.x, 0,
		right.y, forward.y, up.y, 0,
		right.z, forward.z, up.z, 0,
		0, 0, 0, 1,
	}
	tank.body_transform = linalg.matrix4_translate_f32(center + 0.2 * up) * base_rotation


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
}

render_tank :: proc(tank : ^Tank) {
	// // body
	graphics.set_basic_material({0.4, 0.44, 0.5}, &white_texture)
	graphics.draw_mesh(&tank.body_mesh, tank.body_transform)

	// wheels
	graphics.set_basic_material({0.25, 0.22, 0.2}, &white_texture)
	for p, i in tank.wheel_positions {
		local_transform := linalg.matrix4_translate_f32(p) * tank.wheel_rotations[i]
		graphics.draw_mesh(&tank.wheel_mesh, local_transform)
	}
}