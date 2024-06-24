package graphics

import gl "vendor:OpenGL"

// There is one instance of this in graphics context
@private
BasicPipeline :: struct {
	projection_matrix_location 	: i32,
	view_matrix_location 		: i32,	

	main_texture_slot : u32,
}

// There can be many instances of these in game/application
BasicMaterial :: struct {
	main_texture 	: Texture,
	color 			: Color_u8_rgba,
}

// This is called once in init graphics context
@private
create_basic_pipeline :: proc() -> BasicPipeline {
	// create shaders
	// get uniform locations

	pipeline : BasicPipeline

	return pipeline
}

// This is called when changing the pipeline, ideally once per frame
setup_basic_pipeline :: proc (projection, view : mat4 /*, lighting : ^Lighting */) {
	projection := projection
	view := view

	gc := &graphics_context

	gl.Enable(gl.CULL_FACE)

	gl.Uniform4fv(gc.basic_pipeline.projection_matrix_location, 1, auto_cast &projection)
	gl.Uniform4fv(gc.basic_pipeline.view_matrix_location, 1, auto_cast &view)

	// set lighting
}

// This is called once for each change of material
set_basic_material :: proc(material : ^BasicMaterial) {
	gc := &graphics_context

	gl.ActiveTexture(gl.TEXTURE0 + gc.basic_pipeline.main_texture_slot)
	gl.Enable(gl.TEXTURE_2D)
	gl.BindTexture(gl.TEXTURE_2D, material.main_texture.opengl_name)
}