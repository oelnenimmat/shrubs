package graphics

import "core:fmt"

import vk "vendor:vulkan"

Mesh :: struct {
	vertex_buffer : vk.Buffer,
	vertex_memory : vk.DeviceMemory,

	index_buffer : vk.Buffer,
	index_memory : vk.DeviceMemory,

	index_count : u32,
}

create_mesh :: proc(
	positions 	: []vec3,
	UNUSED_normals 	: []vec3,
	UNUSED_texcoords	: []vec2, 
	indices 			: []u16,
) -> Mesh {
	g := &graphics

	m : Mesh

	vertex_count 			:= len(positions)
	positions_buffer_size 	:= vk.DeviceSize(size_of(vec3) * vertex_count)
	m.vertex_buffer, m.vertex_memory = create_buffer_and_memory(
		positions_buffer_size,
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
		vertex_staging := get_staging_memory(vec3, vertex_count)
		copy(vertex_staging, positions)

		cmd := allocate_and_begin_command_buffer()

		vertex_copy := vk.BufferCopy { 0, 0, positions_buffer_size }
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

	return m
}

destroy_mesh :: proc(mesh : ^Mesh) {
	g := &graphics

	vk.DestroyBuffer(g.device, mesh.vertex_buffer, nil)
	vk.FreeMemory(g.device, mesh.vertex_memory, nil)

	vk.DestroyBuffer(g.device, mesh.index_buffer, nil)
	vk.FreeMemory(g.device, mesh.index_memory, nil)
}

draw_mesh :: proc(mesh : ^Mesh, model : mat4) {
	draw_basic_mesh(mesh, model)
}