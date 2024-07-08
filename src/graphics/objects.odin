package graphics

import "shrubs:common"

import "core:fmt"

import gl "vendor:OpenGL"

Mesh :: struct {
	vbo 			: u32,
	ebo 			: u32,
	vao 			: u32,

	index_count : i32,
}

create_mesh :: proc(
	vertex_positions 	: []vec3,
	vertex_normals 		: []vec3,
	vertex_texcoords	: []vec2, 
	elements 			: []u16
) -> Mesh {
	// Vertex arrays/slices need to match in size
	vertex_count := len(vertex_positions)
	assert(len(vertex_normals) == vertex_count)
	assert(len(vertex_texcoords) == vertex_count || vertex_texcoords == nil)

	mesh : Mesh
	gl.GenVertexArrays(1, &mesh.vao)
	gl.BindVertexArray(mesh.vao)

	positions_data_size := size_of(vec3) * vertex_count
	normals_data_size 	:= size_of(vec3) * vertex_count
	texcoords_data_size := size_of(vec2) * vertex_count
	buffer_data_size 	:= positions_data_size + normals_data_size + texcoords_data_size

	positions_offset 	:= 0
	normals_offset 		:= positions_offset + positions_data_size
	texcoords_offset 	:= normals_offset + normals_data_size

	// Create and allocate vbo
	gl.GenBuffers(1, &mesh.vbo)
	gl.BindBuffer(gl.ARRAY_BUFFER, mesh.vbo)
	gl.BufferData(gl.ARRAY_BUFFER, buffer_data_size, nil, gl.STATIC_DRAW)

	// Positions
	gl.BufferSubData(gl.ARRAY_BUFFER, positions_offset, positions_data_size, raw_data(vertex_positions))
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, size_of(vec3), uintptr(positions_offset))
	gl.EnableVertexAttribArray(0)

	// Normals
	gl.BufferSubData(gl.ARRAY_BUFFER, normals_offset, normals_data_size, raw_data(vertex_normals))
	gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, size_of(vec3), uintptr(normals_offset))
	gl.EnableVertexAttribArray(1)

	// Texcoords
	gl.BufferSubData(gl.ARRAY_BUFFER, texcoords_offset, texcoords_data_size, raw_data(vertex_texcoords))
	gl.VertexAttribPointer(2, 2, gl.FLOAT, gl.FALSE, size_of(vec2), uintptr(texcoords_offset))
	gl.EnableVertexAttribArray(2)

	// Elements/Triangles
	gl.GenBuffers(1, &mesh.ebo)
	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, mesh.ebo)
	index_data_size := size_of(u16) * len(elements)
	gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, index_data_size, raw_data(elements), gl.STATIC_DRAW)

	mesh.index_count = i32(len(elements))

	return mesh
}

destroy_mesh :: proc(mesh : ^Mesh) {
	gl.DeleteBuffers(1, &mesh.vbo)
	gl.DeleteBuffers(1, &mesh.ebo)
	gl.DeleteBuffers(1, &mesh.vao)

	mesh^ = {}
}

draw_mesh :: proc(mesh : ^Mesh, model : mat4) {
	model := model

	gc := &graphics_context

	gl.UniformMatrix4fv(gc.model_matrix_location, 1, false, auto_cast &model)
	gl.BindVertexArray(mesh.vao)
	gl.DrawElements(gl.TRIANGLES, mesh.index_count, gl.UNSIGNED_SHORT, nil)
}

Texture :: struct {
	opengl_name : u32
}

TextureFilterMode :: enum { Nearest, Linear }

@private
opengl_texture_filter_mode :: proc(fm : TextureFilterMode) -> i32 {
	switch fm {
		case .Nearest: return gl.NEAREST
		case .Linear: return gl.LINEAR_MIPMAP_LINEAR
	}

	return 0
}

@private
use_texture :: proc(texture : Texture, slot := 0) {
	gl.ActiveTexture(gl.TEXTURE0 + u32(slot))
	gl.Enable(gl.TEXTURE_2D)
	gl.BindTexture(gl.TEXTURE_2D, texture.opengl_name)
}

