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


draw_mesh_instanced :: proc(mesh : ^Mesh, ib : ^InstanceBuffer) {
	gc := &graphics_context
	gl.UseProgram(gc.instance_shader_program)

	gl.UniformMatrix4fv(gc.view_matrix_location, 1, false, transmute([^]f32)&gc.view_matrix)
	gl.UniformMatrix4fv(gc.projection_matrix_location, 1, false, transmute([^]f32)&gc.projection_matrix)
	// gl.UniformMatrix4fv(gc.model_matrix_location, 1, false, transmute([^]f32)&model)

	gl.BindVertexArray(mesh.vao)

	// SETUP INSTANCE DATA BUFFER
	gl.BindBuffer(gl.ARRAY_BUFFER, ib.buffer)
	gl.VertexAttribPointer(2, 4, gl.FLOAT, gl.FALSE, 4 * size_of(f32), uintptr(0))
	gl.EnableVertexAttribArray(2)
	gl.VertexAttribDivisor(2, 1)

	gl.DrawElementsInstanced(
		gl.TRIANGLES, 
		mesh.index_count, 
		gl.UNSIGNED_SHORT, 
		nil, 
		ib.count,
	)
}

InstanceBuffer :: struct {
	count 			: i32,
	buffer 			: u32,
	mapped_memory 	: rawptr,
}

create_instance_buffer :: proc(instance_count: int) -> InstanceBuffer {	
	gc := &graphics_context

	ib := InstanceBuffer {}

	instance_size := size_of(vec4)
	instance_data_size := instance_size * instance_count

	gl.GenBuffers(1, &ib.buffer)
	gl.BindBuffer(gl.ARRAY_BUFFER, ib.buffer)
	
	/*
	To use this same memory from both CPU and GPU we need to specify
		- GL_MAP_COHERENT_BIT -> memory is visible on GPU 'immediately' after write
		- GL_MAP_PERSISTENT_BIT -> memory wont change, so same mapping can be used for long times
		- GL_MAP_WRITE_BIT -> OpenGL promises that we can write to memory correctly (we do not need to read)
	Note(Leo): using same memory on GPU and CPU is convenient, but may prevent
	GPU from using optimal memory layout which may cause performance loss. When
	optimizing, check if we can/need to do something different.
	*/
	flags : u32 = gl.MAP_COHERENT_BIT | gl.MAP_PERSISTENT_BIT | gl.MAP_WRITE_BIT
	gl.BufferStorage(gl.ARRAY_BUFFER, instance_data_size, nil, flags)
	ib.mapped_memory = gl.MapBufferRange(gl.ARRAY_BUFFER, 0, instance_data_size, flags)


	// // In this application we basically only render batches of instances, and since instance
	// // buffer is same as vertex buffer and needs to bound to and vertex array object so we create
	// // one for each instance
	// // instance_vertex_array_object : u32
	// {
	// 	// CREATE VERTEX ARRAY OBJECT
	// 	gl.GenVertexArrays(VIRTUAL_FRAME_COUNT, raw_data(&ib.vertex_arrays))

	// 	for i in 0..<VIRTUAL_FRAME_COUNT {
	// 		gl.BindVertexArray(ib.vertex_arrays[i])

	// 		// SETUP PARTICLE MESH VERTEX BUFFER
	// 		gl.BindBuffer(gl.ARRAY_BUFFER, gc.particle_vertex_buffer_object)
	// 		gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * size_of(f32), uintptr(0))
	// 		gl.EnableVertexAttribArray(0)

	// 		// SETUP PARTICLE MESH INDEX BUFFER
	// 		gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, gc.particle_index_buffer_object)

	// 		// SETUP INSTANCE DATA BUFFER
	// 		gl.BindBuffer(gl.ARRAY_BUFFER, ib.buffer_objects[i])
	// 		gl.VertexAttribPointer(1, 4, gl.FLOAT, gl.FALSE, 4 * size_of(f32), uintptr(0))
	// 		gl.EnableVertexAttribArray(1)
	// 		gl.VertexAttribDivisor(1, 1)
	// 	}
	// }

	ib.count 					= i32(instance_count)

	return ib
}

get_instance_buffer_writeable_memory :: proc(ib : ^InstanceBuffer) -> rawptr {
	// ib_internal := &graphics_context.instance_buffer
	return ib.mapped_memory
}


@(warning="Not implemented")
destroy_instance_buffer :: proc(ib : ^InstanceBuffer) {}

// InstanceBuffer :: struct {
// 	count : i32,
// 	vertex_arrays 	: [VIRTUAL_FRAME_COUNT]u32,
// 	buffer_objects 	: [VIRTUAL_FRAME_COUNT]u32,
// 	mapped_memories : [VIRTUAL_FRAME_COUNT]rawptr,
// }

