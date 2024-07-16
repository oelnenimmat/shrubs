package graphics

import "core:fmt"

import gl "vendor:OpenGL"

@private
EmissivePipeline :: struct {
	program 					: u32,

	model_matrix_location 		: i32,

	surface_texture_slot 		: u32,
	surface_texture_location	: i32,
}

@private
create_emissive_pipeline :: proc() -> EmissivePipeline {
	pl := EmissivePipeline {}

	vert := #load("../../shaders/basic.vert", cstring)
	frag := #load("../../shaders/emissive.frag", cstring)
	pl.program = create_shader_program(vert, frag)

	pl.model_matrix_location = gl.GetUniformLocation(pl.program, "model")

	pl.surface_texture_location = gl.GetUniformLocation(pl.program, "surface_texture")
	pl.surface_texture_slot = 0

	return pl
}

setup_emissive_pipeline :: proc() {
	pl := &graphics_context.emissive_pipeline

	gl.UseProgram(pl.	program)

	gl.Uniform1i(pl.surface_texture_location, i32(pl.surface_texture_slot))

	gl.Enable(gl.CULL_FACE)
	gl.PolygonMode(gl.FRONT, gl.FILL)
	gl.Disable(gl.BLEND)
	gl.Enable(gl.DEPTH_TEST)

	graphics_context.model_matrix_location = pl.model_matrix_location
}

set_emissive_material :: proc(texture : ^Texture) {
	pl := &graphics_context.emissive_pipeline

	set_texture_2D(texture, pl.surface_texture_slot)
}