package application

import "shrubs:assets"
import "shrubs:graphics"
import "shrubs:input"
import "shrubs:physics"

import "core:fmt"
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

TANK_FRONT_AXLE_Y_POSITION :: f32(1.6)
TANK_REAR_AXLE_Y_POSITION :: f32(-1.6)

TANK_WHEEL_LOCAL_POSITIONS :: []vec3 {
	{-1.2, TANK_FRONT_AXLE_Y_POSITION, 0.35},
	{1.2, TANK_FRONT_AXLE_Y_POSITION, 0.35},
	// {-1.2, 0, 0.35},
	// {1.2, 0, 0.35},
	{-1.2, TANK_REAR_AXLE_Y_POSITION, 0.35},
	{1.2, TANK_REAR_AXLE_Y_POSITION, 0.35},
}
TANK_WHEEL_RADIUS :: 0.35

TANK_BODY_LOCAL_POSITION :: vec3{0, 0, 0.35}

TANK_SPEED :: 1.2

Tank :: struct {
	// state
	position : vec3,
	rotation : quaternion,
	z_speed : f32,

	// rendering
	body_mesh	: graphics.Mesh,
	wheel_mesh 	: graphics.Mesh,
}

create_tank :: proc() -> Tank {
	t : Tank

	t.position = {2, 2, 1}
	t.rotation = quaternion(1)

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
	forward := linalg.mul(tank.rotation, OBJECT_FORWARD)
	tank.position += forward * TANK_SPEED * delta_time

	rotate := input.DEBUG_get_key_axis(.O, .P) * -0.01

	rotation := linalg.quaternion_angle_axis(rotate, OBJECT_UP)
	tank.rotation *= rotation

	// physicsy
	tank.z_speed += -physics.GRAVITATIONAL_ACCELERATION * delta_time
	tank.position.z += tank.z_speed

	// collide with terrain
	parent_transform := linalg.matrix4_translate_f32(tank.position) * linalg.matrix4_from_quaternion(tank.rotation)
	max_offset := f32(0)
	for p in TANK_WHEEL_LOCAL_POSITIONS {
		world_position 	:= transform_position(parent_transform, p)
		min_height 		:= sample_height(world_position.x, world_position.y) + TANK_WHEEL_RADIUS
		offset 			:= min_height - world_position.z
		max_offset 		= max(offset, max_offset)
	}
	if max_offset > 0 {
		tank.position.z += max_offset
		tank.z_speed = 0
	}
}

render_tank :: proc(tank : ^Tank) {

	// rotation := linalg.quaternion_between_two_vector3(OBJECT_FORWARD, tank.direction)
	parent_transform := linalg.matrix4_translate_f32(tank.position) * linalg.matrix4_from_quaternion(tank.rotation)

	// body
	graphics.set_basic_material({0.4, 0.44, 0.5}, &white_texture)
	body_local_transform := linalg.matrix4_translate_f32(TANK_BODY_LOCAL_POSITION)
	graphics.draw_mesh(&tank.body_mesh, parent_transform * body_local_transform)

	// wheels
	graphics.set_basic_material({0.25, 0.22, 0.2}, &white_texture)
	for p in TANK_WHEEL_LOCAL_POSITIONS {
		local_transform := linalg.matrix4_translate_f32(p)
		graphics.draw_mesh(&tank.wheel_mesh, parent_transform * local_transform)
	}
}