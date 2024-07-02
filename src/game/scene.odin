package game

import "core:fmt"

import "shrubs:graphics"

SetPiece :: struct {
	mesh 		: ^graphics.Mesh,
	texture 	: ^graphics.Texture,
	color 		: vec3,
	position 	: vec3,
}

Scene :: struct {
	// Systems
	grass : Grass,
	terrain : Terrain,

	// Todo(Leo): this is still separate since it is used in systems
	// and I wasnt sure how to deal with that
	grass_field_texture : graphics.Texture,

	// Resources/Assets
	textures : map[string]graphics.Texture,
	meshes : map[string]graphics.Mesh,

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

	switch scene_name {
	case .Green_Hills_Zone:
		// systems
		s.terrain 	= create_terrain()
		s.grass 	= create_grass()

		// resources
		// s.grass_field_texture = TEMP_load_color_texture("assets/cgshare-book-grass-01.jpg")
		s.grass_field_texture = TEMP_load_color_texture("assets/callum_andrews_ghibli_grass.png")
		// s.grass_field_texture = TEMP_load_color_texture("assets/blue_grass.png")


		s.meshes["pillar"] = TEMP_load_mesh_gltf("assets/shrubs.glb", "mock_coordinate_pillar")
		s.meshes["stone"] = TEMP_load_mesh_gltf("assets/shrubs.glb", "mock_shrub")

		set_pieces := []SetPiece {
			{&s.meshes["pillar"], &white_texture, {0.5, 0.5, 0.6}, {0, 0, 0} },
			
			{&s.meshes["stone"], &white_texture, {0.5, 0.5, 0.6}, {3, 0, 0.5}, },
			{&s.meshes["stone"], &white_texture, {0.5, 0.5, 0.6}, {2.8, 1, 0.5}, },
			{&s.meshes["stone"], &white_texture, {0.5, 0.5, 0.6}, {0, 2, 0.5}, },
			{&s.meshes["stone"], &white_texture, {0.5, 0.5, 0.6}, {1, 3, 0.5}, },
		}

		s.set_pieces = make([]SetPiece, len(set_pieces))
		copy(s.set_pieces, set_pieces)
		
	case .Blue_Hills_Zone:
		// systems
		s.terrain 	= create_terrain()
		s.grass 	= create_grass()

		// resources
		// s.grass_field_texture = TEMP_load_color_texture("assets/cgshare-book-grass-01.jpg")
		// s.grass_field_texture = TEMP_load_color_texture("assets/callum_andrews_ghibli_grass.png")
		s.grass_field_texture = TEMP_load_color_texture("assets/blue_grass.png")

		s.meshes["pillar"] = TEMP_load_mesh_gltf("assets/shrubs.glb", "mock_coordinate_pillar")
		s.meshes["stone"] = TEMP_load_mesh_gltf("assets/shrubs.glb", "mock_shrub")

		set_pieces := []SetPiece {
			{&s.meshes["pillar"], &white_texture, {0.5, 0.5, 0.6}, {0, 0, 0} },
			
			{&s.meshes["stone"], &white_texture, {0.5, 0.5, 0.6}, {3, 0, 0.5}, },
			{&s.meshes["stone"], &white_texture, {0.5, 0.5, 0.6}, {2.8, 1, 0.5}, },
			{&s.meshes["stone"], &white_texture, {0.5, 0.5, 0.6}, {0, 2, 0.5}, },
			{&s.meshes["stone"], &white_texture, {0.5, 0.5, 0.6}, {1, 3, 0.5}, },
		}

		s.set_pieces = make([]SetPiece, len(set_pieces))
		copy(s.set_pieces, set_pieces)
	

	case .Big_Rock:
		// systems
		s.terrain 	= create_terrain()
		s.grass 	= create_grass()

		// resources
		// s.grass_field_texture = TEMP_load_color_texture("assets/cgshare-book-grass-01.jpg")
		s.grass_field_texture = TEMP_load_color_texture("assets/callum_andrews_ghibli_grass.png")
		// s.grass_field_texture = TEMP_load_color_texture("assets/blue_grass.png")

		s.textures["rock"] = TEMP_load_color_texture("assets/rock_01_diff_4k.jpg")
		s.meshes["big_rock_1"] = TEMP_load_mesh_gltf("assets/terrain.glb", "terrain_big_rock_1")


		set_pieces := []SetPiece {
			{&s.meshes["big_rock_1"], &s.textures["rock"], {0.5, 0.5, 0.6}, {1, 3, 0.5}, },
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

	for _, mesh in &s.meshes {
		graphics.destroy_mesh(&mesh)
	}
	delete(s.meshes)

	for _, texture in &s.textures {
		graphics.destroy_texture(&texture)
	}

	free(s)
}

render_scene :: proc(s : ^Scene) {

}