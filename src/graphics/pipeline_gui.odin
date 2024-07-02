package graphics

import "shrubs:window"

import gl "vendor:OpenGL"

@private
GuiPipeline :: struct {
	shader_program : u32,

	// per frame
	window_size_location : i32,
	
	// per material
	fill_mode_location 				: i32,
	fill_color_location 			: i32,
	font_or_fill_texture_location 	: i32,

	// per draw
	screen_rect_location 	: i32,
	texture_rect_location 	: i32,
	
	font_or_fill_texture_slot : u32,
}

@private
create_gui_pipeline :: proc() -> GuiPipeline{
	pl : GuiPipeline

	// Todo(Leo): this #load is actually unnecessary maybe, as the source
	// is only going to be used such a short time.
    vert_shader_source := #load("../shaders/gui.vert", cstring)
    frag_shader_source := #load("../shaders/gui.frag", cstring)

	pl.shader_program = create_shader_program(vert_shader_source, frag_shader_source)

	pl.window_size_location 		= gl.GetUniformLocation(pl.shader_program, "window_size")

	pl.fill_mode_location 			= gl.GetUniformLocation(pl.shader_program, "fill_mode")
	pl.fill_color_location 			= gl.GetUniformLocation(pl.shader_program, "fill_color")
	pl.font_or_fill_texture_location = gl.GetUniformLocation(pl.shader_program, "font_or_fill_texture")

	pl.screen_rect_location 		= gl.GetUniformLocation(pl.shader_program, "screen_rect")
	pl.texture_rect_location 		= gl.GetUniformLocation(pl.shader_program, "texture_rect")

	pl.font_or_fill_texture_slot = 12

	return pl
}

setup_gui_pipeline :: proc() {
	pl := &graphics_context.gui_pipeline

	gl.UseProgram(pl.shader_program)

    window_width, window_height := window.get_window_size()
	gl.Uniform2f(pl.window_size_location, f32(window_width), f32(window_height))

	gl.Uniform1i(
		pl.font_or_fill_texture_location, 
		i32(pl.font_or_fill_texture_slot),
	)

	gl.Enable(gl.BLEND)
	gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)

	gl.Enable(gl.CULL_FACE)

	gl.PolygonMode(gl.FRONT, gl.FILL)
	gl.Disable(gl.DEPTH_TEST)
}

set_gui_material :: proc(
	fill_color 		: vec4, 
	texture 		: ^Texture, 
	color_fill_mode : enum { Solid = 0, Text_Or_Icon, Image },
) {
	pl := &graphics_context.gui_pipeline
	
	if texture != nil {
		gl.ActiveTexture(gl.TEXTURE0 + pl.font_or_fill_texture_slot)
		gl.Enable(gl.TEXTURE_2D)
		gl.BindTexture(gl.TEXTURE_2D, texture.opengl_name)
	}

	gl.Uniform1i(pl.fill_mode_location, i32(color_fill_mode))

	fill_color := fill_color
	gl.Uniform4fv(pl.fill_color_location, 1, cast(^f32) &fill_color)
}

draw_gui_rect :: proc(screen_rect : Rect_f32, texture_rect : Rect_f32) {
	pl := &graphics_context.gui_pipeline

	// shadow
	screen_rect := screen_rect
	texture_rect := texture_rect
	
	gl.Uniform4fv(pl.screen_rect_location, 1, cast(^f32) &screen_rect)
	gl.Uniform4fv(pl.texture_rect_location, 1, cast(^f32) &texture_rect)

	gl.DrawArrays(gl.TRIANGLE_STRIP, 0, 4)
}