package common

import "core:math/linalg"

vec2 :: linalg.Vector2f32
vec3 :: linalg.Vector3f32
vec4 :: linalg.Vector4f32
mat3 :: linalg.Matrix3f32
mat4 :: linalg.Matrix4f32

quaternion :: linalg.Quaternionf32

dvec3 :: linalg.Vector3f64
dvec4 :: linalg.Vector4f64
dmat4 :: linalg.Matrix4f64

Rect_i32 :: struct { x, y, w, h : i32 }
Rect_f32 :: struct { x, y, w, h : f32 }
Color_u8_rgba :: [4]u8

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

// Maybe these need to be tested, maybe not?
@(warning = "Not tested")
dvec3_to_vec3 :: proc(v : dvec3) -> vec3 {
	return {f32(v.x), f32(v.y), f32(v.z)}
}

@(warning = "Not tested")
vec3_to_dvec3 :: proc(v : vec3) -> dvec3 {
	return {f64(v.x), f64(v.y), f64(v.z)}
}

vec4_from_u8_rgba :: proc(u8_rgba : Color_u8_rgba) -> vec4 {
    return {
    	f32(u8_rgba.r),
    	f32(u8_rgba.g),
    	f32(u8_rgba.b),
    	f32(u8_rgba.a)
    } / 255 
}

Rect_f32_from_Rect_i32 :: proc(r : Rect_i32) -> Rect_f32 {
	return { f32(r.x), f32(r.y), f32(r.w), f32(r.h) }
}