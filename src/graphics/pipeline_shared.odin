package graphics

import gl "vendor:OpenGL"

@private
PipelineShared :: struct {
	per_frame_ubo 	: u32,
	lighting_ubo 	: u32,
	wind_ubo 		: u32,
	debug_ubo 		: u32,

	wind_texture : ^Texture,
}

@private
create_pipeline_shared :: proc() -> PipelineShared {
	ps := PipelineShared {}

	create_buffer :: proc(size : int) -> u32 {
		buffer : u32
		gl.GenBuffers(1, &buffer)
		gl.BindBuffer(gl.UNIFORM_BUFFER, buffer)
		gl.BufferStorage(gl.UNIFORM_BUFFER, size, nil, gl.DYNAMIC_STORAGE_BIT)

		return buffer
	}

	ps.per_frame_ubo 	= create_buffer(size_of(PerFrameUniformBuffer))
	ps.lighting_ubo 	= create_buffer(size_of(LightingUniformBuffer))
	ps.wind_ubo 		= create_buffer(size_of(WindUniformBuffer))
	ps.debug_ubo 		= create_buffer(size_of(DebugUniformBuffer))

	return ps
}

@private
PerFrameUniformBuffer :: struct #align(16) {
	projection 		: mat4,
	view 			: mat4,
}
#assert(size_of(PerFrameUniformBuffer) == 128)

set_per_frame_data :: proc(view, projection : mat4) {
	ps := &graphics_context.pipeline_shared

	p : PerFrameUniformBuffer
	p.view 			= view
	p.projection 	= projection

	gl.BindBuffer(gl.UNIFORM_BUFFER, ps.per_frame_ubo)
	gl.BufferSubData(gl.UNIFORM_BUFFER, 0, size_of(PerFrameUniformBuffer), &p)

	gl.BindBufferBase(gl.UNIFORM_BUFFER, PER_FRAME_BUFFER_BINDING, ps.per_frame_ubo)
}

@private
LightingUniformBuffer :: struct #align(16) {
	camera_position 		: vec4,
	directional_direction 	: vec4,
	directional_color 		: vec4,
	ambient_color 			: vec4,
}
#assert(size_of(LightingUniformBuffer) == 64)

set_lighting_data :: proc(camera_position, directional_direction, directional_color, ambient_color : vec3) {
	ps := &graphics_context.pipeline_shared

	l : LightingUniformBuffer
	l.camera_position.xyz 		= camera_position
	l.directional_direction.xyz = directional_direction
	l.directional_color.rgb 	= directional_color
	l.ambient_color.rgb 		= ambient_color

	gl.BindBuffer(gl.UNIFORM_BUFFER, ps.lighting_ubo)
	gl.BufferSubData(gl.UNIFORM_BUFFER, 0, size_of(LightingUniformBuffer), &l)

	gl.BindBufferBase(gl.UNIFORM_BUFFER, LIGHTING_BUFFER_BINDING, ps.lighting_ubo)
}

@private
WindUniformBuffer :: struct #align(16) {
	texture_offset : vec2,
	texture_scale : f32,

	_ : f32,
}
#assert(size_of(WindUniformBuffer) == 16)

set_wind_data :: proc(texture_offset : vec2, texture_scale : f32, texture : ^Texture) {
	ps := &graphics_context.pipeline_shared

	w : WindUniformBuffer
	w.texture_offset 	= texture_offset
	w.texture_scale 	= texture_scale

	gl.BindBuffer(gl.UNIFORM_BUFFER, ps.wind_ubo)
	gl.BufferSubData(gl.UNIFORM_BUFFER, 0, size_of(WindUniformBuffer), &w)

	gl.BindBufferBase(gl.UNIFORM_BUFFER, WIND_BUFFER_BINDING, ps.wind_ubo)

	ps.wind_texture = texture
}

// Seems waste to use full floats as booleans, but there is one (or at most
// virtual frame count) of these, so doesn't really matter at all and smaller
// types are way more annoying to use and using any integer vector component
// shenanigans means we lose nice typed names and meaning.
@private
DebugUniformBuffer :: struct #align(16) {
	draw_normals 	: f32,
	draw_backfacing : f32,
	draw_lod 		: f32,
	_ : f32,
}
#assert(size_of(DebugUniformBuffer) == 16)

set_debug_data :: proc(draw_normals, draw_backfacing, draw_lod : bool) {
	ps := &graphics_context.pipeline_shared

	d := DebugUniformBuffer{}
	d.draw_normals 		= 1 if draw_normals else 0
	d.draw_backfacing 	= 1 if draw_backfacing else 0
	d.draw_lod 			= 1 if draw_lod else 0

	gl.BindBuffer(gl.UNIFORM_BUFFER, ps.debug_ubo)
	gl.BufferSubData(gl.UNIFORM_BUFFER, 0, size_of(DebugUniformBuffer), &d)

	gl.BindBufferBase(gl.UNIFORM_BUFFER, DEBUG_BUFFER_BINDING, ps.debug_ubo)
}