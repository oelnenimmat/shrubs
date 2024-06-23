package graphics

import gl "vendor:OpenGL"

Mesh :: struct {
	positions_vbo 	: u32,
	normals_vbo 	: u32,
	ebo 			: u32,
	vao 			: u32,

	index_count : i32,
}

create_mesh :: proc(vertex_positions : []vec3, vertex_normals : []vec3, elements : []u16) -> Mesh {
	mesh : Mesh

	gl.GenVertexArrays(1, &mesh.vao)
	gl.GenBuffers(1, &mesh.positions_vbo)
	gl.GenBuffers(1, &mesh.normals_vbo)
	gl.GenBuffers(1, &mesh.ebo)

	gl.BindVertexArray(mesh.vao)

	// POSITIONS
	gl.BindBuffer(gl.ARRAY_BUFFER, mesh.positions_vbo)
	gl.BufferData(
		gl.ARRAY_BUFFER, 
		size_of(vec3) * len(vertex_positions), 
		raw_data(vertex_positions), 
		gl.STATIC_DRAW,
	)

	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, size_of(vec3), uintptr(0))
	gl.EnableVertexAttribArray(0)

	// NORMALS
	gl.BindBuffer(gl.ARRAY_BUFFER, mesh.normals_vbo)
	gl.BufferData(
		gl.ARRAY_BUFFER,
		size_of(vec3) * len(vertex_normals),
		raw_data(vertex_normals),
		gl.STATIC_DRAW,
	)

	gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, size_of(vec3), uintptr(0))
	gl.EnableVertexAttribArray(1)


	// ELEMENTS
	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, mesh.ebo)
	index_data_size := size_of(u16) * len(elements)
	gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, index_data_size, raw_data(elements), gl.STATIC_DRAW)

	mesh.index_count = i32(len(elements))

	return mesh
}

draw_mesh :: proc(mesh : ^Mesh, model : mat4) {
	model := model

	gc := &graphics_context
	gl.UseProgram(gc.shader_program)

	gl.UniformMatrix4fv(gc.view_matrix_location, 1, false, transmute([^]f32)&gc.view_matrix)
	gl.UniformMatrix4fv(gc.projection_matrix_location, 1, false, transmute([^]f32)&gc.projection_matrix)
	gl.UniformMatrix4fv(gc.model_matrix_location, 1, false, transmute([^]f32)&model)

	gl.BindVertexArray(mesh.vao)

	gl.DrawElements(
		gl.TRIANGLES, 
		mesh.index_count, 
		gl.UNSIGNED_SHORT, 
		nil, 
	)
}


Texture :: struct {
	opengl_name : u32
}

use_texture :: proc(texture : Texture, slot := 0) {
	gl.ActiveTexture(gl.TEXTURE0 + u32(slot))
	gl.Enable(gl.TEXTURE_2D)
	gl.BindTexture(gl.TEXTURE_2D, texture.opengl_name)
}