package graphics

import "core:fmt"
import "core:math"

import gl "vendor:OpenGL"

@private
GrassPipeline :: struct {
	shader_program : u32,

	projection_matrix_location : i32,
	view_matrix_location : i32,

	// lighting
	light_direction_location 	: i32,
	light_color_location 		: i32,
	ambient_color_location 		: i32,

	// wind
	wind_params_location : i32,

	segment_count_location 	: i32,
	debug_params_location 	: i32,

	// textures
	field_texture_location 	: i32,	
	wind_texture_location 	: i32,	

	bottom_color_location 	: i32,
	top_color_location 		: i32,
	surface_params_location : i32,
	camera_position_location : i32,

	field_texture_slot 	: u32,	
	wind_texture_slot 	: u32,	
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

	pl.segment_count_location 		= gl.GetUniformLocation(pl.shader_program, "segment_count")
	pl.debug_params_location 		= gl.GetUniformLocation(pl.shader_program, "debug_params")

	pl.bottom_color_location 		= gl.GetUniformLocation(pl.shader_program, "bottom_color")
	pl.top_color_location 			= gl.GetUniformLocation(pl.shader_program, "top_color")
	pl.surface_params_location 		= gl.GetUniformLocation(pl.shader_program, "surface_params")
	pl.camera_position_location 		= gl.GetUniformLocation(pl.shader_program, "camera_position")

	pl.field_texture_location 		= gl.GetUniformLocation(pl.shader_program, "field_texture")
	pl.wind_texture_location 		= gl.GetUniformLocation(pl.shader_program, "wind_texture")

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
	camera_position : vec3,
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
	
	gl.Uniform4f(pl.camera_position_location, camera_position.x, camera_position.y, camera_position.z, 0)

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

	// Todo(Leo): optimize by yes culling and just flipping the mesh in vertex shader
	if (cull_back) {
		gl.Enable(gl.CULL_FACE)
	} else {
		gl.Disable(gl.CULL_FACE)
	}
	gl.PolygonMode(gl.FRONT_AND_BACK, gl.FILL)
	gl.Disable(gl.BLEND)
	gl.Enable(gl.DEPTH_TEST)

	// no need for model matrix
}

set_grass_material :: proc(
	field_texture : ^Texture,
	wind_texture : ^Texture,
	bottom_color : vec4,
	top_color : vec4,
	roughness : f32,
) {
	pl := &graphics_context.grass_pipeline

	set_texture_2D(field_texture, pl.field_texture_slot)
	set_texture_2D(wind_texture, pl.wind_texture_slot)

	bottom_color := bottom_color
	top_color := top_color

	gl.Uniform4fv(pl.bottom_color_location, 1, auto_cast &bottom_color)
	gl.Uniform4fv(pl.top_color_location, 1, auto_cast &top_color)
	gl.Uniform4f(
		pl.surface_params_location, 
		roughness, 
		0, 0, 0,
	)
}

draw_grass :: proc(ib : ^InstanceBuffer, instance_count : int, segment_count : int, lod : int) {
	gc := &graphics_context
	pl := &graphics_context.grass_pipeline

	// SETUP INSTANCE DATA BUFFER
	gl.BindBuffer(gl.ARRAY_BUFFER, ib.buffer)
	gl.VertexAttribPointer(0, 4, gl.FLOAT, gl.FALSE, 4 * size_of(vec4), uintptr(0))
	gl.EnableVertexAttribArray(0)
	gl.VertexAttribDivisor(0, 1)

	gl.BindBuffer(gl.ARRAY_BUFFER, ib.buffer)
	gl.VertexAttribPointer(1, 4, gl.FLOAT, gl.FALSE, 4 * size_of(vec4), uintptr(size_of(vec4)))
	gl.EnableVertexAttribArray(1)
	gl.VertexAttribDivisor(1, 1)

	gl.BindBuffer(gl.ARRAY_BUFFER, ib.buffer)
	gl.VertexAttribPointer(2, 4, gl.FLOAT, gl.FALSE, 4 * size_of(vec4), uintptr(2 * size_of(vec4)))
	gl.EnableVertexAttribArray(2)
	gl.VertexAttribDivisor(2, 1)

	gl.BindBuffer(gl.ARRAY_BUFFER, ib.buffer)
	gl.VertexAttribPointer(3, 4, gl.FLOAT, gl.FALSE, 4 * size_of(vec4), uintptr(3 * size_of(vec4)))
	gl.EnableVertexAttribArray(3)
	gl.VertexAttribDivisor(3, 1)

	gl.Uniform4f(pl.segment_count_location, f32(segment_count), f32(lod), 0, 0)
	vertex_count := 3 + (segment_count - 1) * 2

	gl.DrawArraysInstanced(
		gl.TRIANGLE_STRIP,
		0,
		i32(vertex_count),
		i32(instance_count),
	)
}
