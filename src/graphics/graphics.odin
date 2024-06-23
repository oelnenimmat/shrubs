package graphics

import "../common"

import "core:fmt"
import "core:math/linalg"

vec3 :: common.vec3
vec4 :: common.vec4
mat4 :: common.mat4

InstanceBuffer :: struct {
	count : i32,
	vertex_arrays 	: [VIRTUAL_FRAME_COUNT]u32,
	buffer_objects 	: [VIRTUAL_FRAME_COUNT]u32,
	mapped_memories : [VIRTUAL_FRAME_COUNT]rawptr,
}

InstanceData :: struct {
	position: vec4,
}

@(warning="Not implemented")
destroy_instance_buffer :: proc(ib : ^InstanceBuffer) {}