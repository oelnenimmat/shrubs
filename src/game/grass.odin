package game

import "core:encoding/json"
import "core:fmt"
import "core:os"

import graphics "shrubs:graphics/vulkan"

Grass :: struct {
	// chunk min corner positions, curresponding to same index instance buffers
	positions 			: []vec2,
	instance_buffers 	: []graphics.Buffer,
	renderers			: []graphics.GrassRenderer,
	placement_map 		: ^graphics.Texture,
}

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

create_grass :: proc() -> Grass {
	g := Grass{}

	capacity 			:= GRASS_BLADES_IN_CHUNK_1D * GRASS_BLADES_IN_CHUNK_1D
	buffer_data_size 	:= capacity * size_of(GPU_GrassInstanceData)

	chunk_count_1D := 10
	chunk_count_2D := chunk_count_1D * chunk_count_1D

	chunk_size := f32(5)

	// Todo(Leo): allocator!!!!
	g.positions 		= make([]vec2, chunk_count_2D)
	g.instance_buffers 	= make([]graphics.Buffer, chunk_count_2D)
	g.renderers 		= make([]graphics.GrassRenderer, chunk_count_2D)

	for i in 0..<chunk_count_2D {
		x := f32(i % chunk_count_1D)
		y := f32(i / chunk_count_1D)

		g.positions[i] 			= {x * chunk_size - 25, y * chunk_size - 25}
		g.instance_buffers[i] 	= graphics.create_buffer(buffer_data_size)
		g.renderers[i] 			= graphics.create_grass_renderer(&g.instance_buffers[i])
	}

	return g
}

destroy_grass :: proc(grass : ^Grass) {
	for _, i in &grass.instance_buffers {
		graphics.destroy_buffer(&grass.instance_buffers[i])
		graphics.destroy_grass_renderer(&grass.renderers[i])
	}
	delete(grass.renderers)
	delete(grass.instance_buffers)
	delete(grass.positions)

	grass^ = {}
}

update_grass :: proc(g : ^Grass, placement_map : ^graphics.Texture) {
	g.placement_map = placement_map
}