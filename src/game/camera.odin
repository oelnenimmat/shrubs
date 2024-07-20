/*
Camera converts positition and rotation to view matrix and
also provides the projection matrix given the other related
parameters.

Todo(Leo): As of now, camera is also responsible of considering
the coordinate system. This might or might not be good, so think!

Todo(Leo): this comment is a lie, also discuss them here
Coordinate systems are discussed in /doc folder
*/

// +private
package game

import "core:math/linalg"
import "core:math/linalg/glsl"

import "shrubs:window"

OBJECT_RIGHT 	:: vec3{1, 0, 0}
OBJECT_FORWARD 	:: vec3{0, 1, 0}
OBJECT_UP 		:: vec3{0, 0, 1}

// SETTINGS
VERTICAL_FIELD_OF_VIEW 	:: 1
NEAR_CLIPPING_PLANE 	:: 0.1
FAR_CLIPPING_PLANE 		:: 300.00

Camera :: struct {
	position 	: vec3,
	rotation 	: quaternion,
}

create_camera :: proc() -> Camera {
	c : Camera
	c.position = vec3(0)
	c.rotation = quaternion(1)
	return c
}

camera_get_projection_and_view_matrices :: proc(camera : ^Camera) -> (mat4, mat4) {
	using linalg

	// right 	:= normalize(mul(camera.rotation, OBJECT_RIGHT))
	forward := normalize(mul(camera.rotation, OBJECT_FORWARD))
	up 		:= normalize(mul(camera.rotation, OBJECT_UP))

	// Todo(Leo): don't use glsl for this, Odin and glfw have weird things about
	// all look matrices, and don't want to end up with correcting mistakes
	// somewhere else with more mistakes some other where else.
	view_matrix: = glsl.mat4LookAt(
		auto_cast camera.position, 
		auto_cast (camera.position + forward), 
		auto_cast up,
	)

	// Can get each frame; is simpler and is quick lookup. Unnecessary though.
	window_width, window_height := window.get_window_size()
	aspect_ratio := f32(window_width) / f32(window_height)

	// Maybe not calculate each frame. Still, doesn't matter.
	// Todo(Leo): don't use glsl for this, Odin and glfw have weird things about
	// all look matrices, and don't want to end up with correcting mistakes
	// somewhere else with more mistakes some other where else.
	projection_matrix := glsl.mat4Perspective(
		VERTICAL_FIELD_OF_VIEW, 
		aspect_ratio, 
		NEAR_CLIPPING_PLANE, 
		FAR_CLIPPING_PLANE,
	)

	projection_matrix[1,1] *= -1

	return projection_matrix, view_matrix
}