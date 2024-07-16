package graphics

import "core:fmt"
import "core:math"

import gl "vendor:OpenGL"

@private
GrassPipeline :: struct {
	shader_program : u32,

	segment_count_location 	: i32,

	// Even though the wind texture is picked from shared resources, the
	// location and unit are unique for each pipeline
	// Todo(Leo): change all XXX_texture_slot --> XXX_texture_unit
	wind_texture_location 	: i32,	
	wind_texture_slot 		: u32,	
}

@private
create_grass_pipeline :: proc() -> GrassPipeline {
	pl : GrassPipeline

	// Todo(Leo): if we load these like these, they gonna stay in the program 
	// memory the entire duration, unnecessarily eating up ram
	vertex_shader_source 	:= #load("../../shaders/grass.vert", cstring)
	frag_shader_source		:= #load("../../shaders/grass.frag", cstring)
	pl.shader_program 		= create_shader_program(vertex_shader_source, frag_shader_source)

	pl.segment_count_location 		= gl.GetUniformLocation(pl.shader_program, "segment_count")
	pl.wind_texture_location 		= gl.GetUniformLocation(pl.shader_program, "wind_texture")

	pl.wind_texture_slot = 0
	
	return pl
}

setup_grass_pipeline :: proc(cull_back : bool) {
	pl 		:= &graphics_context.grass_pipeline
	shared 	:= &graphics_context.pipeline_shared

	gl.UseProgram(pl.shader_program)

	gl.Uniform1i(pl.wind_texture_location, i32(pl.wind_texture_slot))
	set_texture_2D(shared.wind_texture, pl.wind_texture_slot)

	// Todo(Leo): optimize by yes culling and just flipping the mesh in vertex shader
	if (cull_back) {
		gl.Enable(gl.CULL_FACE)
	} else {
		gl.Disable(gl.CULL_FACE)
	}
	gl.PolygonMode(gl.FRONT_AND_BACK, gl.FILL)
	gl.Disable(gl.BLEND)
	gl.Enable(gl.DEPTH_TEST)
}

GrassRenderer :: struct {
	vao : u32,	
}

create_grass_renderer :: proc(instance_buffer : ^Buffer) -> GrassRenderer {
	gr := GrassRenderer {}

	gl.GenVertexArrays(1, &gr.vao)
	gl.BindVertexArray(gr.vao)

	gl.BindBuffer(gl.ARRAY_BUFFER, instance_buffer.buffer)

	gl.VertexAttribPointer(0, 4, gl.FLOAT, gl.FALSE, 4 * size_of(vec4), uintptr(0 * size_of(vec4)))
	gl.VertexAttribPointer(1, 4, gl.FLOAT, gl.FALSE, 4 * size_of(vec4), uintptr(1 * size_of(vec4)))
	gl.VertexAttribPointer(2, 4, gl.FLOAT, gl.FALSE, 4 * size_of(vec4), uintptr(2 * size_of(vec4)))
	gl.VertexAttribPointer(3, 4, gl.FLOAT, gl.FALSE, 4 * size_of(vec4), uintptr(3 * size_of(vec4)))

	gl.EnableVertexAttribArray(0)
	gl.EnableVertexAttribArray(1)
	gl.EnableVertexAttribArray(2)
	gl.EnableVertexAttribArray(3)

	gl.VertexAttribDivisor(0, 1)
	gl.VertexAttribDivisor(1, 1)
	gl.VertexAttribDivisor(2, 1)
	gl.VertexAttribDivisor(3, 1)

	return gr
}

destroy_grass_renderer :: proc(gr : ^GrassRenderer) {
	gl.DeleteVertexArrays(1, &gr.vao)
}

draw_grass :: proc(gr : GrassRenderer, instance_count : int, segment_count : int, lod : int) {
	pl := &graphics_context.grass_pipeline

	gl.BindVertexArray(gr.vao)

	gl.Uniform4f(pl.segment_count_location, f32(segment_count), f32(lod), 0, 0)
	vertex_count := 3 + (segment_count - 1) * 2

	gl.DrawArraysInstanced(
		gl.TRIANGLE_STRIP,
		0,
		i32(vertex_count),
		i32(instance_count),
	)
}
