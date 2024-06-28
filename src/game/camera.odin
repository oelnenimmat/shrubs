/*
Camera controller for the application.

Todo(Leo): this comment is a lie, also discuss them here
Coordinate systems are discussed in /doc folder
*/

// +private
package game

import "core:math"
import "core:math/linalg"
import "core:math/linalg/glsl"

import "../window"
import "../graphics"
import "../input"


OBJECT_RIGHT 	:: vec3{1, 0, 0}
OBJECT_FORWARD 	:: vec3{0, 1, 0}
OBJECT_UP 		:: vec3{0, 0, 1}

// SETTINGS
VERTICAL_FIELD_OF_VIEW 	:: 1
NEAR_CLIPPING_PLANE 	:: 0.1
FAR_CLIPPING_PLANE 		:: 300.00

CAMERA_TRANSLATION_SPEED :: 2.0
CAMERA_ROTATION_SPEED 	:: 2.0

Camera :: struct {
	position 	: vec3,
	rotation 	: quaternion,
	pan, tilt 	: f32,
	height 		: f32,
}

create_camera :: proc() -> Camera {
	camera : Camera
	reset_camera(&camera)
	return camera
}

reset_camera :: proc(using camera : ^Camera) {
	position 	= {0, 0, 0}
	pan 		= 0
	tilt 		= 0
	height 		= 1.8
}

update_camera :: proc(camera : ^Camera, delta_time : f32) {

	// GET CAMERA INPUT -------------------------------------------------------
	// todo(Leo, Louis): think if we want to handle camera rotation axes here
	// or input. I(Leo) am in favor of here, but wasn't super sure yet.
	x_input := input.DEBUG_get_key_axis(.A, .D) + input.DEBUG_get_key_axis(.Left, .Right)
	y_input := input.camera.move.y
	HACK_z_input := input.camera.move.z

	using linalg

	x_sensitivity := f32(-1)
	y_sensitivity := f32(-1)

	camera.pan += input.camera.look.x * x_sensitivity
	camera.pan = mod(camera.pan, 2 * math.PI)

	camera.tilt += input.camera.look.y * y_sensitivity
	camera.tilt = clamp(camera.tilt, -1.3, 1.3)

	tilt := quaternion_angle_axis_f32(camera.tilt, OBJECT_RIGHT)
	pan := quaternion_angle_axis_f32(camera.pan, OBJECT_UP)

	camera_rotation := pan * tilt

	view_right 		:= normalize(mul(camera_rotation, OBJECT_RIGHT))
	view_forward 	:= normalize(mul(camera_rotation, OBJECT_FORWARD))
	view_up 		:= normalize(mul(camera_rotation, OBJECT_UP))


	flat_right 		:= linalg.normalize(vec3{view_right.x, view_right.y, 0})
	flat_forward 	:= linalg.normalize(vec3{view_forward.x, view_forward.y, 0})

	movement_vector := 	x_input * flat_right +
						y_input * flat_forward
	camera.position += movement_vector * CAMERA_TRANSLATION_SPEED * delta_time 
	camera.position.z = sample_height (camera.position.x, camera.position.y)
	
	camera.height += HACK_z_input * CAMERA_TRANSLATION_SPEED * delta_time

	if input.camera.reset {
		reset_camera(camera)
	}
}


// Todo(Leo): some things here are calculated again that are already calculated in
// update_camera()
camera_get_projection_and_view_matrices :: proc(camera : ^Camera) -> (mat4, mat4) {
	using linalg

	tilt := quaternion_angle_axis_f32(camera.tilt, OBJECT_RIGHT)
	pan := quaternion_angle_axis_f32(camera.pan, OBJECT_UP)

	camera_rotation := pan * tilt

	// view_right 		:= normalize(mul(camera_rotation, OBJECT_RIGHT))
	view_forward 	:= normalize(mul(camera_rotation, OBJECT_FORWARD))
	view_up 		:= normalize(mul(camera_rotation, OBJECT_UP))

	view_position := camera.position + {0, 0, camera.height}

	view_matrix: = glsl.mat4LookAt(
		auto_cast view_position, 
		auto_cast (view_position + view_forward), 
		auto_cast view_up
	)

	window_width, window_height := window.get_window_size()
	aspect_ratio := f32(window_width) / f32(window_height)

	projection_matrix := glsl.mat4Perspective(
		VERTICAL_FIELD_OF_VIEW, 
		aspect_ratio, 
		NEAR_CLIPPING_PLANE, 
		FAR_CLIPPING_PLANE
	)

	return projection_matrix, view_matrix
}