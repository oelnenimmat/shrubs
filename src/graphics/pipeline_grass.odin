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
	wind_params_location : i32,

	debug_params_location : i32,

	// textures
	field_texture_location : i32,	
	wind_texture_location : i32,	

	field_texture_slot : u32,	
	wind_texture_slot : u32,	
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

	pl.wind_params_location 		= gl.GetUniformLocation(pl.shader_program, "wind_params")

	pl.debug_params_location 		= gl.GetUniformLocation(pl.shader_program, "debug_params")

	pl.field_texture_location = gl.GetUniformLocation(pl.shader_program, "field_texture")
	pl.wind_texture_location = gl.GetUniformLocation(pl.shader_program, "wind_texture")

	pl.field_texture_slot = 0
	pl.wind_texture_slot = 1
	
	return pl
}

setup_grass_pipeline :: proc(
	projection, view : mat4,
	light_direction : vec3,
	light_color : vec3,
	ambient_color : vec3,
	wind_offset : vec2,
	debug_params : vec4,
	cull_back : bool,
	cull_front : bool,
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
	gl.Uniform4f(pl.wind_params_location, wind_offset.x, wind_offset.y, 0.005, 0);

	gl.Uniform1i(pl.field_texture_location, i32(pl.field_texture_slot))
	gl.Uniform1i(pl.wind_texture_location, i32(pl.wind_texture_slot))

	debug_params := debug_params
	gl.Uniform4fv(pl.debug_params_location, 1, auto_cast &debug_params)

	// Options
	if cull_back {
		gl.Enable(gl.CULL_FACE)
		gl.CullFace(gl.BACK)
	} else if cull_front {
		gl.Enable(gl.CULL_FACE)
		gl.CullFace(gl.FRONT)
	} else {
		gl.Disable(gl.CULL_FACE)
	}

	gl.PolygonMode(gl.FRONT_AND_BACK, gl.FILL)
	gl.Disable(gl.BLEND)
	gl.Enable(gl.DEPTH_TEST)



	// no need for model matrix
}

set_grass_material :: proc(field_texture : ^Texture, wind_texture : ^Texture) {
	pl := &graphics_context.grass_pipeline

	set_texture_2D(field_texture, pl.field_texture_slot)
	set_texture_2D(wind_texture, pl.wind_texture_slot)
}

draw_grass :: proc(mesh : ^Mesh, ib : ^InstanceBuffer, count : int) {
	gc := &graphics_context

	gl.BindVertexArray(mesh.vao)

	// SETUP INSTANCE DATA BUFFER
	gl.BindBuffer(gl.ARRAY_BUFFER, ib.buffer)
	gl.VertexAttribPointer(2, 4, gl.FLOAT, gl.FALSE, 2 * size_of(vec4), uintptr(0))
	gl.EnableVertexAttribArray(2)
	gl.VertexAttribDivisor(2, 1)

	gl.BindBuffer(gl.ARRAY_BUFFER, ib.buffer)
	gl.VertexAttribPointer(3, 4, gl.FLOAT, gl.FALSE, 2 * size_of(vec4), uintptr(size_of(vec4)))
	gl.EnableVertexAttribArray(3)
	gl.VertexAttribDivisor(3, 1)

	// Stupid Wild Ass Guess
	SWAG_GRASS_VERTEX_COUNT :: 9

	gl.DrawArraysInstanced(
		gl.TRIANGLE_STRIP,
		0,
		SWAG_GRASS_VERTEX_COUNT,
		i32(count),
	)
}