create_color_texture :: proc(
	width, height : int,
	pixels : []common.Color_u8_rgba,
	filter_mode : TextureFilterMode,
) -> Texture {

	pixel_count := width * height
	assert(pixel_count == len(pixels))

	min_filter_mode := opengl_texture_filter_mode(filter_mode)
	mag_filter_mode := gl.LINEAR if min_filter_mode == gl.LINEAR_MIPMAP_LINEAR else min_filter_mode

	name : u32
	gl.GenTextures(1, &name)
	// todo(Leo): Maybe pick and reserve a slot for all housekeeping name activites such as this. maybe
	gl.BindTexture(gl.TEXTURE_2D, name)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, min_filter_mode)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, mag_filter_mode)

	gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, i32(width), i32(height), 0, gl.RGBA, gl.UNSIGNED_BYTE, raw_data(pixels))

	if min_filter_mode == gl.LINEAR_MIPMAP_LINEAR {
		gl.GenerateMipmap(gl.TEXTURE_2D)
	}
	
	gl.BindTexture(gl.TEXTURE_2D, 0)

	return { name }
}

create_alpha_only_texture :: proc(
	width, height : int, 
	pixels : []u8,
	filter_mode : TextureFilterMode,
) -> Texture {

	pixel_count := width * height
	assert(pixel_count == len(pixels))

	min_filter_mode := opengl_texture_filter_mode(filter_mode)
	mag_filter_mode := gl.LINEAR if min_filter_mode == gl.LINEAR_MIPMAP_LINEAR else min_filter_mode

	name : u32
	gl.GenTextures(1, &name)
	// todo(Leo): Maybe pick and reserve a slot for all housekeeping name activites such as this. maybe
	gl.BindTexture(gl.TEXTURE_2D, name)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, min_filter_mode)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, mag_filter_mode)
	
	gl.TexImage2D(gl.TEXTURE_2D, 0, gl.ALPHA, i32(width), i32(height), 0, gl.ALPHA, gl.UNSIGNED_BYTE, raw_data(pixels))

	if min_filter_mode == gl.LINEAR_MIPMAP_LINEAR {
		gl.GenerateMipmap(gl.TEXTURE_2D)
	}

	gl.BindTexture(gl.TEXTURE_2D, 0)

	return { name }
}

destroy_texture :: proc(texture : ^Texture) {
	name := texture.opengl_name
	gl.DeleteTextures(1, &name)
}

/*
draw_mesh_instanced :: proc(mesh : ^Mesh, ib : ^InstanceBuffer) {
	gc := &graphics_context

	gl.BindVertexArray(mesh.vao)

	// SETUP INSTANCE DATA BUFFER
	gl.BindBuffer(gl.ARRAY_BUFFER, ib.buffer)
	gl.VertexAttribPointer(2, 4, gl.FLOAT, gl.FALSE, 2 * size_of(vec4), uintptr(0))
	gl.EnableVertexAttribArray(2)
	gl.VertexAttribDivisor(2, 1)

	gl.BindBuffer(gl.ARRAY_BUFFER, ib.buffer)
	gl.VertexAttribPointer(3, 4, gl.FLOAT, gl.FALSE, 2 * size_of(vec4), uintptr(size_of(vec4)))
	gl.EnableVertexAttribArray(3)
	gl.VertexAttribDivisor(3, 1)

	gl.DrawElementsInstanced(
		gl.TRIANGLES, 
		mesh.index_count, 
		gl.UNSIGNED_SHORT, 
		nil, 
		ib.count,
	)
}
*/

Buffer :: struct {
	buffer 			: u32,
	is_writeable 	: bool,
}

create_buffer :: proc(data_size : int, needs_to_be_writeable := false) -> Buffer {	
	b : Buffer
	b.is_writeable = needs_to_be_writeable

	gl.GenBuffers(1, &b.buffer)
	gl.BindBuffer(gl.SHADER_STORAGE_BUFFER, b.buffer)

	flags : u32 = gl.DYNAMIC_STORAGE_BIT if b.is_writeable else 0

	// Todo(Leo): maybe use gl.BufferData instead, the usage can be specified
	gl.BufferStorage(gl.SHADER_STORAGE_BUFFER, data_size, nil, flags)

	return b
}

@(warning="Not implemented")
destroy_buffer :: proc(ib : ^Buffer) {}

buffer_write_data :: proc(b : ^Buffer, data : []$DataType) {
	assert(b.is_writeable)

	size := len(data) * size_of(DataType)
	data := raw_data(data)

	gl.BindBuffer(gl.SHADER_STORAGE_BUFFER, b.buffer)
	gl.BufferSubData(gl.SHADER_STORAGE_BUFFER, 0, size, data)
}
