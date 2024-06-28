package game

import "shrubs:graphics"

import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:math/rand"

// Squares!!! for now..
TERRAIN_CHUNK_COUNT :: 5 // x 3
TERRAIN_CHUNK_SIZE :: 10 // x 10

GRASS_DENSITY_PER_UNIT :: 10

Terrain :: struct {
	positions : []vec3,
	meshes : []graphics.Mesh,
}

create_terrain :: proc() -> Terrain {
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

		t.positions[i] = {x, y, 0}
		t.meshes[i] = create_static_terrain_mesh(t.positions[i].xy)
	}

	return t
}

destroy_terrain :: proc(terrain : ^Terrain) {
	delete (terrain.positions)

	// Todo(Leo): also delete all the meshes from graphics
	delete (terrain.meshes)

	terrain^ = {}
}

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

Grass :: struct {
	instances 	: graphics.InstanceBuffer,
	mesh 		: graphics.Mesh,
}

create_grass :: proc() -> Grass {
	g : Grass

	g.mesh = create_grass_blade_mesh()

	world_side_length := f32(TERRAIN_CHUNK_COUNT * TERRAIN_CHUNK_SIZE)
	w := 0.5 * world_side_length

	count := int(world_side_length * GRASS_DENSITY_PER_UNIT)

	fmt.println("grass count:", count * count)

	g.instances = generate_grass_positions({-w, -w, 0}, {w, w, 0}, count)

	return g
}

destroy_grass :: proc(grass : ^Grass) {
	// Todo(Leo): destroy mesh and instances

	grass^ = {}
}

// Todo(Leo): make sure sure this is GPU compatible
// Todo(Leo): maybe move this into graphics/pipeline_grass.odin???
// This needs to be GPU compatible and match shader things
GrassInstanceData :: struct #align(16) {
	position 	: vec4,
	field_uv 	: vec2,
	height 		: f32,
	rotation 	: f32,
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
		z := sample_height(x, y)

		h := 0.9 + rand.float32() * 0.2
		h *= 0.4
		r := rand.float32() * 2 * math.PI

		instance_memory[i].position = {x, y, z, 0}	
		instance_memory[i].height = h	
		instance_memory[i].rotation = r

		instance_memory[i].field_uv = vec2{
			(x - min.x) / (max.x - min.x),
			(y - min.y) / (max.y - min.y),
		}
	}

	return buffer
}

sample_height :: proc(x, y : f32) -> f32 {
	
	WORLD_SEED 			:: 562
	WORLD_TO_GRID_SCALE :: 0.1
	TERRAIN_Z_SCALE 	:: 5

	// transform to grid scale
	x := x * WORLD_TO_GRID_SCALE
	y := y * WORLD_TO_GRID_SCALE

	return value_noise_2D(x, y) * TERRAIN_Z_SCALE
}

create_static_terrain_mesh :: proc(min_corner_position : vec2) -> graphics.Mesh {
	
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
		cell_x := i % (quad_count_1D + 1)
		cell_y := i / (quad_count_1D + 1)

		x := f32(cell_x) * quad_size
		y := f32(cell_y) * quad_size	

		z := sample_height(x + min_corner_position.x, y + min_corner_position.y)

		u := f32(cell_x) / f32(quad_count_1D + 1)
		v := f32(cell_y) / f32(quad_count_1D + 1)

		positions[i] 	= {x, y, z}
		normals[i] 		= {0, 0, 1}
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

	mesh := graphics.create_mesh(positions, normals, texcoords, indices)
	return mesh
}