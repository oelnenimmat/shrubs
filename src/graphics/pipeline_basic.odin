package graphics

import "core:fmt"

import gl "vendor:OpenGL"

// There is one instance of this in graphics context
@private
BasicPipeline :: struct {
	shader_program : u32,

	model_matrix_location 	: i32,	

	surface_color_location 		: i32,
	surface_texture_slot 		: u32,
	surface_texture_location 	: i32,
}

// Not used for now, just passing the fields as params to set_material
// There can be many instances of these in game/application
// BasicMaterial :: struct {
// 	surface_texture 	: Texture,
// 	color 			: Color_u8_rgba,
// }

// This is called once in init graphics context
@private
create_basic_pipeline :: proc() -> BasicPipeline {
	pl : BasicPipeline

	vertex_shader_source 	:= #load("../shaders/basic.vert", cstring)
	frag_shader_source 		:= #load("../shaders/basic.frag", cstring)
	pl.shader_program 		= create_shader_program(vertex_shader_source, frag_shader_source)

	pl.model_matrix_location 		= gl.GetUniformLocation(pl.shader_program, "model")

	pl.surface_color_location 		= gl.GetUniformLocation(pl.shader_program, "surface_color")
	pl.surface_texture_location 	= gl.GetUniformLocation(pl.shader_program, "surface_texture")
	pl.surface_texture_slot 		= 10

	return pl
}

// This is called when changing the pipeline, ideally once per frame
setup_basic_pipeline :: proc () {
	pl := &graphics_context.basic_pipeline
	
	gl.UseProgram(pl.shader_program)
	
	gl.Uniform1i(pl.surface_texture_location, i32(pl.surface_texture_slot))

	gl.Enable(gl.CULL_FACE)
	gl.PolygonMode(gl.FRONT_AND_BACK, gl.FILL)
	gl.Disable(gl.BLEND)
	gl.Enable(gl.DEPTH_TEST)

	// set per draw locations for mesh rendering
	graphics_context.model_matrix_location = pl.model_matrix_location
}

// This is called once for each change of material
// set_basic_material :: proc(material : ^BasicMaterial) {
set_basic_material :: proc(color : vec3, texture : ^Texture) {
	pl := &graphics_context.basic_pipeline

	set_texture_2D(texture, pl.surface_texture_slot)

	color := color
	gl.Uniform3fv(pl.surface_color_location, 1, auto_cast &color)
}