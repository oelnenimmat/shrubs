package graphics

import "core:fmt"

import vk "vendor:vulkan"

Mesh :: struct {
	vertex_buffer 		: vk.Buffer,
	vertex_memory 		: vk.DeviceMemory,

	vertex_buffers 	: []vk.Buffer,
	offsets 		: []vk.DeviceSize,

	index_buffer : vk.Buffer,
	index_memory : vk.DeviceMemory,

	index_count : u32,
}

create_mesh :: proc(
	positions 	: []vec3,
	normals 	: []vec3,
	texcoords	: []vec2, 
	indices 	: []u16,
) -> Mesh {
	g := &graphics

	m : Mesh

	vertex_count := len(positions)
	assert(len(normals) == vertex_count)
	assert(len(texcoords) == vertex_count)

	positions_size 	:= vk.DeviceSize(size_of(vec3) * vertex_count)
	normals_size  	:= vk.DeviceSize(size_of(vec3) * vertex_count)
	texcoords_size  := vk.DeviceSize(size_of(vec2) * vertex_count)

	positions_offset 	:= align_up(vk.DeviceSize(0), 16)
	normals_offset 		:= align_up(positions_offset + positions_size, 16)
	texcoords_offset 	:= align_up(normals_offset + normals_size, 16)

	vertex_buffer_size := align_up(texcoords_offset + texcoords_size, 16)

	m.vertex_buffer, m.vertex_memory = create_buffer_and_memory(
		vertex_buffer_size,
		{ .VERTEX_BUFFER, .TRANSFER_DST },
		{ .DEVICE_LOCAL },
	)

	m.index_count 		= u32(len(indices))
	index_buffer_size 	:= vk.DeviceSize(size_of(u16) * m.index_count)
	m.index_buffer, m.index_memory = create_buffer_and_memory(
		index_buffer_size,
		{ .INDEX_BUFFER, .TRANSFER_DST },
		{ .DEVICE_LOCAL },
	)

	{
		vertex_staging := get_staging_memory(u8, int(vertex_buffer_size))

		positions_slice := vertex_staging[positions_offset : positions_offset + positions_size]
		normals_slice 	:= vertex_staging[normals_offset : normals_offset + normals_size]
		texcoords_slice := vertex_staging[texcoords_offset : texcoords_offset + texcoords_size]

		positions_staging 	:= (cast([^]vec3)raw_data(positions_slice))[0:vertex_count]
		normals_staging 	:= (cast([^]vec3)raw_data(normals_slice))[0:vertex_count]
		texcoords_staging 	:= (cast([^]vec2)raw_data(texcoords_slice))[0:vertex_count]

		copy(positions_staging, positions)
		copy(normals_staging, normals)
		copy(texcoords_staging, texcoords)

		cmd := allocate_and_begin_command_buffer()

		vertex_copy := vk.BufferCopy { 0, 0, vertex_buffer_size }
		vk.CmdCopyBuffer(cmd, g.staging_buffer, m.vertex_buffer, 1, &vertex_copy)

		end_submit_wait_and_free_command_buffer(cmd)
	}

	{
		index_staging := get_staging_memory(u16, int(m.index_count))
		copy(index_staging, indices)

		cmd := allocate_and_begin_command_buffer()

		index_copy := vk.BufferCopy { 0, 0, index_buffer_size }
		vk.CmdCopyBuffer(cmd, g.staging_buffer, m.index_buffer, 1, &index_copy)

		end_submit_wait_and_free_command_buffer(cmd)
	}

	m.vertex_buffers = make([]vk.Buffer, 3, graphics.allocator)
	m.vertex_buffers[0] = m.vertex_buffer
	m.vertex_buffers[1] = m.vertex_buffer
	m.vertex_buffers[2] = m.vertex_buffer

	m.offsets = make([]vk.DeviceSize, 3, graphics.allocator)
	m.offsets[0] = positions_offset
	m.offsets[1] = normals_offset
	m.offsets[2] = texcoords_offset

	return m
}

destroy_mesh :: proc(mesh : ^Mesh) {
	g := &graphics

	vk.DestroyBuffer(g.device, mesh.vertex_buffer, nil)
	vk.FreeMemory(g.device, mesh.vertex_memory, nil)

	vk.DestroyBuffer(g.device, mesh.index_buffer, nil)
	vk.FreeMemory(g.device, mesh.index_memory, nil)

	delete(mesh.vertex_buffers, graphics.allocator)
	delete(mesh.offsets, graphics.allocator)
}

draw_mesh :: proc(mesh : ^Mesh, model : mat4) {
	draw_basic_mesh(mesh, model)
}