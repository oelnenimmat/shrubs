package game


Scene :: struct {
	grass : Grass,
	terrain : Terrain,

}

load_scene :: proc() -> Scene {
	s : Scene
	s.terrain 	= create_terrain()
	s.grass 	= create_grass()

	return s
}

unload_scene :: proc(s : ^Scene) {

	// Todo(Leo): now these actually need to be implemented
	destroy_terrain(&s.terrain)
	destroy_grass(&s.grass)

}

render_scene :: proc(s : ^Scene) {

}