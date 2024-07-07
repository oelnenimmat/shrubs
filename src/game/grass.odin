package game

import "shrubs:graphics"

GrassTypeSettings :: struct {
	bottom_color 		: vec4,
	top_color 			: vec4,
	height 				: f32,
	height_variation 	: f32,
	width 				: f32,
	bend 				: f32,

	clump_height_variation 	: f32,
	clump_squeeze_in 		: f32,
	clump_align_facing 		: f32,
}

Grass :: struct {
	positions : []vec2,
	instances : []graphics.InstanceBuffer,

	placement_map : ^graphics.Texture,

	type : GrassTypeSettings,
}

// Todo(Leo): make sure sure this is GPU compatible
// Todo(Leo): maybe move this into graphics/pipeline_grass.odin???
// This needs to be GPU compatible and match shader things
GrassInstanceData :: struct #align(16) {
	position 	: vec4,
	field_uv 	: vec2,
	height 		: f32,
	rotation 	: f32,
	more_data 	: vec4,
	even_more_data 	: vec4,
	// bend 		: f32,
	// _unused 	: vec3,	
}
#assert(size_of(GrassInstanceData) == 64)

GrassLodSettings :: struct {
	instance_count : int,
	segment_count : int,
}

grass_lod_settings := [3]GrassLodSettings {
	{64, 5},
	{48, 3},
	{32, 1},
}

create_grass :: proc(placement_map : ^graphics.Texture) -> Grass {
	g : Grass

	capacity := GRASS_BLADES_IN_CHUNK_1D * GRASS_BLADES_IN_CHUNK_1D

	// Todo(Leo): allocator!!!!
	chunk_count_1D := 10
	chunk_count_2D := chunk_count_1D * chunk_count_1D

	chunk_size := f32(5)

	g.positions = make([]vec2, chunk_count_2D)
	g.instances = make([]graphics.InstanceBuffer, chunk_count_2D)

	for i in 0..<chunk_count_2D {
		x := f32(i % chunk_count_1D)
		y := f32(i / chunk_count_1D)

		g.positions[i] = {x * chunk_size - 25, y * chunk_size - 25}
		g.instances[i] = graphics.create_instance_buffer(capacity, size_of(GrassInstanceData))
	}

	g.placement_map = placement_map

	return g
}

destroy_grass :: proc(grass : ^Grass) {
	for ib in &grass.instances {
		graphics.destroy_instance_buffer(&ib)
	}

	grass^ = {}
}