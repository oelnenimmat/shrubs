package assets

import "vendor:cgltf"

import "core:mem"
import "core:math/linalg"
import "core:fmt"

vec2 :: linalg.Vector2f32
vec3 :: linalg.Vector3f32

// todo(Leo): it seems like cgltf memory is not handled properly
NOT_MEMORY_SAFE_gltf_load_node :: proc (filename : cstring, node_name : cstring) -> (positions : []vec3, normals : []vec3, indices : [] u16) {

	options : cgltf.options = {}

	data, result := cgltf.parse_file(options, filename)
	assert(result == .success, "failed to read gltf file with cgtlf")

	node : ^cgltf.node = nil
	for n in &data.nodes {
		if n.name == node_name {
			node = &n
		}
	}
	assert(node != nil, "requested node not found in file")

	mesh := node.mesh
	assert(mesh != nil, "requested node does not have mesh")

	result = cgltf.load_buffers(options, data, filename)
	assert(result == .success, "could not load cgltf buffers")

	assert(len(mesh.primitives) == 1, "no handling multiple primitives yet, sorry")
	primitive := &mesh.primitives[0]

	// todo(Leo): use pointers
	position_attribute_index 	:= -1
	normal_attribute_index 		:= -1
	texcoord_attribute_index 	:= -1

	for p, i in primitive.attributes {
		switch p.name {
			case "POSITION": 	position_attribute_index = i
			case "NORMAL": 		normal_attribute_index = i
			case "TEXCOORD_0": 	texcoord_attribute_index = i
		}
	}

	assert(position_attribute_index >= 0)
	assert(normal_attribute_index >= 0)
	assert(texcoord_attribute_index >= 0)

	// gltf coordinates go differently than ours, so we need to convert
	// we do modifications directly to cgltf buffer, since we are not gonna save it anywhere later anyway
	// todo(Leo): think about normals, i think they should be world(/object) space normals, but i am not sure
	// can also do simd lol
	// convert_coordinates :: proc(v : vec3) -> vec3 {
	// 	return {v.x, -v.z, v.y} // seems to be this
	// 	// return {-v.x, v.z, v.y} // I though it would be this (maybe blender does something)
	// }

	convert_coordinates :: proc(vecs : []vec3) {
		for v, i in vecs {
			vecs[i] = {v.x, -v.z, v.y} // seems to be this
			// v = {-v.x, v.z, v.y} // I though it would be this (maybe blender does something)
		}
	}

	// ----- POSITIONS -----

	position_accessor := primitive.attributes[position_attribute_index].data
	assert(position_accessor.component_type == .r_32f)
	assert(position_accessor.type == .vec3)

	vertex_count := position_accessor.count

	position_buffer_view 	:= position_accessor.buffer_view
	position_buffer 		:= position_buffer_view.buffer
	position_src_ptr 		:= cast([^]u8)position_buffer.data
	position_src_data 		:= cast([^]vec3) mem.ptr_offset(
		position_src_ptr, 
		position_buffer_view.offset + position_accessor.offset,
	)

	convert_coordinates(position_src_data[0:vertex_count])
	// for i in 0..<vertex_count {
	// 	position_src_data[i] = convert_coordinates(position_src_data[i])
	// }

	// ----- NORMALS ----

	normal_accessor := primitive.attributes[normal_attribute_index].data
	assert(normal_accessor.component_type == .r_32f)
	assert(normal_accessor.type == .vec3)
	assert(normal_accessor.count == vertex_count)

	normal_buffer_view 	:= normal_accessor.buffer_view
	normal_buffer 		:= normal_buffer_view.buffer
	normal_src_ptr 		:= cast([^]u8)normal_buffer.data
	normal_src_data 	:= cast([^]vec3) mem.ptr_offset(
		normal_src_ptr,
		normal_buffer_view.offset + normal_accessor.offset,
	)

	convert_coordinates(normal_src_data[0:vertex_count])
	// for i in 0..<vertex_count {
	// 	normal_src_data[i] = convert_coordinates(normal_src_data[i])
	// }

	// ----- TEXCOORDS -----

	texcoord_accessor := primitive.attributes[texcoord_attribute_index].data
	assert(texcoord_accessor.component_type == .r_32f)
	assert(texcoord_accessor.type == .vec2)
	assert(texcoord_accessor.count == vertex_count)

	texcoord_buffer_view 	:= texcoord_accessor.buffer_view
	texcoord_buffer 		:= texcoord_buffer_view.buffer
	texcoord_src_ptr 		:= cast([^]u8)texcoord_buffer.data
	texcoord_src_data 		:= cast([^]vec2) mem.ptr_offset(
		texcoord_src_ptr,
		texcoord_buffer_view.offset + texcoord_accessor.offset,
	)

	// ----- INDICES -----

	index_accessor 		:= primitive.indices
	assert(index_accessor.component_type == .r_32u || index_accessor.component_type == .r_16u)
	assert(index_accessor.type == .scalar)

	index_count 		:= index_accessor.count

	index_buffer_view 	:= index_accessor.buffer_view
	index_buffer 		:= index_buffer_view.buffer
	index_src_ptr 		:= mem.ptr_offset(
		cast([^]u8)index_buffer.data,
		index_buffer_view.offset + index_accessor.offset,
	)

	// ----- COPY MEMORY -----

	positions = make([]vec3, vertex_count)
	normals = make([]vec3, vertex_count)
	indices = make([]u16, index_count)

	copy_slice(positions, position_src_data[0:vertex_count])
	copy_slice(normals, normal_src_data[0:vertex_count])

	if index_accessor.component_type == .r_16u {
		copy_slice(indices, (cast([^]u16)index_src_ptr)[0:index_count])
	} else {

		fmt.println("Converting u32 indices to u16 indices, hope it fits")

		indices_u32 := make([]u32, index_count)
		defer delete(indices_u32)

		copy_slice(indices_u32, (cast([^]u32)index_src_ptr)[0:index_count])
		for i in 0..<index_count {
			indices[i] = u16(indices_u32[i])
		}
	}

	// if index_accessor.component_type == .r_16u {
	// 	indices_u16 := make([]u16, index_count)
	// 	defer delete(indices_u16)

	// 	copy_slice(indices_u16, (cast([^]u16)index_src_ptr)[0:index_count])
	// 	for i in 0..<index_count {
	// 		indices[i] = u32(indices_u16[i])
	// 	}


	// } else {
	// 	copy_slice(indices, (cast([^]u32)index_src_ptr)[0:index_count])
	// }

	return
}