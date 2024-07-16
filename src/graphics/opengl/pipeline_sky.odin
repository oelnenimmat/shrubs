package graphics

import gl "vendor:OpenGL"

@private
SkyPipeline :: struct {
	program : u32,
}

@private
create_sky_pipeline :: proc() -> SkyPipeline {
	pl := SkyPipeline {}

	vert := #load("../../shaders/sky.vert", cstring)
	frag := #load("../../shaders/sky.frag", cstring)
	pl.program = create_shader_program(vert, frag)

	return pl
}

// One sky, no need to setup material/pipeline separately
draw_sky :: proc() {
	pl := &graphics_context.sky_pipeline

	gl.UseProgram(pl.program)

	gl.Enable(gl.CULL_FACE)
	gl.PolygonMode(gl.FRONT, gl.FILL)
	gl.Disable(gl.BLEND)
	gl.Enable(gl.DEPTH_TEST)

	gl.DrawArrays(gl.TRIANGLES, 0, 3)
}