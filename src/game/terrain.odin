package game

import graphics "shrubs:graphics/vulkan"
import "shrubs:imgui"

import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:math/rand"

// Squares!!! for now..
TERRAIN_CHUNK_SIZE_1D 		:: 100 // x 10
TERRAIN_QUADS_PER_CHUNK_1D 	:: 100

GRASS_DENSITY_PER_UNIT :: 10
GRASS_CHUNK_WORLD_SIZE :: 10
GRASS_BLADES_IN_CHUNK_1D :: 128

// "World" as in isolated part of "world" that makes up this specific scene 
WorldSettings :: struct {
	seed 		: int,
	noise_scale : f32,
	z_scale 	: f32,
	z_offset 	: f32,

	chunk_count_1D : int,

	placement_match_world_size 	: bool,
	placement_scale 			: vec2,
	placement_offset 			: vec2,
}

check_dirty_bool :: proc(dirty : ^bool, edited : bool) {
	if edited {
		dirty^ = true
	}
}

check_dirty_b8 :: proc(dirty : ^bool, edited : b8) {
	if edited {
		dirty^ = true
	}
}

check_dirty :: proc { check_dirty_bool, check_dirty_b8 }

edit_world_settings :: proc(w : ^WorldSettings) {
	dirty := false

	check_dirty(&dirty, imgui.input_int("seed", &w.seed))
	check_dirty(&dirty, imgui.DragFloat("noise scale", &w.noise_scale, 0.01))
	check_dirty(&dirty, imgui.DragFloat("z scale", &w.z_scale, 0.01))
	check_dirty(&dirty, imgui.DragFloat("z offset", &w.z_offset, 0.01))

	check_dirty(&dirty, imgui.input_int("chunk count(1D)", &w.chunk_count_1D))
	imgui.text("world size: {}", w.chunk_count_1D * TERRAIN_CHUNK_SIZE_1D)

	if imgui.button("generate") || dirty {
		generate_terrain_mesh = true
	}

	imgui.Separator()
	imgui.text("Placement texture")
	imgui.checkbox("match world size", &w.placement_match_world_size)
	imgui.drag_vec2("scale", &w.placement_scale)
	imgui.drag_vec2("offset", &w.placement_offset)

	if w.placement_match_world_size {
		w.placement_scale = vec2(f32(w.chunk_count_1D * TERRAIN_CHUNK_SIZE_1D))
		w.placement_offset = -0.5 * w.placement_scale
	}

}

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
	road_texture 		: ^graphics.Texture,
	world 				: ^WorldSettings,
) -> Terrain {
	t := Terrain {}

	// Todo(Leo): allocator!!!
	t.positions, t.meshes = create_terrain_meshes(world)

	t.grass_placement_map = grass_placement_map
	t.grass_field_texture = grass_field_texture
	t.road_texture = road_texture
	
	return t
}

create_terrain_meshes :: proc(world : ^WorldSettings) -> (positions : []vec3, meshes : []graphics.Mesh) {
	chunk_count := world.chunk_count_1D * world.chunk_count_1D
	// Todo(Leo): allocator!!!
	positions = make([]vec3, chunk_count)
	meshes = make([]graphics.Mesh, chunk_count)

	terrain_world_size := world.chunk_count_1D * TERRAIN_CHUNK_SIZE_1D
	min_chunk_min_corner := -0.5 * f32(terrain_world_size)

	for i in 0..<chunk_count {
		chunk_x := i % world.chunk_count_1D
		chunk_y := i / world.chunk_count_1D

		x := f32(chunk_x) * TERRAIN_CHUNK_SIZE_1D + min_chunk_min_corner
		y := f32(chunk_y) * TERRAIN_CHUNK_SIZE_1D + min_chunk_min_corner

		uv_offset := vec2 {
			f32(chunk_x) / f32(world.chunk_count_1D),
			f32(chunk_y) / f32(world.chunk_count_1D),
		}

		positions[i] = {x, y, 0}
		meshes[i] = create_static_terrain_mesh(positions[i].xy, uv_offset, world)
	}

	return
}

destroy_terrain_meshes :: proc(terrain : ^Terrain) {
	delete (terrain.positions)

	for mesh in &terrain.meshes {
		graphics.destroy_mesh(&mesh)
	}
	delete (terrain.meshes)
}

destroy_terrain :: proc(terrain : ^Terrain) {
	destroy_terrain_meshes(terrain)
	terrain^ = {}
}

sample_height :: proc(x, y : f32, world : ^WorldSettings) -> f32 {

	// transform to grid scale. divide, so that noise_scale roughly
	// describe a feature size on the biggest octave
	x := x / world.noise_scale
	y := y / world.noise_scale

	noise := value_noise_2D(x, y, i32(world.seed)) * 2 - 1
	return noise * world.z_scale + world.z_offset
}

create_static_terrain_mesh :: proc(min_corner_position : vec2, uv_offset : vec2, world : ^WorldSettings) -> graphics.Mesh {
	
	// per dimension
	quad_count_1D := 10
	quad_count := quad_count_1D * quad_count_1D
	quad_size := f32(TERRAIN_CHUNK_SIZE_1D) / f32(quad_count_1D)

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

		z := sample_height(x, y, world)

		u := f32(cell_x) / f32(quad_count_1D) / f32(world.chunk_count_1D) + uv_offset.x
		v := f32(cell_y) / f32(quad_count_1D) / f32(world.chunk_count_1D) + uv_offset.y

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