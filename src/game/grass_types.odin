package game

import graphics "shrubs:graphics/vulkan"

import "core:encoding/json"
import "core:fmt"
import "core:os"

GRASS_TYPES_FILENAME :: "scenes/grass.json"

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

GPU_GrassTypeData :: struct #align(16) {
	height 				: f32,
	height_variation 	: f32,
	width 				: f32,
	bend 				: f32,

	clump_size 				: f32,
	clump_height_variation 	: f32,
	clump_squeeze_in		: f32,
	_ : f32,

	top_color : vec4,

	bottom_color : vec4,

	roughness : f32,
	_ : f32,
	_ : vec2,
}
#assert(size_of(GPU_GrassTypeData) == 80)


GrassTypes :: struct {
	settings 		: [GrassType]GrassTypeSettings,
}

create_grass_types :: proc() -> GrassTypes {
	return {}
}

destroy_grass_types :: proc(gt : ^GrassTypes) {}

update_grass_type_buffer :: proc(types : ^GrassTypes) {
	gpu_data := graphics.get_grass_types_mapped()
	for type, i in GrassType {
		gpu_data[i] = {
			types.settings[type].height,
			types.settings[type].height_variation,
			types.settings[type].width,
			types.settings[type].bend,
			types.settings[type].clump_size,
			types.settings[type].clump_height_variation,
			types.settings[type].clump_squeeze_in,
			0,	

			types.settings[type].top_color,
			types.settings[type].bottom_color,
			types.settings[type].roughness,
			0,
			{},
		}
	}
}

load_grass_types :: proc(types : ^GrassTypes) {
	data, read_success := os.read_entire_file(GRASS_TYPES_FILENAME)
	defer delete(data)

	if read_success {
		json_error := json.unmarshal(data, &types.settings)
		if json_error != nil {
			fmt.println("[LOAD GRASS ERROR(json)]:", json_error)
		}
	} else {
		fmt.println("[LOAD GRASS ERROR]: failed to load the file")
	}

}

save_grass_types :: proc(types : ^GrassTypes) {
	data, json_error := json.marshal(types.settings, opt = {pretty = true})
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
