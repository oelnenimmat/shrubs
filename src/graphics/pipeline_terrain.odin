package graphics

import "core:fmt"

import gl "vendor:OpenGL"

@private
TerrainPipeline :: struct {
	shader_program : u32,

	model_matrix_location 		: i32,	

	splatter_texture_location 	: i32,
	grass_texture_location 		: i32,
	road_texture_location 		: i32,

	// Todo(Leo): these are not set properly quite yet
	// Should be now
	splatter_texture_slot 	: u32,
	grass_texture_slot 		: u32,
	road_texture_slot 		: u32,
}

@private
create_terrain_pipeline :: proc() -> TerrainPipeline {
	// create shaders
	// get uniform locations

	pl : TerrainPipeline

	// Compile time generated slices to program memory, no need to delete after.
	// Now we don't need to worry about shader files being present runtime.
	vertex_shader_source := #load("../shaders/basic.vert", cstring)
	frag_shader_source := #load("../shaders/terrain.frag", cstring)

	pl.shader_program = create_shader_program(vertex_shader_source, frag_shader_source)

	pl.model_matrix_location 		= gl.GetUniformLocation(pl.shader_program, "model")

	pl.splatter_texture_location 	= gl.GetUniformLocation(pl.shader_program, "splatter_texture")
	pl.grass_texture_location 		= gl.GetUniformLocation(pl.shader_program, "grass_texture")
	pl.road_texture_location 		= gl.GetUniformLocation(pl.shader_program, "road_texture")

	pl.splatter_texture_slot 	= 0
	pl.grass_texture_slot 		= 1
	pl.road_texture_slot 		= 2

	return pl
}

setup_terrain_pipeline :: proc () {
	pl := &graphics_context.terrain_pipeline

	gl.UseProgram(pl.shader_program)

	gl.Uniform1i(pl.splatter_texture_location, i32(pl.splatter_texture_slot))
	gl.Uniform1i(pl.grass_texture_location, i32(pl.grass_texture_slot))
	gl.Uniform1i(pl.road_texture_location, i32(pl.road_texture_slot))

	gl.Enable(gl.CULL_FACE)
	gl.PolygonMode(gl.FRONT_AND_BACK, gl.FILL)
	gl.Disable(gl.BLEND)
	gl.Enable(gl.DEPTH_TEST)
	
	// set per draw locations for mesh rendering
	graphics_context.model_matrix_location = pl.model_matrix_location
}

set_terrain_material :: proc(
	splatter_texture : ^Texture,
	grass_texture : ^Texture,
	road_texture : ^Texture,
) {
	pl := &graphics_context.terrain_pipeline

	set_texture_2D(splatter_texture, pl.splatter_texture_slot)
	set_texture_2D(grass_texture, pl.grass_texture_slot)
	set_texture_2D(road_texture, pl.road_texture_slot)
}