package game

import "core:encoding/json"
import "core:fmt"
import "core:os"
import "core:strings"

import graphics "shrubs:graphics/vulkan"

TextureUseName :: enum {
	Grass_Field_Color,
	Grass_Placement,
	Rock,
	Road,
	Wind,
}

// Todo(Leo): read more
// sRGB values, according to this:
// https://physics.stackexchange.com/questions/353672/what-are-the-wavelengths-of-the-red-green-and-blue-lights-used-for-making-led
// Todo(Leo): for physically realistic sun color
// Todo(Leo): also find  the absorbtions for clear and cloudy sky and figure out how to use thos
// WAVELENGTH_RED 		:: 612e-9
// WAVELENGTH_GREEN 	:: 549e-9
// WAVELENGTH_BLUE 	:: 464e-9
Lighting :: struct {
	direction_polar 	: vec2,
	directional_color 	: vec4,
	ambient_color 		: vec4,
	exposure 			: f32,
}

Scene :: struct {
	// identification
	name : string,
	index : int,

	// Resources/Assets
	// Todo(Leo): be careful, these now need to manually match!
	texture_uses 	: [TextureUseName]TextureAssetName,
	textures 		: [TextureUseName]^graphics.Texture,
	// meshes : [MeshName]graphics.Mesh,
	
	// Systems
	world 		: WorldSettings,
	terrain 	: Terrain,
	lighting 	: Lighting,

	// this is just a mockup measure :)
	grass_type 	: GrassType,

	greyboxing : Greyboxing,
}

SerializedScene :: struct {
	world 			: WorldSettings,
	lighting 		: Lighting,
	greyboxing 		: SerializedGreyboxing,
	grass_type 		: GrassType,
	texture_uses 	: [TextureUseName]TextureAssetName,
}

// Todo(Leo): proper allocation :)
// Todo(Leo): proper allocation :)
// Todo(Leo): proper allocation :)
// Todo(Leo): proper allocation :)
load_scene :: proc(scene_index : int) -> ^Scene {
	s := new(Scene)
	s^ = {}

	// info := &available_scenes[scene_index]
	s.greyboxing = create_greyboxing()

	serialized : SerializedScene
	{
		// Todo(Leo): check success
		data, success := os.read_entire_file(available_scenes.filenames[scene_index])

		// Todo(Leo): check error
		json.unmarshal(data, &serialized)
	}

	s.name = available_scenes.display_names[scene_index]
	s.index = scene_index

	// Assets/resources	
	s.texture_uses = serialized.texture_uses
	for name in TextureUseName {
		s.textures[name] = &asset_provider.textures[s.texture_uses[name]]
	}

	// systems
	s.world = serialized.world
	s.terrain = create_terrain(
		s.textures[.Grass_Placement],
		s.textures[.Grass_Field_Color],
		s.textures[.Road],
		&s.world,
	)
	s.lighting = serialized.lighting

	s.grass_type = serialized.grass_type
	update_grass(&grass_system, s.textures[.Grass_Placement])

	deserialize_greyboxing(&s.greyboxing, &serialized.greyboxing)

	return s
}

save_scene :: proc(scene : ^Scene) {
	s : SerializedScene
	s.world 		= scene.world
	s.lighting 		= scene.lighting
	s.greyboxing 	= serialize_greyboxing(&scene.greyboxing)
	s.grass_type 	= scene.grass_type
	s.texture_uses 	= scene.texture_uses

	// Todo(Leo): allocation!!!
	data, json_error := json.marshal(s, opt = {pretty = true})
	defer delete(data)

	if json_error == nil {
		success := os.write_entire_file(available_scenes.filenames[scene.index], data)
		if !success {
			fmt.println("[SAVE SCENE ERROR(os write failed)]")
		}
	} else {
		fmt.println("[SAVE SCENE ERROR(json)]:", json_error)
	}
}

unload_scene :: proc(s : ^Scene) {
	save_scene(s)

	destroy_terrain(&s.terrain)
	destroy_greyboxing(&s.greyboxing)

	free(s)
}