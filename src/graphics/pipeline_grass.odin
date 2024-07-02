package graphics

import "core:fmt"

import gl "vendor:OpenGL"

@private
GrassPipeline :: struct {
	shader_program : u32,

	projection_matrix_location : i32,
	view_matrix_location : i32,

	// lighting
	light_direction_location : i32,
	light_color_location : i32,
	ambient_color_location : i32,

	// wind
	wind_location : i32,

	// Todo(Leo): these are not set properly quite yet
	field_texture_slot : u32,
}

@private
create_grass_pipeline :: proc() -> GrassPipeline {
	pl : GrassPipeline

	// Compile time generated slices to program memory, no need to delete after.
	// Now we don't need to worry about shader files being present runtime.
	vertex_shader_source := #load("../shaders/grass.vert", cstring)
	frag_shader_source := #load("../shaders/grass.frag", cstring)

	pl.shader_program = create_shader_program(vertex_shader_source, frag_shader_source)

	pl.view_matrix_location 		= gl.GetUniformLocation(pl.shader_program, "view")
	pl.projection_matrix_location 	= gl.GetUniformLocation(pl.shader_program, "projection")

	pl.light_direction_location 	= gl.GetUniformLocation(pl.shader_program, "light_direction")
	pl.light_color_location 		= gl.GetUniformLocation(pl.shader_program, "light_color")
	pl.ambient_color_location 		= gl.GetUniformLocation(pl.shader_program, "ambient_color")

	pl.wind_location = gl.GetUniformLocation(pl.shader_program, "wind_direction_amount")

	return pl
}

setup_grass_pipeline :: proc(
	projection, view : mat4,
	light_direction : vec3,
	light_color : vec3,
	ambient_color : vec3,
	wind_direction : vec3,
	wind_amount : f32,
) {
	projection := projection
	view := view

	light_direction := light_direction
	light_color := light_color
	ambient_color := ambient_color

	pl := &graphics_context.grass_pipeline
	gl.UseProgram(pl.shader_program)

	// View
	gl.UniformMatrix4fv(pl.projection_matrix_location, 1, false, auto_cast &projection)
	gl.UniformMatrix4fv(pl.view_matrix_location, 1, false, auto_cast &view)

	// Lighting
	gl.Uniform3fv(pl.light_direction_location, 1, auto_cast &light_direction)
	gl.Uniform3fv(pl.light_color_location, 1, auto_cast &light_color)
	gl.Uniform3fv(pl.ambient_color_location, 1, auto_cast &ambient_color)

	// Wind
	direction_amount := vec4{wind_direction.x, wind_direction.y, wind_direction.z, wind_amount}
	gl.Uniform4fv(pl.wind_location, 1, auto_cast &direction_amount)	

	gl.Disable(gl.CULL_FACE)
	gl.PolygonMode(gl.FRONT_AND_BACK, gl.FILL)
	gl.Disable(gl.BLEND)
	gl.Enable(gl.DEPTH_TEST)

	// no need for model matrix
}

set_grass_material :: proc(field_texture : ^Texture) {
	pl := &graphics_context.grass_pipeline

	gl.ActiveTexture(gl.TEXTURE0 + pl.field_texture_slot)
	gl.Enable(gl.TEXTURE_2D)
	gl.BindTexture(gl.TEXTURE_2D, field_texture.opengl_name)
}