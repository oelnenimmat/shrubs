package common

import "core:math/linalg"

vec2 :: linalg.Vector2f32
vec3 :: linalg.Vector3f32
vec4 :: linalg.Vector4f32
mat3 :: linalg.Matrix3f32
mat4 :: linalg.Matrix4f32

quaternion :: linalg.Quaternionf32

// RIGHT 		:: vec3 {1, 0, 0}
// FORWARD 	:: vec3 {0, 1, 0}
// UP 			:: vec3 {0, 0, 1}

// LEFT 		:: vec3 {-1, 0, 0}
// BACK 		:: vec3 {0, -1, 0}
// DOWN 		:: vec3 {0, 0, -1}

matrix4_mul_point :: proc(mat : mat4, p : vec3) -> vec3 {
	return (mat * vec4 {p.x, p.y, p.z, 1}).xyz
}

matrix4_mul_vector :: proc(mat : mat4, v : vec3) -> vec3 {
	return (mat * vec4 {v.x, v.y, v.z, 0}).xyz
}

matrix4_mul_rotation :: proc(mat : mat4, r : quaternion) -> quaternion {
	return linalg.quaternion_from_matrix4(mat) * r
}