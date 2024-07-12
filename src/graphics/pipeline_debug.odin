package graphics

import "core:fmt"

import gl "vendor:OpenGL"

// There is one instance of this in graphics context
@private
DebugPipeline :: struct {
	shader_program : u32,

	model_matrix_location 	: i32,	
	color_location 			: i32,
}


// This is called once in init graphics context
@private
create_debug_pipeline :: proc() -> DebugPipeline {
	pl : DebugPipeline

	vertex_shader_source 	:= #load("../shaders/debug_line.vert", cstring)
	frag_shader_source 		:= #load("../shaders/debug_line.frag", cstring)
	pl.shader_program 		= create_shader_program(vertex_shader_source, frag_shader_source)

	pl.model_matrix_location 	= gl.GetUniformLocation(pl.shader_program, "model")
	pl.color_location 			= gl.GetUniformLocation(pl.shader_program, "color")

	return pl
}

// This is called when changing the pipeline, ideally once per frame
setup_debug_pipeline :: proc () {
	pl := &graphics_context.debug_pipeline

	gl.UseProgram(pl.shader_program)

	// set per draw locations for mesh rendering
	// graphics_context.model_matrix_location = pl.model_matrix_location

	gl.Disable(gl.CULL_FACE)
	gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE)
	gl.Disable(gl.BLEND)
	gl.Enable(gl.DEPTH_TEST)
}

// Todo(Leo): we kinda set material on each draw, and it is only color
// so we could just set it here
draw_debug_mesh :: proc(mesh : ^Mesh, model : mat4, color : vec3) {
	pl := &graphics_context.debug_pipeline

	gc := &graphics_context

	color := color
	gl.Uniform3fv(pl.color_location, 1, auto_cast &color)

	model := model
	gl.UniformMatrix4fv(pl.model_matrix_location, 1, false, auto_cast &model)
	gl.BindVertexArray(mesh.vao)
	gl.DrawElements(gl.TRIANGLES, mesh.index_count, gl.UNSIGNED_SHORT, nil)
}
