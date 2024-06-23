package application

import "../graphics"

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

	// origin at the first vertex, growing to positive X and Y
	for i in 0..<vertex_count {
		x := i % (quad_count_1D + 1)
		y := i / (quad_count_1D + 1)

		positions[i] = {f32(x) * quad_size, f32(y) * quad_size, 0}
		normals[i] = {0, 0, 1}
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

	mesh := graphics.create_mesh(positions, normals, indices)
	return mesh
}