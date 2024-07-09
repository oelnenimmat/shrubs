package game

import "core:encoding/json"
import "core:fmt"
import "core:os"

import "shrubs:graphics"

GrassType :: enum { Green, Blue, DryTips }

GrassTypeSettings :: struct {
	height 				: f32,
	height_variation 	: f32,
	width 				: f32,
	bend 				: f32,

	clump_size 				: f32,
	clump_height_variation 	: f32,
	clump_squeeze_in 		: f32,
	clump_align_facing 		: f32,

	bottom_color 		: vec4,
	top_color 			: vec4,
	roughness 			: f32,
}

grass_type_settings : [GrassType]GrassTypeSettings
GRASS_TYPES_FILENAME :: "scenes/grass.json"

load_grass_types :: proc() {
	data, read_success := os.read_entire_file(GRASS_TYPES_FILENAME)
	defer delete(data)

	if read_success {
		json_error := json.unmarshal(data, &grass_type_settings)
		if json_error != nil {
			fmt.println("[LOAD GRASS ERROR(json)]:", json_error)
		}
	} else {
		fmt.println("[LOAD GRASS ERROR]: failed to load the file")
	}

}

save_grass_types :: proc() {
	data, json_error := json.marshal(grass_type_settings, opt = {pretty = true})
	defer delete(data)

	if json_error == nil {
		write_success := os.write_entire_file(GRASS_TYPES_FILENAME, data)
		if !write_success {
			fmt.println("[SAVE GRASS ERROR]: failed to save the file")
		}
	} else {
		fmt.println("[SAVE GRASS ERROR(json)]:", json_error)
	}
}


Grass :: struct {
	types_buffer 		: graphics.Buffer,

	// chunk min corner positions, curresponding to same index instance buffers
	positions 			: []vec2,
	instance_buffers 	: []graphics.Buffer,
	placement_map 		: ^graphics.Texture,
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

	top_color : vec4,
	bottom_color : vec4,

	roughness : f32,
	more_data_2 : f32,
	more_data_3 : vec2,
}
#assert(size_of(GPU_GrassTypeData) == 80)

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

create_grass :: proc(placement_map : ^graphics.Texture) -> Grass {
	g : Grass

	// type info buffer
	type_count 			:= len(GrassType)
	type_buffer_size 	:= type_count * size_of(GPU_GrassTypeData)
	g.types_buffer = graphics.create_buffer(type_buffer_size, true)

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
	gpu_data : [len(GrassType)]GPU_GrassTypeData
	for type, i in GrassType {
		gpu_data[i] = {
			grass_type_settings[type].height,
			grass_type_settings[type].height_variation,
			grass_type_settings[type].width,
			grass_type_settings[type].bend,
			grass_type_settings[type].clump_size,
			grass_type_settings[type].clump_height_variation,
			grass_type_settings[type].clump_squeeze_in,
			0,	

			grass_type_settings[type].top_color,
			grass_type_settings[type].bottom_color,
			grass_type_settings[type].roughness,
			0,
			{},
		}
	}
	graphics.buffer_write_data(&g.types_buffer, gpu_data[:])	
}

destroy_grass :: proc(grass : ^Grass) {
	graphics.destroy_buffer(&grass.types_buffer)

	for ib in &grass.instance_buffers {
		graphics.destroy_buffer(&ib)
	}

	grass^ = {}
}