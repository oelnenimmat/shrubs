package graphics

import "core:fmt"

import gl "vendor:OpenGL"

// There is one instance of this in graphics context
@private
TerrainPipeline :: struct {
	shader_program : u32,

	projection_matrix_location 	: i32,
	view_matrix_location 		: i32,
	model_matrix_location 		: i32,	

	surface_color_location : i32,

	// lighting
	light_direction_location 	: i32,
	light_color_location 		: i32,
	ambient_color_location 		: i32,

	splatter_texture_location 	: i32,
	grass_texture_location 		: i32,
	road_texture_location 		: i32,

	debug_params_location : i32,

	// Todo(Leo): these are not set properly quite yet
	// Should be now
	splatter_texture_slot : u32,
	grass_texture_slot : u32,
	road_texture_slot : u32,
}

// This is called once in init graphics context
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

	pl.view_matrix_location 		= gl.GetUniformLocation(pl.shader_program, "view")
	pl.projection_matrix_location 	= gl.GetUniformLocation(pl.shader_program, "projection")
	pl.model_matrix_location 		= gl.GetUniformLocation(pl.shader_program, "model")
	pl.surface_color_location 		= gl.GetUniformLocation(pl.shader_program, "surface_color")

	pl.light_direction_location 	= gl.GetUniformLocation(pl.shader_program, "light_direction")
	pl.light_color_location 		= gl.GetUniformLocation(pl.shader_program, "light_color")
	pl.ambient_color_location 		= gl.GetUniformLocation(pl.shader_program, "ambient_color")

	pl.splatter_texture_location 	= gl.GetUniformLocation(pl.shader_program, "splatter_texture")
	pl.grass_texture_location 		= gl.GetUniformLocation(pl.shader_program, "grass_texture")
	pl.road_texture_location 		= gl.GetUniformLocation(pl.shader_program, "road_texture")

	pl.debug_params_location = gl.GetUniformLocation(pl.shader_program, "debug_params")

	pl.splatter_texture_slot = 0
	pl.grass_texture_slot = 1
	pl.road_texture_slot = 2

	return pl
}

// This is called when changing the pipeline, ideally once per frame
setup_terrain_pipeline :: proc (
	projection, view : mat4,
	light_direction : vec3,
	light_color : vec3,
	ambient_color : vec3,
	debug_params : vec4,
) {
	projection := projection
	view := view

	light_direction := light_direction
	light_color := light_color
	ambient_color := ambient_color

	pl := &graphics_context.terrain_pipeline
	gl.UseProgram(pl.shader_program)

	gl.UniformMatrix4fv(pl.projection_matrix_location, 1, false, auto_cast &projection)
	gl.UniformMatrix4fv(pl.view_matrix_location, 1, false, auto_cast &view)

	gl.Uniform3fv(pl.light_direction_location, 1, auto_cast &light_direction)
	gl.Uniform3fv(pl.light_color_location, 1, auto_cast &light_color)
	gl.Uniform3fv(pl.ambient_color_location, 1, auto_cast &ambient_color)

	debug_params := debug_params
	gl.Uniform4fv(pl.debug_params_location, 1, auto_cast &debug_params)

	gl.Enable(gl.CULL_FACE)
	gl.PolygonMode(gl.FRONT_AND_BACK, gl.FILL)
	gl.Disable(gl.BLEND)
	gl.Enable(gl.DEPTH_TEST)
	
	// set per draw locations for mesh rendering
	graphics_context.model_matrix_location = pl.model_matrix_location

	// set lighting
}

// This is called once for each change of material
// set_terrain_material :: proc(material : ^TerrainMaterial) {
set_terrain_material :: proc(
	splatter_texture : ^Texture,
	grass_texture : ^Texture,
	road_texture : ^Texture,
) {
	// color := color

	pl := &graphics_context.terrain_pipeline

	gl.ActiveTexture(gl.TEXTURE0 + pl.splatter_texture_slot)
	gl.Enable(gl.TEXTURE_2D)
	gl.BindTexture(gl.TEXTURE_2D, splatter_texture.opengl_name)

	gl.ActiveTexture(gl.TEXTURE0 + pl.grass_texture_slot)
	gl.Enable(gl.TEXTURE_2D)
	gl.BindTexture(gl.TEXTURE_2D, grass_texture.opengl_name)

	gl.ActiveTexture(gl.TEXTURE0 + pl.road_texture_slot)
	gl.Enable(gl.TEXTURE_2D)
	gl.BindTexture(gl.TEXTURE_2D, road_texture.opengl_name)

	gl.Uniform1i(pl.splatter_texture_location, i32(pl.splatter_texture_slot))
	gl.Uniform1i(pl.grass_texture_location, i32(pl.grass_texture_slot))
	gl.Uniform1i(pl.road_texture_location, i32(pl.road_texture_slot))

	// gl.Uniform3fv(pl.surface_color_location, 1, auto_cast &color)
}