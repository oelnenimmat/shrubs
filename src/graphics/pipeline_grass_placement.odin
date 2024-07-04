package graphics

import gl "vendor:OpenGL"

@private
GrassPlacementPipeline :: struct {
	program : u32,

	placement_texture_location 	: i32,
	noise_params_location 		: i32,
	world_params_location 		: i32,
	grass_params_location 		: i32,

	placement_texture_slot : u32,
}

@private
create_grass_placement_pipeline :: proc () -> GrassPlacementPipeline {
	pl : GrassPlacementPipeline

	compute_shader_source := #load("../shaders/grass_placement.compute", cstring)

	pl.program = create_compute_shader_program(compute_shader_source)

	pl.placement_texture_location = gl.GetUniformLocation(pl.program, "placement_texture")
	pl.noise_params_location = gl.GetUniformLocation(pl.program, "noise_params")
	pl.world_params_location = gl.GetUniformLocation(pl.program, "world_params")
	pl.grass_params_location = gl.GetUniformLocation(pl.program, "grass_params")

	return pl
}

dispatch_grass_placement_pipeline :: proc (
	buffer : ^InstanceBuffer, 
	placement_texture : ^Texture,
	blade_count : int,
) {
	pl := &graphics_context.grass_placement_pipeline

	blade_count := u32(blade_count)

	gl.UseProgram(pl.program)
	gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 0, buffer.buffer)

	set_texture_2D(placement_texture, pl.placement_texture_slot)

	gl.Uniform4f(pl.noise_params_location, 563, 0.1, 5, 0)
	gl.Uniform4f(pl.world_params_location, -25.0, -25.0, 50.0, 50.0)
	gl.Uniform4f(pl.grass_params_location, 0.4, 0.2, f32(blade_count), 0)

	// 512 blades per side, work group is 32 x 32
	gl.DispatchCompute(blade_count / 32, blade_count / 32, 1)
	gl.MemoryBarrier(gl.ALL_BARRIER_BITS)
}