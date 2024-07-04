package game

import "core:fmt"

import "shrubs:graphics"

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
}

MeshName :: enum {
	Pillar,
	Stone,
	Big_Rock_1,
}

Scene :: struct {
	name : SceneName,

	// Systems
	grass : Grass,
	terrain : Terrain,

	// Resources/Assets
	// Notice that these might become massive, so it is best to use
	// scene as a pointer as is done now.
	textures : [TextureName]graphics.Texture,
	meshes : [MeshName]graphics.Mesh,

	set_pieces : []SetPiece,
}

SceneName :: enum {
	Green_Hills_Zone,
	Blue_Hills_Zone,
	Big_Rock,
}

// Todo(Leo): take pointer argument for lazy allocation issues. If we make a
// local variable here to return, pointer to it don't work.
load_scene :: proc(scene_name : SceneName) -> ^Scene {
// load_scene :: proc() -> Scene {
	s := new(Scene)
	s^ = {}

	s.name = scene_name

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
			{&s.meshes[.Big_Rock_1], &s.textures[.Rock], {0.5, 0.5, 0.6}, {-8, 11, 1}, },
		}

		s.set_pieces = make([]SetPiece, len(set_pieces))
		copy(s.set_pieces, set_pieces)
	}

	return s
}


unload_scene :: proc(s : ^Scene) {

	// Todo(Leo): now these actually need to be implemented
	destroy_terrain(&s.terrain)
	destroy_grass(&s.grass)

	delete(s.set_pieces)

	for mesh in &s.meshes {
		graphics.destroy_mesh(&mesh)
	}

	for texture in &s.textures {
		graphics.destroy_texture(&texture)
	}

	free(s)
}

render_scene :: proc(s : ^Scene) {

}