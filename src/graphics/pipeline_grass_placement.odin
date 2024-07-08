package graphics

import gl "vendor:OpenGL"

@private
GrassPlacementPipeline :: struct {
	program : u32,

	placement_texture_location 	: i32,
	noise_params_location 		: i32,
	chunk_params_location 		: i32,
	world_params_location 		: i32,

	placement_texture_slot : u32,
}

@private
create_grass_placement_pipeline :: proc () -> GrassPlacementPipeline {
	pl : GrassPlacementPipeline

	compute_shader_source := #load("../shaders/grass_placement.compute", cstring)

	pl.program = create_compute_shader_program(compute_shader_source)

	pl.placement_texture_location = gl.GetUniformLocation(pl.program, "placement_texture")
	pl.noise_params_location = gl.GetUniformLocation(pl.program, "noise_params")
	pl.chunk_params_location = gl.GetUniformLocation(pl.program, "chunk_params")
	pl.world_params_location = gl.GetUniformLocation(pl.program, "world_params")

	return pl
}

dispatch_grass_placement_pipeline :: proc (
	types 					: ^Buffer, 
	instances 				: ^Buffer,
	placement_texture 		: ^Texture,
	blade_count 			: int,
	chunk_position 			: vec2,
	chunk_size 				: f32,
) {
	pl := &graphics_context.grass_placement_pipeline

	blade_count := u32(blade_count)

	gl.UseProgram(pl.program)
	gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 0, types.buffer)
	gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 1, instances.buffer)

	set_texture_2D(placement_texture, pl.placement_texture_slot)

	gl.Uniform4f(pl.noise_params_location, 563, 0.1, 5, 0)
	gl.Uniform4f(pl.chunk_params_location, chunk_position.x, chunk_position.y, chunk_size, f32(blade_count))
	gl.Uniform4f(pl.world_params_location, -25.0, -25.0, 50.0, 0.0)

	// work group is 16 x 16
	gl.DispatchCompute(blade_count / 16, blade_count / 16, 1)

	// Todo(Leo): actuaylly think about synchronizing, see e.g. tsushima grass video for more
	gl.MemoryBarrier(gl.ALL_BARRIER_BITS)
}