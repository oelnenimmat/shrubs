package graphics

import "core:fmt"

import gl "vendor:OpenGL"

// There is one instance of this in graphics context
@private
DebugPipeline :: struct {
	shader_program : u32,

	projection_matrix_location 	: i32,
	view_matrix_location 		: i32,	
	model_matrix_location 		: i32,	

	color_location : i32,
}


// This is called once in init graphics context
@private
create_debug_pipeline :: proc() -> DebugPipeline {
	// create shaders
	// get uniform locations

	pl : DebugPipeline

	// Compile time generated slices to program memory, no need to delete after.
	// Now we don't need to worry about shader files being present runtime.
	vertex_shader_source := #load("../shaders/debug_line.vert", cstring)
	frag_shader_source := #load("../shaders/debug_line.frag", cstring)

	pl.shader_program = create_shader_program(vertex_shader_source, frag_shader_source)

	pl.view_matrix_location 		= gl.GetUniformLocation(pl.shader_program, "view")
	pl.projection_matrix_location 	= gl.GetUniformLocation(pl.shader_program, "projection")
	pl.model_matrix_location 		= gl.GetUniformLocation(pl.shader_program, "model")
	pl.color_location 				= gl.GetUniformLocation(pl.shader_program, "color")

	return pl
}

// This is called when changing the pipeline, ideally once per frame
setup_debug_pipeline :: proc (projection, view : mat4) {
	projection := projection
	view := view

	pl := &graphics_context.debug_pipeline
	gl.UseProgram(pl.shader_program)

	gl.UniformMatrix4fv(pl.projection_matrix_location, 1, false, auto_cast &projection)
	gl.UniformMatrix4fv(pl.view_matrix_location, 1, false, auto_cast &view)

	// set per draw locations for mesh rendering
	graphics_context.model_matrix_location = pl.model_matrix_location

	gl.Disable(gl.CULL_FACE)
	gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE)
	gl.LineWidth(2)
	gl.Disable(gl.BLEND)
	gl.Enable(gl.DEPTH_TEST)
}

// This is called once for each change of material
// set_basic_material :: proc(material : ^BasicMaterial) {
set_debug_line_material :: proc(color : vec3) {
	color := color

	pl := &graphics_context.debug_pipeline
	
	gl.Uniform3fv(pl.color_location, 1, auto_cast &color)
}

// Todo(Leo): we kinda set material on each draw, and it is only color
// so we could just set it here
draw_debug_mesh :: proc(mesh : ^Mesh, model : mat4) {
	model := model

	gc := &graphics_context

	gl.UniformMatrix4fv(gc.model_matrix_location, 1, false, auto_cast &model)
	gl.BindVertexArray(mesh.vao)
	gl.DrawElements(gl.TRIANGLES, mesh.index_count, gl.UNSIGNED_SHORT, nil)
}
