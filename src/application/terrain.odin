package application

import "../graphics"

import "core:math"
import "core:math/rand"

create_grass_blade_mesh :: proc() -> graphics.Mesh {
	w := f32(0.1)
	h := f32(0.25)

	hw := w / 2

	positions := []vec3{
		{-hw, 			0, 0},
		{hw, 			0, 0},
		{-hw * 0.9375, 	0, h},
		{hw * 0.9375, 	0, h},
		{-hw * 0.75, 	0, 2*h},
		{hw * 0.75, 	0, 2*h},
		{-hw * 0.4375, 	0, 3*h},
		{hw * 0.4375, 	0, 3*h},
		{0, 			0, 4*h},
	}

	normals := []vec3 {
		{0, 1, 0},
		{0, 1, 0},
		{0, 1, 0},
		{0, 1, 0},
		{0, 1, 0},
		{0, 1, 0},
		{0, 1, 0},
		{0, 1, 0},
		{0, 1, 0},
	}

	// Todo(Leo): make triangle strip, this is just normal triangles, as this is what we have now
	// Todo(Leo): might be that we do not need this at all in the end, just generate things on gpu/vertex shader
	elements := []u16 {
		0, 1, 2, 2, 1, 3,
		2, 3, 4, 4, 3, 5,
		4, 5, 6, 6, 5, 7,
		6, 7, 8,
	}

	return graphics.create_mesh(positions, normals, nil, elements) 
}

GrassInstanceData :: struct #align(16) {
	position 	: vec2,
	height 		: f32,
	rotation 	: f32,
	field_uv 	: vec2,
}
#assert(size_of(GrassInstanceData) == 32)


generate_grass_positions :: proc(min, max : vec3, count_per_dimension : int) -> graphics.InstanceBuffer {

	cell_count := count_per_dimension * count_per_dimension
	cell_size_x := (max.x - min.x) / f32(count_per_dimension)
	cell_size_y := (max.y - min.y) / f32(count_per_dimension)

	buffer := graphics.create_instance_buffer(cell_count, size_of(GrassInstanceData))
	
	instance_memory := (cast([^]GrassInstanceData) graphics.get_instance_buffer_writeable_memory(&buffer))[0:cell_count]

	for i in 0..<cell_count {
		cell_x := i % count_per_dimension
		cell_y := i / count_per_dimension

		x := min.x + (f32(cell_x) + rand.float32()) * cell_size_x
		y := min.y + (f32(cell_y) + rand.float32()) * cell_size_y
		
		h := 0.9 + rand.float32() * 0.2
		h *= 0.4
		r := rand.float32() * 2 * math.PI

		instance_memory[i].position = {x, y}	
		instance_memory[i].height = h	
		instance_memory[i].rotation = r

		instance_memory[i].field_uv = vec2{
			(x - min.x) / (max.x - min.x),
			(y - min.y) / (max.y - min.y),
		}
	}

	return buffer
}

create_static_terrain_mesh :: proc() -> graphics.Mesh {
	
	world_size := 10
	
	// per dimension
	quad_count_1D := 10
	quad_count := quad_count_1D * quad_count_1D
	quad_size := f32(world_size) / f32(quad_count_1D)

	// VERTICES
	vertex_count := (quad_count_1D + 1) * (quad_count_1D + 1)

	positions := make([]vec3, vertex_count)
	defer delete(positions)

	normals := make([]vec3, vertex_count)
	defer delete(normals)

	texcoords := make([]vec2, vertex_count)
	defer delete(texcoords)

	// origin at the first vertex, growing to positive X and Y
	for i in 0..<vertex_count {
		x := i % (quad_count_1D + 1)
		y := i / (quad_count_1D + 1)

		positions[i] 	= {f32(x) * quad_size, f32(y) * quad_size, 0}
		normals[i] 		= {0, 0, 1}
		texcoords[i] 	= {f32(x) / f32(quad_count_1D + 1), f32(y) / f32(quad_count_1D + 1)}
	}

	// ELEMENTS/TRIANGLES
	index_count := 6 * quad_count_1D * quad_count_1D
	indices := make([]u16, index_count)
	defer delete(indices)

	for i in 0..<quad_count {
		x := i % quad_count_1D
		y := i / quad_count_1D

		t0 := i * 6
		t1 := t0 + 1
		t2 := t0 + 2
		t3 := t0 + 3
		t4 := t0 + 4
		t5 := t0 + 5

		v0 := x + y * (quad_count_1D + 1)
		v1 := v0 + 1
		v2 := v0 + (quad_count_1D + 1)
		v3 := v2
		v4 := v1
		v5 := v0 + (quad_count_1D + 1) + 1

		indices[t0] = u16(v0)
		indices[t1] = u16(v1)
		indices[t2] = u16(v2)
		indices[t3] = u16(v3)
		indices[t4] = u16(v4)
		indices[t5] = u16(v5)
	}

	mesh := graphics.create_mesh(positions, normals, texcoords, indices)
	return mesh
}