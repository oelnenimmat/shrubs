package game

import "core:encoding/json"
import "core:fmt"
import "core:os"
import "core:strings"

import "shrubs:graphics"

// Todo(Leo): read more
// sRGB values, according to this:
// https://physics.stackexchange.com/questions/353672/what-are-the-wavelengths-of-the-red-green-and-blue-lights-used-for-making-led
WAVELENGTH_RED 		:: 612e-9
WAVELENGTH_GREEN 	:: 549e-9
WAVELENGTH_BLUE 	:: 464e-9

SetPiece :: struct {
	mesh 		: ^graphics.Mesh,
	texture 	: ^graphics.Texture,
	color 		: vec3,
	position 	: vec3,
}

TextureName :: enum {
	Grass_Field,
	Grass_Placement,
	Rock,
	Road,
	Wind,
}

MeshName :: enum {
	Pillar,
	Stone,
	Big_Rock_1,
}

Lighting :: struct {
	direction_polar 	: vec2,
	directional_color 	: vec4,
	ambient_color 		: vec4
}

Scene :: struct {
	name : SceneName,

	// Systems
	grass 		: Grass,
	terrain 	: Terrain,
	lighting 	: Lighting,

	// Resources/Assets
	// Notice that these might become massive, so it is best to use
	// scene as a pointer as is done now.
	textures : [TextureName]graphics.Texture,
	meshes : [MeshName]graphics.Mesh,

	set_pieces : []SetPiece,
	greyboxing : Greyboxing,
}

SceneName :: enum {
	Green_Hills_Zone,
	Blue_Hills_Zone,
	Big_Rock,
}

SerializedScene :: struct {
	lighting : Lighting,
	greyboxing : SerializedGreyboxing,
}

