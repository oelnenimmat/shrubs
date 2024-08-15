package game

import "shrubs:physics"
import graphics "shrubs:graphics/vulkan"

import "shrubs:debug"

import "core:math/linalg"

HOVERBIKE_MAX_SPEED :: 40

// Todo(Leo): apply some sort of log curve, but this should still be analytical
// v = v0 + at
// a = (v - v0) / t = v / t
HOVERBIKE_TIME_TO_MAX_SPEED :: 1
HOVERBIKE_ACCELERATION :: HOVERBIKE_MAX_SPEED / HOVERBIKE_TIME_TO_MAX_SPEED

DEBUG_HOVERBIKE_BODY_SIZE :: vec3{0.6, 3, 1}

HOVERBIKE_SEAT_LOCAL_POSITION :: vec3{0, -1.8, 0}

Hoverbike :: struct {
	mesh 		: graphics.Mesh,
	material 	: graphics.BasicMaterial,

	position 	: vec3,
	forward 	: vec3,
	up 			: vec3,

	velocity 	: vec3,

	ride_position : vec3,
}

create_hoverbike :: proc() -> Hoverbike {
	h : Hoverbike

	h.position = {20, 20, 0}
	h.velocity = {0, 0, 0}

	h.material = graphics.create_basic_material(&asset_provider.textures[.Proto_Hoverbike])
	h.material.mapped.surface_color = {0.7, 0.5, 0.2, 1}

	h.up = OBJECT_UP
	h.forward = OBJECT_FORWARD

	return h
}

destroy_hoverbike :: proc(h : ^Hoverbike) {
	graphics.destroy_mesh(&h.mesh)
	graphics.destroy_basic_material(&h.material)
}

hoverbike_control :: proc(h : ^Hoverbike, thrust, turn, delta_time : f32) {
	turn 		:= linalg.quaternion_angle_axis_f32(turn * -0.035, h.up)
	h.forward 	= linalg.normalize(linalg.mul(turn, h.forward))

	h.velocity += h.forward * thrust * HOVERBIKE_ACCELERATION * delta_time
}

physics_update_hoverbike :: proc(h : ^Hoverbike) {

	h.velocity += physics.get_gravitational_pull(h.position) * physics.DELTA_TIME
	h.position += h.velocity * physics.DELTA_TIME

	side_drag 		:= 1
	forward_drag 	:= 0.2

	side_direction 			:= linalg.normalize(linalg.cross(h.forward, h.up))
	side_velocity 			:= linalg.projection(h.velocity, side_direction)
	forward_and_up_velocity := h.velocity - side_velocity

	forward_and_up_velocity *= 0.999
	side_velocity 			*= 0.95

	forward_and_up_speed 		:= linalg.length(forward_and_up_velocity)
	forward_and_up_direction 	:= linalg.normalize(forward_and_up_velocity)

	// Todo(Leo): really do some kind of drag force
	forward_and_up_speed = min(forward_and_up_speed, HOVERBIKE_MAX_SPEED)
	forward_and_up_velocity = forward_and_up_speed * forward_and_up_direction


	h.velocity = forward_and_up_velocity + side_velocity

	collider_offset := vec3{0, 0, -0.4}
	collider_radius := f32(1)
	collider := physics.SphereCollider{h.position + collider_offset, collider_radius}

	{
		debug.draw_wire_sphere(collider.position, collider.radius, debug.BRIGHT_PURPLE)
	}

	for c in physics.collide(collider) {
		correction 			:= c.direction * c.depth
		h.position 			+= correction
		velocity_correction := -linalg.projection(h.velocity, c.direction)
		h.velocity 			+= velocity_correction
	}
}

render_hoverbike :: proc(h : ^Hoverbike) {
	graphics.set_basic_material(&h.material)

	rotation : mat4
	{
		f := h.forward
		u := h.up
		r := linalg.normalize(linalg.cross(f, u))
		rotation = {
			r.x, f.x, u.x, 0,
			r.y, f.y, u.y, 0,
			r.z, f.z, u.z, 0,
			0, 0, 0, 1,
		}
	}
	model := linalg.matrix4_translate(h.position) *	rotation;

	graphics.draw_mesh(&asset_provider.meshes[.Proto_Hoverbike], model)
}