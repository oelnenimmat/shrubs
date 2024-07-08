package game

import "shrubs:graphics"

GrassTypeSettings :: struct {
	bottom_color 		: vec4,
	top_color 			: vec4,
	height 				: f32,
	height_variation 	: f32,
	width 				: f32,
	bend 				: f32,

	clump_size 				: f32,
	clump_height_variation 	: f32,
	clump_squeeze_in 		: f32,
	clump_align_facing 		: f32,
}

Grass :: struct {
	types_buffer 		: graphics.Buffer,
	positions 			: []vec2,
	instance_buffers 	: []graphics.Buffer,

	placement_map : ^graphics.Texture,

	type : GrassTypeSettings,
}

GPU_GrassTypeData :: struct #align(16) {
	height 				: f32,
	height_variation 	: f32,
	width 				: f32,
	bend 				: f32,

	clump_size 				: f32,
	clump_height_variation 	: f32,
	clump_squeeze_in		: f32,

	more_data : f32,
}
#assert(size_of(GPU_GrassTypeData) == 32)

// Todo(Leo): make sure sure this is GPU compatible
// Todo(Leo): maybe move this into graphics/pipeline_grass.odin???
// This needs to be GPU compatible and match shader things
GPU_GrassInstanceData :: struct #align(16) {
	position 	: vec4,
	field_uv 	: vec2,
	height 		: f32,
	rotation 	: f32,
	more_data 	: vec4,
	even_more_data 	: vec4,
	// bend 		: f32,
	// _unused 	: vec3,	
}
#assert(size_of(GPU_GrassInstanceData) == 64)

GrassLodSettings :: struct {
	instance_count : int,
	segment_count : int,
}

grass_lod_settings := [3]GrassLodSettings {
	{64, 5},
	{48, 3},
	{32, 1},
}

create_grass :: proc(placement_map : ^graphics.Texture, type : GrassTypeSettings) -> Grass {
	g : Grass

	// type info buffer
	type_buffer_size := size_of(GPU_GrassTypeData)
	g.type = type
	g.types_buffer = graphics.create_buffer(type_buffer_size, true)
	// update_grass_type_buffer(&g)

	// Chunk/instance buffers
	capacity := GRASS_BLADES_IN_CHUNK_1D * GRASS_BLADES_IN_CHUNK_1D
	buffer_data_size := capacity * size_of(GPU_GrassInstanceData)

	chunk_count_1D := 10
	chunk_count_2D := chunk_count_1D * chunk_count_1D

	chunk_size := f32(5)

	// Todo(Leo): allocator!!!!
	g.positions = make([]vec2, chunk_count_2D)
	g.instance_buffers = make([]graphics.Buffer, chunk_count_2D)

	for i in 0..<chunk_count_2D {
		x := f32(i % chunk_count_1D)
		y := f32(i / chunk_count_1D)

		g.positions[i] = {x * chunk_size - 25, y * chunk_size - 25}
		g.instance_buffers[i] = graphics.create_buffer(buffer_data_size)
	}

	g.placement_map = placement_map

	return g
}

update_grass_type_buffer :: proc(g : ^Grass) {
	gpu_type := GPU_GrassTypeData {
		g.type.height,
		g.type.height_variation,
		g.type.width,
		g.type.bend,
		g.type.clump_size,
		g.type.clump_height_variation,
		g.type.clump_squeeze_in,
		0,
	}
	graphics.buffer_write_data(&g.types_buffer, []GPU_GrassTypeData { gpu_type })	
}

destroy_grass :: proc(grass : ^Grass) {
	for ib in &grass.instance_buffers {
		graphics.destroy_buffer(&ib)
	}

	grass^ = {}
}