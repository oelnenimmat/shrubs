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

import "core:math"
import "core:math/linalg"
import "core:math/linalg/glsl"

import "../input"

PLAYER_CHARACTER_MOVE_SPEED :: 2.0

PlayerCharacter :: struct {
	base_position 	: vec3,
	pan, tilt 		: f32,
	head_height 	: f32,
}

create_player_character :: proc() -> PlayerCharacter {
	pc : PlayerCharacter
	pc.head_height = 1.8
	return pc
}

update_player_character :: proc(pc : ^PlayerCharacter, cam : ^Camera, delta_time : f32) {
	move_right_input 	:= input.DEBUG_get_key_axis(.A, .D)
	move_forward_input 	:= input.DEBUG_get_key_axis(.S, .W)
	HACK_z_input 		:= input.DEBUG_get_key_axis(.F, .R)

	look_right_input 	:= input.DEBUG_get_mouse_movement(0) * 0.005
	look_up_input 		:= input.DEBUG_get_mouse_movement(1) * 0.005

	using linalg

	x_sensitivity := f32(-1)
	y_sensitivity := f32(-1)

	pc.pan += look_right_input * x_sensitivity
	pc.pan = mod(pc.pan, 2 * math.PI)

	pc.tilt += look_up_input * y_sensitivity
	pc.tilt = clamp(pc.tilt, -1.3, 1.3)

	tilt := quaternion_angle_axis_f32(pc.tilt, OBJECT_RIGHT)
	pan := quaternion_angle_axis_f32(pc.pan, OBJECT_UP)

	view_rotation 	:= pan * tilt
	view_right 		:= normalize(mul(view_rotation, OBJECT_RIGHT))
	view_forward 	:= normalize(mul(view_rotation, OBJECT_FORWARD))
	view_up 		:= normalize(mul(view_rotation, OBJECT_UP))

	flat_right 		:= linalg.normalize(vec3{view_right.x, view_right.y, 0})
	flat_forward 	:= linalg.normalize(vec3{view_forward.x, view_forward.y, 0})

	movement_vector := 	move_right_input * flat_right +
						move_forward_input * flat_forward

	pc.base_position += movement_vector * PLAYER_CHARACTER_MOVE_SPEED * delta_time 
	pc.base_position.z = sample_height (pc.base_position.x, pc.base_position.y)
	
	pc.head_height += HACK_z_input * PLAYER_CHARACTER_MOVE_SPEED * delta_time

	cam.position = pc.base_position + OBJECT_UP * pc.head_height

	tilt = quaternion_angle_axis_f32(pc.tilt, OBJECT_RIGHT)
	pan = quaternion_angle_axis_f32(pc.pan, OBJECT_UP)

	camera.rotation = pan * tilt

}
