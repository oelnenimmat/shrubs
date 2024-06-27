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
Color_u8_rgba :: [4]u8

// Maybe these need to be tested, maybe not?
@(warning = "Not tested")
dvec3_to_vec3 :: proc(v : dvec3) -> vec3 {
	return {f32(v.x), f32(v.y), f32(v.z)}
}

@(warning = "Not tested")
vec3_to_dvec3 :: proc(v : vec3) -> dvec3 {
	return {f64(v.x), f64(v.y), f64(v.z)}
}


