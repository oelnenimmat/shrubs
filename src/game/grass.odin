/*
Todo(Leo):

	grass everywhere:
		- lod
		- single shared buffer
		- lod slots in buffer
			- e.g. 1 x lod 0, 10 x lod 1, 100 x lod 2

		- control density
		- fold short grass

		- chibli shader test
		 	- calculate normal in vertex shader and use the same for the entire blade
		 	- supposedly we get grass shaped light wave thingies

*/

package game

import "core:encoding/json"
import "core:fmt"
import "core:os"

import graphics "shrubs:graphics/vulkan"

// Make sure that this is same in shaders :)
GRASS_INSTANCE_DATA_SIZE :: 4 * size_of(vec4)


GRASS_CHUNK_SIZE_1D :: WORLD_CHUNK_SIZE_1D
// GRASS_DENSITY_PER_UNIT :: 10
// GRASS_CHUNK_WORLD_SIZE :: 10
GRASS_BLADES_IN_CHUNK_1D :: 256

GRASS_LOD_0_RENDERER_COUNT :: 1
GRASS_LOD_1_RENDERER_COUNT :: 3
GRASS_LOD_2_RENDERER_COUNT :: 12

GRASS_LOD_0_BLADE_COUNT_1D :: 1024
GRASS_LOD_1_BLADE_COUNT_1D :: 512
GRASS_LOD_2_BLADE_COUNT_1D :: 256

Grass :: struct {
	// chunk min corner positions, curresponding to same index instance buffers
	positions 			: []vec2,
	renderers			: []graphics.GrassRenderer,
	placement_map 		: ^graphics.Texture,

	lod_renderers : [3][]graphics.GrassRenderer,
	lod_positions : [3][]vec3,
}

create_grass :: proc() -> Grass {
	g := Grass{}

	capacity := GRASS_BLADES_IN_CHUNK_1D * GRASS_BLADES_IN_CHUNK_1D
	// buffer_data_size 	:= capacity * GRASS_INSTANCE_DATA_SIZE

	chunk_count_1D := 10
	chunk_count_2D := chunk_count_1D * chunk_count_1D

	chunk_size := f32(GRASS_CHUNK_SIZE_1D)

	// Todo(Leo): allocator!!!!
	g.positions 		= make([]vec2, chunk_count_2D)
	g.renderers 		= make([]graphics.GrassRenderer, chunk_count_2D)

	for i in 0..<chunk_count_2D {
		x := f32(i % chunk_count_1D)
		y := f32(i / chunk_count_1D)

		g.positions[i] = {x * chunk_size, y * chunk_size}
		g.renderers[i] = graphics.create_grass_renderer(
			GRASS_BLADES_IN_CHUNK_1D,	
			&asset_provider.textures[.Grass_Placement],
		)
	}

	{
		LOD :: 0
		g.lod_renderers[LOD] = make([]graphics.GrassRenderer, GRASS_LOD_0_RENDERER_COUNT, context.allocator)
		for _, i in g.lod_renderers[LOD] {
			g.lod_renderers[LOD][i] = graphics.create_grass_renderer(GRASS_LOD_0_BLADE_COUNT_1D, &asset_provider.textures[.Grass_Placement])
		}
		g.lod_positions[LOD] = make([]vec3, GRASS_LOD_0_RENDERER_COUNT, context.allocator)
		copy(g.lod_positions[LOD], []vec3{{0, 0, 0}})
	}

	{
		LOD :: 1
		g.lod_renderers[LOD] = make([]graphics.GrassRenderer, GRASS_LOD_1_RENDERER_COUNT, context.allocator)
		for _, i in g.lod_renderers[LOD] {
			g.lod_renderers[LOD][i] = graphics.create_grass_renderer(GRASS_LOD_1_BLADE_COUNT_1D, &asset_provider.textures[.Grass_Placement])
		}
		g.lod_positions[LOD] = make([]vec3, GRASS_LOD_1_RENDERER_COUNT, context.allocator)
		copy(g.lod_positions[LOD], []vec3{
			{chunk_size, 0, 0},
			{0, chunk_size, 0},
			{chunk_size, chunk_size, 0},
		})
	}

	{
		LOD :: 2
		g.lod_renderers[LOD] = make([]graphics.GrassRenderer, GRASS_LOD_2_RENDERER_COUNT, context.allocator)
		for _, i in g.lod_renderers[LOD] {
			g.lod_renderers[LOD][i] = graphics.create_grass_renderer(GRASS_LOD_2_BLADE_COUNT_1D, &asset_provider.textures[.Grass_Placement])
		}
		g.lod_positions[LOD] = make([]vec3, GRASS_LOD_2_RENDERER_COUNT, context.allocator)
		copy(g.lod_positions[LOD], []vec3{
			{2 * chunk_size, 0 * chunk_size, 0},
			{3 * chunk_size, 0 * chunk_size, 0},
			{2 * chunk_size, 1 * chunk_size, 0},
			{3 * chunk_size, 1 * chunk_size, 0},
			{0 * chunk_size, 2 * chunk_size, 0},
			{1 * chunk_size, 2 * chunk_size, 0},
			{2 * chunk_size, 2 * chunk_size, 0},
			{3 * chunk_size, 2 * chunk_size, 0},
			{0 * chunk_size, 3 * chunk_size, 0},
			{1 * chunk_size, 3 * chunk_size, 0},
			{2 * chunk_size, 3 * chunk_size, 0},
			{3 * chunk_size, 3 * chunk_size, 0},
		})
	}

	return g
}

destroy_grass :: proc(grass : ^Grass) {
	for _, i in grass.renderers {
		graphics.destroy_grass_renderer(&grass.renderers[i])
	}

	for _, lod in grass.lod_renderers{
		for _, i in grass.lod_renderers[lod] {
			graphics.destroy_grass_renderer(&grass.lod_renderers[lod][i])
		}
	}	

	delete(grass.renderers)
	delete(grass.positions)



	grass^ = {}
}

update_grass :: proc(g : ^Grass, placement_map : ^graphics.Texture) {
	g.placement_map = placement_map
}