// create_instance_buffer :: proc(instance_count: int) -> InstanceBuffer {	
// 	gc := &graphics_context

// 	ib := InstanceBuffer {}

// 	instance_size := size_of(vec4)
// 	instance_data_size := instance_size * instance_count

// 	gl.GenBuffers(VIRTUAL_FRAME_COUNT, raw_data(&ib.buffer_objects))
// 	for i in 0..<VIRTUAL_FRAME_COUNT {
// 		gl.BindBuffer(gl.ARRAY_BUFFER, ib.buffer_objects[i])
		
// 		/*
// 		To use this same memory from both CPU and GPU we need to specify
// 			- GL_MAP_COHERENT_BIT -> memory is visible on GPU 'immediately' after write
// 			- GL_MAP_PERSISTENT_BIT -> memory wont change, so same mapping can be used for long times
// 			- GL_MAP_WRITE_BIT -> OpenGL promises that we can write to memory correctly (we do not need to read)
// 		Note(Leo): using same memory on GPU and CPU is convenient, but may prevent
// 		GPU from using optimal memory layout which may cause performance loss. When
// 		optimizing, check if we can/need to do something different.
// 		*/
// 		flags : u32 = gl.MAP_COHERENT_BIT | gl.MAP_PERSISTENT_BIT | gl.MAP_WRITE_BIT
// 		gl.BufferStorage(gl.ARRAY_BUFFER, instance_data_size, nil, flags)
// 		ib.mapped_memories[i] = gl.MapBufferRange(gl.ARRAY_BUFFER, 0, instance_data_size, flags)
// 	}


// 	// In this application we basically only render batches of instances, and since instance
// 	// buffer is same as vertex buffer and needs to bound to and vertex array object so we create
// 	// one for each instance
// 	// instance_vertex_array_object : u32
// 	{
// 		// CREATE VERTEX ARRAY OBJECT
// 		gl.GenVertexArrays(VIRTUAL_FRAME_COUNT, raw_data(&ib.vertex_arrays))

// 		for i in 0..<VIRTUAL_FRAME_COUNT {
// 			gl.BindVertexArray(ib.vertex_arrays[i])

// 			// SETUP PARTICLE MESH VERTEX BUFFER
// 			gl.BindBuffer(gl.ARRAY_BUFFER, gc.particle_vertex_buffer_object)
// 			gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * size_of(f32), uintptr(0))
// 			gl.EnableVertexAttribArray(0)

// 			// SETUP PARTICLE MESH INDEX BUFFER
// 			gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, gc.particle_index_buffer_object)

// 			// SETUP INSTANCE DATA BUFFER
// 			gl.BindBuffer(gl.ARRAY_BUFFER, ib.buffer_objects[i])
// 			gl.VertexAttribPointer(1, 4, gl.FLOAT, gl.FALSE, 4 * size_of(f32), uintptr(0))
// 			gl.EnableVertexAttribArray(1)
// 			gl.VertexAttribDivisor(1, 1)
// 		}
// 	}

// 	ib.count 					= i32(instance_count)

// 	return ib
// }

// get_instance_buffer_writeable_memory :: proc(ib : ^InstanceBuffer) -> rawptr {
// 	// ib_internal := &graphics_context.instance_buffer
// 	return ib.mapped_memories[graphics_context.virtual_frame_index]
// }


// @(warning="Not implemented")
// destroy_instance_buffer :: proc(ib : ^InstanceBuffer) {}

CUBE_VERTEX_POSITIONS :: []vec3 {
	{-0.5, -0.5, -0.5},
	{0.5, -0.5, -0.5},
	{-0.5, 0.5, -0.5},
	{0.5, 0.5, -0.5},

	{-0.3, -0.3, 0.3},
	{0.3, -0.3, 0.3},
	{-0.3, 0.3, 0.3},
	{0.3, 0.3, 0.3},
}

CUBE_VERTEX_NORMALS :: []vec3 {
	{-0.5, -0.5, -0.5},
	{0.5, -0.5, -0.5},
	{-0.5, 0.5, -0.5},
	{0.5, 0.5, -0.5},

	{-0.5, -0.5, 0.5},
	{0.5, -0.5, 0.5},
	{-0.5, 0.5, 0.5},
	{0.5, 0.5, 0.5},
}

CUBE_ELEMENTS :: []u16 {
	0, 2, 1,  1, 2, 3,
	5, 7, 4,  4, 7, 6, 

	4, 6, 0,  0, 6, 2,
	1, 3, 5,  5, 3, 7,

	0, 1, 4,  4, 1, 5,
	2, 6, 3,  3, 6, 7,
}
