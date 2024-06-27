package graphics

import "core:fmt"

import gl "vendor:OpenGL"

// There is one instance of this in graphics context
@private
BasicPipeline :: struct {
	shader_program : u32,

	projection_matrix_location 	: i32,
	view_matrix_location 		: i32,	
	model_matrix_location 		: i32,	

	surface_color_location : i32,

	// lighting
	light_direction_location : i32,
	light_color_location : i32,
	ambient_color_location : i32,

	// Todo(Leo): these are not set properly quite yet
	main_texture_slot : u32,
}

// Not used for now, just passing the fields as params to set_material
// There can be many instances of these in game/application
// BasicMaterial :: struct {
// 	main_texture 	: Texture,
// 	color 			: Color_u8_rgba,
// }

// This is called once in init graphics context
@private
create_basic_pipeline :: proc() -> BasicPipeline {
	// create shaders
	// get uniform locations

	pl : BasicPipeline

	// Compile time generated slices to program memory, no need to delete after.
	// Now we don't need to worry about shader files being present runtime.
	vertex_shader_source := #load("../shaders/basic.vert", cstring)
	frag_shader_source := #load("../shaders/basic.frag", cstring)

	pl.shader_program = create_shader_program(vertex_shader_source, frag_shader_source)

	pl.view_matrix_location 		= gl.GetUniformLocation(pl.shader_program, "view")
	pl.projection_matrix_location 	= gl.GetUniformLocation(pl.shader_program, "projection")
	pl.model_matrix_location 		= gl.GetUniformLocation(pl.shader_program, "model")
	pl.surface_color_location 		= gl.GetUniformLocation(pl.shader_program, "surface_color")

	pl.light_direction_location 	= gl.GetUniformLocation(pl.shader_program, "light_direction")
	pl.light_color_location 		= gl.GetUniformLocation(pl.shader_program, "light_color")
	pl.ambient_color_location 		= gl.GetUniformLocation(pl.shader_program, "ambient_color")

	return pl
}

// This is called when changing the pipeline, ideally once per frame
setup_basic_pipeline :: proc (
	projection, view : mat4,
	light_direction : vec3,
	light_color : vec3,
	ambient_color : vec3,
) {
	projection := projection
	view := view

	light_direction := light_direction
	light_color := light_color
	ambient_color := ambient_color

	pl := &graphics_context.basic_pipeline
	gl.UseProgram(pl.shader_program)

	gl.UniformMatrix4fv(pl.projection_matrix_location, 1, false, auto_cast &projection)
	gl.UniformMatrix4fv(pl.view_matrix_location, 1, false, auto_cast &view)

	gl.Uniform3fv(pl.light_direction_location, 1, auto_cast &light_direction)
	gl.Uniform3fv(pl.light_color_location, 1, auto_cast &light_color)
	gl.Uniform3fv(pl.ambient_color_location, 1, auto_cast &ambient_color)

	gl.Enable(gl.CULL_FACE)
	gl.PolygonMode(gl.FRONT_AND_BACK, gl.FILL)

	// set per draw locations for mesh rendering
	graphics_context.model_matrix_location = pl.model_matrix_location

	// set lighting
}

// This is called once for each change of material
// set_basic_material :: proc(material : ^BasicMaterial) {
set_basic_material :: proc(color : vec3, texture : ^Texture) {
	color := color

	pl := &graphics_context.basic_pipeline

	gl.ActiveTexture(gl.TEXTURE0 + pl.main_texture_slot)
	gl.Enable(gl.TEXTURE_2D)
	gl.BindTexture(gl.TEXTURE_2D, texture.opengl_name)

	gl.Uniform3fv(pl.surface_color_location, 1, auto_cast &color)
}