// Todo(Leo): take pointer argument for lazy allocation issues. If we make a
// local variable here to return, pointer to it don't work.
load_scene :: proc(scene_name : SceneName) -> ^Scene {
	s := new(Scene)
	s^ = {}

	s.name = scene_name

	serialized : SerializedScene
	{
		filename_builder : strings.Builder
		defer strings.builder_destroy(&filename_builder)
		fmt.sbprintf(&filename_builder, "scenes/{}.scene", scene_name)

		// Todo(Leo): check success
		data, success := os.read_entire_file(strings.to_string(filename_builder))

		// Todo(Leo): check error
		json.unmarshal(data, &serialized)
	}

	// http://kitfox.com/projects/perlinNoiseMaker/
	// Todo(Leo): this is for all, so maybe make more public access
	s.textures[.Wind] = TEMP_load_color_texture("assets/perlin_wind.png")

	switch scene_name {
	case .Green_Hills_Zone:

		// resources
		s.textures[.Grass_Field] = TEMP_load_color_texture("assets/callum_andrews_ghibli_grass.png")

		s.meshes[.Pillar] 	= TEMP_load_mesh_gltf("assets/shrubs.glb", "mock_coordinate_pillar")
		s.meshes[.Stone] 	= TEMP_load_mesh_gltf("assets/shrubs.glb", "mock_shrub")

		// systems
		s.terrain = create_terrain(
			&white_texture,
			&s.textures[.Grass_Field],
			&black_texture,
		)
		s.grass = create_grass(&white_texture)

		set_pieces := []SetPiece {
			{&s.meshes[.Pillar], &white_texture, {0.5, 0.5, 0.6}, {0, 0, 0} },
			
			{&s.meshes[.Stone], &white_texture, {0.5, 0.5, 0.6}, {3, 0, 0.5}, },
			{&s.meshes[.Stone], &white_texture, {0.5, 0.5, 0.6}, {2.8, 1, 0.5}, },
			{&s.meshes[.Stone], &white_texture, {0.5, 0.5, 0.6}, {0, 2, 0.5}, },
			{&s.meshes[.Stone], &white_texture, {0.5, 0.5, 0.6}, {1, 3, 0.5}, },
		}

		s.set_pieces = make([]SetPiece, len(set_pieces))
		copy(s.set_pieces, set_pieces)
		
	case .Blue_Hills_Zone:

		// resources
		s.textures[.Grass_Field] = TEMP_load_color_texture("assets/blue_grass.png")

		s.meshes[.Pillar] = TEMP_load_mesh_gltf("assets/shrubs.glb", "mock_coordinate_pillar")
		s.meshes[.Stone] = TEMP_load_mesh_gltf("assets/shrubs.glb", "mock_shrub")

		// systems
		s.terrain = create_terrain(
			&white_texture,
			&s.textures[.Grass_Field],
			&black_texture,
		)
		s.grass = create_grass(&white_texture)

		set_pieces := []SetPiece {
			{&s.meshes[.Pillar], &white_texture, {0.5, 0.5, 0.6}, {0, 0, 0} },
			
			{&s.meshes[.Stone], &white_texture, {0.5, 0.5, 0.6}, {3, 0, 0.5}, },
			{&s.meshes[.Stone], &white_texture, {0.5, 0.5, 0.6}, {2.8, 1, 0.5}, },
			{&s.meshes[.Stone], &white_texture, {0.5, 0.5, 0.6}, {0, 2, 0.5}, },
			{&s.meshes[.Stone], &white_texture, {0.5, 0.5, 0.6}, {1, 3, 0.5}, },
		}

		s.set_pieces = make([]SetPiece, len(set_pieces))
		copy(s.set_pieces, set_pieces)
		
	case .Big_Rock:

		// resources
		s.textures[.Grass_Placement] 	= TEMP_load_color_texture("assets/grass_placement_test.png", .Nearest)
		s.textures[.Rock] 				= TEMP_load_color_texture("assets/rock_01_diff_4k.jpg")
		s.textures[.Grass_Field] 		= TEMP_load_color_texture("assets/callum_andrews_ghibli_grass.png")
		s.textures[.Road] 				= TEMP_load_color_texture("assets/rocky_trail_diff_4k.jpg")
		
		s.meshes[.Big_Rock_1] = TEMP_load_mesh_gltf("assets/terrain.glb", "terrain_big_rock_1")

		// systems
		s.terrain = create_terrain(
			&s.textures[.Grass_Placement],
			&s.textures[.Grass_Field],
			&s.textures[.Road],
		)
		s.grass = create_grass(&s.textures[.Grass_Placement])

		set_pieces := []SetPiece {
			{&s.meshes[.Big_Rock_1], &s.textures[.Rock], {1, 1, 1}, {-8, 11, 1}, },
		}

		s.set_pieces = make([]SetPiece, len(set_pieces))
		copy(s.set_pieces, set_pieces)
	}

	s.lighting = serialized.lighting
	deserialize_greyboxing(&s.greyboxing, &serialized.greyboxing)

	return s
}

save_scene :: proc(scene : ^Scene) {
	// Todo(Leo): allocation!!!
	filename_builder : strings.Builder
	defer strings.builder_destroy(&filename_builder)
	fmt.sbprintf(&filename_builder, "scenes/{}.scene", scene.name)


	s : SerializedScene
	s.lighting = scene.lighting
	s.greyboxing = serialize_greyboxing(&scene.greyboxing)

	// Todo(Leo): allocation!!!
	data, json_error := json.marshal(s, opt = {pretty = true})
	defer delete(data)

	if json_error == nil {
		success := os.write_entire_file(strings.to_string(filename_builder), data)
		if !success {
			fmt.println("[SAVE SCENE ERROR(os write failed)]")
		}
	} else {
		fmt.println("[SAVE SCENE ERROR(json)]:", json_error)
	}
}

unload_scene :: proc(s : ^Scene) {

	save_scene(s)

	// Todo(Leo): now these actually need to be implemented
	destroy_terrain(&s.terrain)
	destroy_grass(&s.grass)
	destroy_greyboxing(&s.greyboxing)

	delete(s.set_pieces)

	for mesh in &s.meshes {
		graphics.destroy_mesh(&mesh)
	}

	for texture in &s.textures {
		graphics.destroy_texture(&texture)
	}

	free(s)
}