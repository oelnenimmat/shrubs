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
	grass : Grass,
	terrain : Terrain,

	grass_field_texture : graphics.Texture,

	stone_mesh 	: graphics.Mesh,
	pillar_mesh : graphics.Mesh,

	set_pieces : []SetPiece,
}

// Todo(Leo): take pointer argument for lazy allocation issues. If we make a
// local variable here to return, pointer to it don't work.
load_scene :: proc(s : ^Scene) {
// load_scene :: proc() -> Scene {
	s^ = {}
	
	// systems
	s.terrain 	= create_terrain()
	s.grass 	= create_grass()

	// resources
	// s.grass_field_texture = TEMP_load_color_texture("assets/cgshare-book-grass-01.jpg")
	s.grass_field_texture = TEMP_load_color_texture("assets/callum_andrews_ghibli_grass.png")
	// s.grass_field_texture = TEMP_load_color_texture("assets/blue_grass.png")

	s.pillar_mesh = TEMP_load_mesh_gltf("assets/shrubs.glb", "mock_coordinate_pillar")
	s.stone_mesh = TEMP_load_mesh_gltf("assets/shrubs.glb", "mock_shrub")

	set_pieces := []SetPiece {
		{&s.pillar_mesh, &white_texture, {0.5, 0.5, 0.6}, {0, 0, 0} },
		
		{&s.stone_mesh, &white_texture, {0.5, 0.5, 0.6}, {3, 0, 0.5}, },
		{&s.stone_mesh, &white_texture, {0.5, 0.5, 0.6}, {2.8, 1, 0.5}, },
		{&s.stone_mesh, &white_texture, {0.5, 0.5, 0.6}, {0, 2, 0.5}, },
		{&s.stone_mesh, &white_texture, {0.5, 0.5, 0.6}, {1, 3, 0.5}, },
	}

	s.set_pieces = make([]SetPiece, len(set_pieces))
	copy(s.set_pieces, set_pieces)
	
	// return s
}

unload_scene :: proc(s : ^Scene) {

	// Todo(Leo): now these actually need to be implemented
	destroy_terrain(&s.terrain)
	destroy_grass(&s.grass)

}

render_scene :: proc(s : ^Scene) {

}