package game

import "shrubs:graphics"

import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:math/rand"

// Squares!!! for now..
TERRAIN_CHUNK_COUNT :: 5 // x 5
TERRAIN_CHUNK_SIZE :: 10 // x 10

GRASS_DENSITY_PER_UNIT :: 10

GRASS_CHUNK_WORLD_SIZE :: 10
GRASS_BLADES_IN_CHUNK_1D :: 128

Terrain :: struct {
	positions 		: []vec3,
	meshes 			: []graphics.Mesh,

	grass_placement_map : ^graphics.Texture,
	grass_field_texture : ^graphics.Texture,
	road_texture : ^graphics.Texture,
}

create_terrain :: proc(
	grass_placement_map : ^graphics.Texture,
	grass_field_texture : ^graphics.Texture,
	road_texture : ^graphics.Texture,
) -> Terrain {
	t : Terrain

	chunk_count := TERRAIN_CHUNK_COUNT * TERRAIN_CHUNK_COUNT
	// Todo(Leo): allocator!!!
	t.positions = make([]vec3, chunk_count)
	t.meshes = make([]graphics.Mesh, chunk_count)

	terrain_world_size := TERRAIN_CHUNK_COUNT * TERRAIN_CHUNK_SIZE
	min_chunk_min_corner := -0.5 * f32(terrain_world_size)

	for i in 0..<chunk_count {
		chunk_x := i % TERRAIN_CHUNK_COUNT
		chunk_y := i / TERRAIN_CHUNK_COUNT

		x := f32(chunk_x) * TERRAIN_CHUNK_SIZE + min_chunk_min_corner
		y := f32(chunk_y) * TERRAIN_CHUNK_SIZE + min_chunk_min_corner

		uv_offset := vec2 {
			f32(chunk_x) / f32(TERRAIN_CHUNK_COUNT),
			f32(chunk_y) / f32(TERRAIN_CHUNK_COUNT),
		}

		t.positions[i] = {x, y, 0}
		t.meshes[i] = create_static_terrain_mesh(t.positions[i].xy, uv_offset)
	}

	t.grass_placement_map = grass_placement_map
	t.grass_field_texture = grass_field_texture
	t.road_texture = road_texture
	
	return t
}

destroy_terrain :: proc(terrain : ^Terrain) {
	delete (terrain.positions)

	// Todo(Leo): also delete all the meshes from graphics
	for mesh in &terrain.meshes {
		graphics.destroy_mesh(&mesh)
	}
	delete (terrain.meshes)

	terrain^ = {}
}



sample_height :: proc(x, y : f32) -> f32 {
	
	WORLD_SEED 			:: 563
	WORLD_TO_GRID_SCALE :: 0.1
	TERRAIN_Z_SCALE 	:: 5

	// transform to grid scale
	x := x * WORLD_TO_GRID_SCALE
	y := y * WORLD_TO_GRID_SCALE

	return value_noise_2D(x, y, WORLD_SEED) * TERRAIN_Z_SCALE
}

create_static_terrain_mesh :: proc(min_corner_position : vec2, uv_offset : vec2) -> graphics.Mesh {
	
	// per dimension
	quad_count_1D := 10
	quad_count := quad_count_1D * quad_count_1D
	quad_size := f32(TERRAIN_CHUNK_SIZE) / f32(quad_count_1D)

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
		cell_x := i % (quad_count_1D + 1)
		cell_y := i / (quad_count_1D + 1)

		local_x := f32(cell_x) * quad_size
		local_y := f32(cell_y) * quad_size	

		x := local_x + min_corner_position.x
		y := local_y + min_corner_position.y

		z := sample_height(x, y)

		u := f32(cell_x) / f32(quad_count_1D) / f32(TERRAIN_CHUNK_COUNT) + uv_offset.x
		v := f32(cell_y) / f32(quad_count_1D) / f32(TERRAIN_CHUNK_COUNT) + uv_offset.y

		positions[i] 	= {local_x, local_y, z}
		// set normals to zero for now, we accumulatecalculate them later
		normals[i] 		= {0, 0, 0}
		texcoords[i] 	= {u, v}
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

	
	for i := 0; i < index_count; i += 3 {
		v0 := positions[indices[i + 0]]
		v1 := positions[indices[i + 1]]
		v2 := positions[indices[i + 2]]
	
		v01 := v1 - v0
		v02 := v2 - v0

		n := linalg.cross(v01, v02)

		normals[indices[i + 0]] = n
		normals[indices[i + 1]] = n
		normals[indices[i + 2]] = n
	}

	for i := 0; i < vertex_count; i += 1 {
		normals[i] = linalg.normalize(normals[i])
	}
	

	mesh := graphics.create_mesh(positions, normals, texcoords, indices)
	return mesh
}