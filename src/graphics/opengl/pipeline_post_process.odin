package graphics

import gl "vendor:OpenGL"

PostProcessPipeline :: struct {
	program : u32,

	params_location : i32,
}

@private
create_post_process_pipeline :: proc() -> PostProcessPipeline {
	pl : PostProcessPipeline

	vertex_source := #load("../../shaders/post_process.vert", cstring)
	fragment_source := #load("../../shaders/post_process.frag", cstring)

	pl.program = create_shader_program(vertex_source, fragment_source)

	pl.params_location = gl.GetUniformLocation(pl.program, "params")

	return pl
}

dispatch_post_process_pipeline :: proc(render_target : ^RenderTarget, exposure : f32) {
	pl := &graphics_context.post_process_pipeline

	// gl.DebugMessageInsert(gl.DEBUG_SOURCE_APPLICATION, gl.DEBUG_TYPE_MARKER, 21, gl.DEBUG_SEVERITY_NOTIFICATION, 0, "")

	gl.UseProgram(pl.program)

	gl.ActiveTexture(gl.TEXTURE0)
	gl.Enable(gl.TEXTURE_2D)
	gl.BindTexture(gl.TEXTURE_2D, render_target.resolve_image)

	gl.Uniform4f(pl.params_location, exposure, 0, 0, 0)

	gl.Enable(gl.CULL_FACE)
	gl.CullFace(gl.BACK)
	gl.PolygonMode(gl.FRONT_AND_BACK, gl.FILL)
	gl.Disable(gl.BLEND)
	gl.Disable(gl.DEPTH_TEST)

	gl.DrawArrays(gl.TRIANGLE_STRIP, 0, 4)
}