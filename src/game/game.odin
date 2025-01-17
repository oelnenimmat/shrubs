package game

/*
The actual core application main file. Initialize, terminate and
update all systems from this file
*/

import "shrubs:assets"
import "shrubs:debug"
import graphics "shrubs:graphics/vulkan"
import "shrubs:imgui"
import "shrubs:input"
import "shrubs:physics"
import "shrubs:window"

import "core:fmt"
import "core:intrinsics"
import "core:math"
import "core:math/linalg"
import "core:os"
import "core:path/filepath"
import "core:reflect"
import "core:slice"
import "core:strings"
import "core:time"

import "shrubs:common"
vec2 		:: common.vec2
vec3 		:: common.vec3
vec4 		:: common.vec4
mat3 		:: common.mat3
mat4 		:: common.mat4
quaternion 	:: common.quaternion

matrix4_mul_point 		:: common.matrix4_mul_point
matrix4_mul_vector 		:: common.matrix4_mul_vector
matrix4_mul_rotation 	:: common.matrix4_mul_rotation

IS_ACTUALLY_EDITOR :: true

WINDOW_WIDTH :: 960
WINDOW_HEIGHT :: 540

APPLICATION_NAME :: "Shrubs"

SCENES_DIRECTORY :: "scenes/"
SCENE_FILE_EXTENSION :: ".scene"

// Todo(Leo): All the components should not be here in the wild,
// can easily lead into spaghetti and/or confusion. Some more 
// service like things like camera are fine

// Actors??
player_character 	: PlayerCharacter
main_camera 		: Camera
tank 				: Tank
hoverbike 			: Hoverbike

player_material : graphics.BasicMaterial
terrain_material : graphics.TerrainMaterial

scene : ^Scene
grass_types : GrassTypes
grass_system : Grass

grass_blade_count := 32
grass_segment_count := 3

lod_enabled 	:= 2
draw_normals 	:= false
draw_backfacing := false
draw_lod 		:= false
grass_cull_back := false

grass_chunk_size := f32(5)

grass_type_to_edit : GrassType

// Resources
// this is in its own file for now
// asset_provider : AssetProvider

application : struct {
	wants_to_quit 	: bool,
	mode 			: enum { Game, Edit },
}

show_imgui_demo := false
show_timings := true
timings : struct {
	frame_time : SmoothValue(30),
}

show_debug_values := true

test_position : vec3

save_screenshot := false
generate_terrain_mesh := false

available_scenes : struct {
	filenames 		: []string,
	display_names 	: []string,
}

wind : struct {
	enabled : bool,
	time 	: f32,
	offset 	: vec2
}

main_render_target : graphics.RenderTarget
tank_render_target : graphics.RenderTarget

world_mesh : graphics.Mesh
world_material : graphics.BasicMaterial

// Current collision detection cannot handle too big size difference 
// so we stick with 20 m radius for now
// world_radius := f32(1000)
// world_radius := f32(100)
world_radius := f32(20)

initialize :: proc() {
	// Todo(Leo): some of this stuff seems to bee "application" or "engine" and not "game"
	window.initialize(WINDOW_WIDTH, WINDOW_HEIGHT, APPLICATION_NAME)
	input.initialize()
	graphics.initialize()
	imgui.initialize(window.get_glfw_window_handle())
	debug.initialize(256)
	physics.initialize()

	// render targets
	main_render_target = graphics.create_render_target(1920, 1080, 2)
	tank_render_target = graphics.create_render_target(800, 600, 2)

	// Common resources
	load_asset_provider()

	// Scene independent systems
	main_camera 		= create_camera()
	tank 				= create_tank()
	player_character 	= create_player_character()
	hoverbike 			= create_hoverbike()

	// Application is started in edit mode
	application.mode = .Edit

	// Todo(Leo): Not sure how to categorize this yet?
	grass_types = create_grass_types()
	load_grass_types(&grass_types)
	grass_system = create_grass()

	// Detect available scenes
	{

		// Todo(Leo): check error :)
		h, e := os.open(SCENES_DIRECTORY)
		defer os.close(h)
		
		// Todo(Leo): check error :)
		scene_directory, err := os.read_dir(h, 10, context.temp_allocator)
		// found_scenes := make([dynamic]SceneInfo, 0, 100, context.temp_allocator)
		
		filenames 		:= make([dynamic]string, context.temp_allocator)
		display_names 	:= make([dynamic]string, context.temp_allocator)

		for f in scene_directory {
			fmt.println(f.name, filepath.ext(f.name))
			if filepath.ext(f.name) == SCENE_FILE_EXTENSION {

				// Todo(Leo): maybe validate this somehow?
				b := strings.builder_make(context.temp_allocator)
				fmt.sbprintf(&b, "{}{}", SCENES_DIRECTORY, f.name)

				append(&filenames, strings.clone(strings.to_string(b), context.allocator))
				append(&display_names, strings.clone(filepath.stem(f.name), context.allocator))
			} else {
				// fmt.println("NOT SCENE!")
			}
		}
		available_scenes.filenames = slice.clone(filenames[:], context.allocator)
		available_scenes.display_names = slice.clone(display_names[:], context.allocator)
	}


	// Scene
	if IS_ACTUALLY_EDITOR {
		load_editor_state()

		// If we good, we load the previously loaded scene
		for name, index in available_scenes.display_names {
			if name == editor.loaded_scene_name {
				scene = load_scene(index)
			}
		}

		// otherwise, lets hope we at least have some
		if scene == nil {
			scene = load_scene(0)
		}
	}

	wind.enabled = true

	player_material = graphics.create_basic_material(&asset_provider.textures[.White])
	player_material.mapped.surface_color = {0.6, 0.2, 0.4, 1}

	terrain_material = graphics.create_terrain_material(
		&asset_provider.textures[.Road],
		&asset_provider.textures[.Green_Grass_Field],
	)

	graphics.set_world_data(
		scene.world.placement_scale,
		scene.world.placement_offset,
		{},
		&asset_provider.textures[.Grass_Placement],
	)

	graphics.set_wind_data(
		{},
		0,
		&asset_provider.textures[.Wind],
	)

	world_mesh = load_mesh_gltf("assets/shapes.glb", "shape_hi_res_sphere")
	world_material = graphics.create_basic_material(&asset_provider.textures[.Road])
	world_material.mapped.surface_color = {1, 1, 1, 1}
	world_material.mapped.texcoord_scale = 0.1
}

terminate :: proc() {
	graphics.wait_idle()


	save_editor_state()

	destroy_tank(&tank)
	destroy_hoverbike(&hoverbike)



	graphics.destroy_mesh(&world_mesh)
	graphics.destroy_basic_material(&world_material)
	graphics.destroy_basic_material(&player_material)

	destroy_grass(&grass_system)
	save_grass_types(&grass_types)
	destroy_grass_types(&grass_types)


	// Todo(Leo): not really necessary at this point, but I keep these here
	// to remeber that destroying stuff is at times actually necessary.
	unload_scene(scene)
	unload_asset_provider()

	physics.terminate()
	debug.terminate()
	imgui.terminate()
	graphics.terminate()
	input.terminate()
	window.terminate()
}

does_want_to_quit :: proc() -> bool {
	return window.should_close() || application.wants_to_quit
}

update :: proc(delta_time: f64) {


	///////////////////////////////////////////////////////////////////////////
	// PREPARE FOR GAME UPDATE 
	// Todo(Leo): this doesn't feel like "game" thing, more "application" or "engine"
	// clear the temp allocator here
	free_all(context.temp_allocator)
	clear_debug_values()

	// note(Leo): in main we have delta time as f64, but for the most part
	// we now use f32 for rendering reasons, so it is more straightforward
	// to just use f32 everywhere here
	delta_time := f32(delta_time)
	smooth_value_put(&timings.frame_time, delta_time) 

	///////////////////////////////////////////////////////////////////////////
	// APPLICATION UPDATE
	// Need to always call window.XXX_frame(), then input.XXX_frame
	// Todo(Leo): maybe combine, or move to main.odin
	window.begin_frame()
	input.begin_frame()
	debug.new_frame()


	if input.DEBUG_get_key_pressed(.Q, {.Ctrl}) {
		application.wants_to_quit = true
	}

	if input.DEBUG_get_key_pressed(.Escape) {

		application.mode = .Edit if application.mode == .Game else .Game

		switch application.mode {
		case .Edit:
			input.lock_mouse(editor.mode == .FlyView)
		case .Game:
			input.lock_mouse(true)
		}
	}

	if input.DEBUG_get_key_pressed(.F12) {
		save_screenshot = true
	}


	///////////////////////////////////////////////////////////////////////////
	// START OF GAME UPDATE
	// Todo(Leo): physics.tick()???? Maybe physics update can be done from here??

	if generate_terrain_mesh {
		generate_terrain_mesh = false
	
		destroy_terrain_meshes(&scene.terrain)

		scene.terrain.positions, scene.terrain.meshes = create_terrain_meshes(&scene.world)
	}

	if application.mode == .Game {

		physics.begin_frame(delta_time)
		
		// world
		{
			// old test sphere world
			colliders := []physics.SphereCollider {{vec3(0), world_radius}}
			physics.submit_colliders(colliders)

			physics.submit_colliders(scene.terrain.colliders)
		}

		// submit greyboxes
		{	
			g := &scene.greyboxing
			base_t := g.base_position
			base_r := linalg.quaternion_from_euler_angles(g.base_rotation.x, g.base_rotation.y, g.base_rotation.z, .XYZ)
			base_transform := linalg.matrix4_from_trs(base_t, base_r, vec3(1))

			colliders := make([]physics.BoxCollider, len(scene.greyboxing.boxes), context.temp_allocator)
			for _, i in colliders {
				b := scene.greyboxing.boxes[i]
				colliders[i] = {
					matrix4_mul_point(base_transform, b.position),
					base_r * linalg.quaternion_from_euler_angles(b.rotation.x, b.rotation.y, b.rotation.z, .XYZ),
					b.size,
				} 
			}
			physics.submit_colliders(colliders)
		}

		// Todo(Leo): update colliders in a sensible manner
		for _ in 0..<physics.ticks_this_frame() {
			physics_update_hoverbike(&hoverbike)
			// physics_update_tank(&tank)
			// physics_update_player_character(&player_character)
		}


		debug.draw_line(player_character.position, hoverbike.position, debug.RED)

		// tank submits colliders that player needs to use, so that need to update first
		// Todo(Leo): maybe have a collider handle that is just updated or something, but this
		// works now, when things are not too complicated. Also there will be a need to think
		// about the order of execution
		update_tank(&tank, delta_time)
		update_player_character(&player_character, &main_camera, delta_time)
	} else if application.mode == .Edit {
		update_editor_camera(&main_camera, delta_time)
	}

	put_debug_value("hoverbike position", hoverbike.position)
	put_debug_value("hoverbike velocity", hoverbike.velocity)
	put_debug_value("hoverbike speed m/s", linalg.length(hoverbike.velocity))
	put_debug_value("hoverbike speed km/h", linalg.length(hoverbike.velocity) * 3.6)


	if wind.enabled {
		wind.time += delta_time
		wind.offset.x += delta_time * 0.06
		wind.offset.y += delta_time * 0.03
	}
	wind_amount := math.sin(wind.time) * 0.5


	if input.DEBUG_get_key_pressed(.U) {
		wind.enabled = !wind.enabled
	}

	// END OF UPDATE
	///////////////////////////////////////////////////////////////////////////

	///////////////////////////////////////////////////////////////////////////
	// GUI
	{
		// Todo(Leo): these are from last frame, does it matter? Probably not much, as
		// typically we are not operating camera and gizmo in the same frame
		projection, view := camera_get_projection_and_view_matrices(&main_camera)

		// Cancel this
		projection[1,1] *= -1

		imgui.begin_frame(projection, view)
		if show_imgui_demo {
			imgui.ShowDemoWindow()
		}		
	}

	imgui.SetNextWindowPos({10, 10})
	imgui.SetNextWindowSize({300, 0})
	next_window_Y := f32(10)
	if show_timings {
		if imgui.Begin("Timings", nil, .NoResize | .NoScrollbar | .NoCollapse | .NoNav) {
			if imgui.BeginTable("time table", 2) {

				imgui.TableNextRow()
				imgui.TableNextColumn()
				imgui.text("frame time")
				imgui.TableNextColumn()
				imgui.text("{:5.2f} ms (fps {})", timings.frame_time.value * 1000, int(1 / timings.frame_time.value))

				imgui.EndTable()
			}
		}
		next_window_Y += imgui.GetWindowHeight() + 10
		imgui.End()
	}
	imgui.SetNextWindowPos({10, next_window_Y})

	imgui.SetNextWindowSize({300, 0})
	if show_debug_values {
		if imgui.Begin("Debug Values", nil, .NoResize | .NoScrollbar | .NoCollapse | .NoNav) {
			for v in debug_values {
				switch value in v.value {
					case f32: imgui.value(v.label, value)
					case int: imgui.value(v.label, value)
					case bool: imgui.value(v.label, value)
					case vec3: imgui.value(v.label, value)
				}

			}
		}
		next_window_Y += imgui.GetWindowHeight() + 10
		imgui.End()
	}
	imgui.SetNextWindowPos({10, next_window_Y})

	if application.mode == .Edit {
		_, window_height := window.get_window_size()
		imgui.SetNextWindowSize({300, f32(window_height) - next_window_Y - 10})
		editor_gui()
		update_grass_type_buffer(&grass_types)
	}

	editor_do_gizmos()

	imgui.end_frame()
}

render :: proc() {

	graphics.begin_frame()

	// render_camera(&tank.front_camera, &tank_render_target)
	render_camera(&main_camera, &main_render_target)

	// NEXT PIPELINE
	graphics.draw_post_process(scene.lighting.exposure)

	// Currently we provide a service to save screenshots from the final game view, before gui :thumbs_up:
	if save_screenshot {
		save_screenshot = false

		width, height, pixels := graphics.copy_screenshot_buffer(context.temp_allocator)

		now := time.now()

		NANOSECS_IN_HOUR :: 3.6e12
		now_but_in_my_timezone := time.Time { now._nsec + 3 * NANOSECS_IN_HOUR }

		buffer : [128]u8
		filename_builder := strings.builder_from_bytes(buffer[:])
		fmt.sbprintf(
			&filename_builder,

			// year is always 4 chars, pad rest with leading zeros so file system
			// sorts them properly
			"local/screenshots/screen_framebuffer_{}_{:2i}_{:2i}_{:2i}_{:2i}_{:2i}.png",
			time.date(now_but_in_my_timezone),
			time.clock_from_time(now_but_in_my_timezone),
		)
		assets.write_color_image(strings.to_string(filename_builder), width, height, pixels)
	}

	// NEXT PIPELINE
	imgui.render()


	// End of pipelines
	graphics.render()


	// Todo(Leo): not so nice to have these in render, this is a clue to put this stuff
	// outside "game", to main.odin
	// Need to always call window.XXX_frame(), then input.XXX_frame
	// Todo(Leo): maybe combine, or move to main.odin
	window.end_frame()
	input.end_frame()
}

render_camera :: proc(camera : ^Camera, render_target : ^graphics.RenderTarget) {
	// NEXT PIPELINE
	// Todo(Leo): compute grass lod locations
	
	player_position 	:= player_character.position
	player_view_forward := player_character.view_forward

	player_grass_tile_x := int(math.floor(player_position.x / GRASS_TILE_SIZE_1D))
	player_grass_tile_y := int(math.floor(player_position.y / GRASS_TILE_SIZE_1D))

	lod_0_tile_position := vec3{
		f32(player_grass_tile_x) * GRASS_TILE_SIZE_1D,
		f32(player_grass_tile_y) * GRASS_TILE_SIZE_1D,
		0,
	}

	lod_1_tile_positions := []vec3 {
		lod_0_tile_position + {-1, -1, 0} * GRASS_TILE_SIZE_1D,
		lod_0_tile_position + {0, -1, 0} * GRASS_TILE_SIZE_1D,
		lod_0_tile_position + {1, -1, 0} * GRASS_TILE_SIZE_1D,

		lod_0_tile_position + {-1, 0, 0} * GRASS_TILE_SIZE_1D,
		lod_0_tile_position + {1, 0, 0} * GRASS_TILE_SIZE_1D,
		
		lod_0_tile_position + {-1, 1, 0} * GRASS_TILE_SIZE_1D,
		lod_0_tile_position + {0, 1, 0} * GRASS_TILE_SIZE_1D,
		lod_0_tile_position + {1, 1, 0} * GRASS_TILE_SIZE_1D,
	}

	lod_2_tile_positions := []vec3 {
		lod_0_tile_position + {-3, -3, 0} * GRASS_TILE_SIZE_1D,
		lod_0_tile_position + {-2, -3, 0} * GRASS_TILE_SIZE_1D,
		lod_0_tile_position + {-1, -3, 0} * GRASS_TILE_SIZE_1D,
		lod_0_tile_position + {0, -3, 0} * GRASS_TILE_SIZE_1D,
		lod_0_tile_position + {1, -3, 0} * GRASS_TILE_SIZE_1D,
		lod_0_tile_position + {2, -3, 0} * GRASS_TILE_SIZE_1D,
		lod_0_tile_position + {3, -3, 0} * GRASS_TILE_SIZE_1D,
		
		lod_0_tile_position + {-3, -2, 0} * GRASS_TILE_SIZE_1D,
		lod_0_tile_position + {-2, -2, 0} * GRASS_TILE_SIZE_1D,
		lod_0_tile_position + {-1, -2, 0} * GRASS_TILE_SIZE_1D,
		lod_0_tile_position + {0, -2, 0} * GRASS_TILE_SIZE_1D,
		lod_0_tile_position + {1, -2, 0} * GRASS_TILE_SIZE_1D,
		lod_0_tile_position + {2, -2, 0} * GRASS_TILE_SIZE_1D,
		lod_0_tile_position + {3, -2, 0} * GRASS_TILE_SIZE_1D,
		
		lod_0_tile_position + {-3, -1, 0} * GRASS_TILE_SIZE_1D,
		lod_0_tile_position + {-2, -1, 0} * GRASS_TILE_SIZE_1D,
		lod_0_tile_position + {2, -1, 0} * GRASS_TILE_SIZE_1D,
		lod_0_tile_position + {3, -1, 0} * GRASS_TILE_SIZE_1D,

		lod_0_tile_position + {-3, 0, 0} * GRASS_TILE_SIZE_1D,
		lod_0_tile_position + {-2, 0, 0} * GRASS_TILE_SIZE_1D,
		lod_0_tile_position + {2, 0, 0} * GRASS_TILE_SIZE_1D,
		lod_0_tile_position + {3, 0, 0} * GRASS_TILE_SIZE_1D,

		lod_0_tile_position + {-3, 1, 0} * GRASS_TILE_SIZE_1D,
		lod_0_tile_position + {-2, 1, 0} * GRASS_TILE_SIZE_1D,
		lod_0_tile_position + {2, 1, 0} * GRASS_TILE_SIZE_1D,
		lod_0_tile_position + {3, 1, 0} * GRASS_TILE_SIZE_1D,
		
		lod_0_tile_position + {-3, 2, 0} * GRASS_TILE_SIZE_1D,
		lod_0_tile_position + {-2, 2, 0} * GRASS_TILE_SIZE_1D,
		lod_0_tile_position + {-1, 2, 0} * GRASS_TILE_SIZE_1D,
		lod_0_tile_position + {0, 2, 0} * GRASS_TILE_SIZE_1D,
		lod_0_tile_position + {1, 2, 0} * GRASS_TILE_SIZE_1D,
		lod_0_tile_position + {2, 2, 0} * GRASS_TILE_SIZE_1D,
		lod_0_tile_position + {3, 2, 0} * GRASS_TILE_SIZE_1D,
		
		lod_0_tile_position + {-3, 3, 0} * GRASS_TILE_SIZE_1D,
		lod_0_tile_position + {-2, 3, 0} * GRASS_TILE_SIZE_1D,
		lod_0_tile_position + {-1, 3, 0} * GRASS_TILE_SIZE_1D,
		lod_0_tile_position + {0, 3, 0} * GRASS_TILE_SIZE_1D,
		lod_0_tile_position + {1, 3, 0} * GRASS_TILE_SIZE_1D,
		lod_0_tile_position + {2, 3, 0} * GRASS_TILE_SIZE_1D,
		lod_0_tile_position + {3, 3, 0} * GRASS_TILE_SIZE_1D,
	}


	grass_system.lod_positions[0][0] = lod_0_tile_position
	copy(grass_system.lod_positions[1], lod_1_tile_positions)
	copy(grass_system.lod_positions[2], lod_2_tile_positions)


	graphics.begin_grass_placement()

	lod_blade_counts := []f32{GRASS_LOD_0_BLADE_COUNT_1D, GRASS_LOD_1_BLADE_COUNT_1D, GRASS_LOD_2_BLADE_COUNT_1D}

	for _, lod in grass_system.lod_renderers {
		for _, i in grass_system.lod_renderers[lod] {

			input := grass_system.lod_renderers[lod][i].placement_input_mapped

			input[0].x = f32(scene.grass_type)
			input[1] = {
				grass_system.lod_positions[lod][i].x,
				grass_system.lod_positions[lod][i].y,
				GRASS_TILE_SIZE_1D,
				lod_blade_counts[lod]
			}

			graphics.dispatch_grass_placement_chunk(&grass_system.lod_renderers[lod][i])
		}		
	}

	graphics.end_grass_placement()


	///////////////////////////////////////////////////////////////////////////
	// Rendering

	graphics.bind_render_target(render_target)
	// graphics.bind_framebuffer(&render_target)

	light_direction := matrix4_mul_vector(
						linalg.matrix4_rotate_f32(scene.lighting.direction_polar.x * math.PI / 180, OBJECT_UP) *
						linalg.matrix4_rotate_f32(scene.lighting.direction_polar.y * math.PI / 180, OBJECT_RIGHT),
						OBJECT_FORWARD)
	light_color := scene.lighting.directional_color.rgb
	ambient_color := scene.lighting.ambient_color.rgb

	projection_matrix, view_matrix := camera_get_projection_and_view_matrices(camera)

	graphics.set_per_frame_data(view_matrix, projection_matrix)
	graphics.set_lighting_data(camera.position, light_direction, light_color, ambient_color)
	graphics.set_wind_data(wind.offset, 0.005, nil)
	
	noise_params := vec4 {
		f32(scene.world.seed),
		scene.world.noise_scale,
		scene.world.z_scale,
		scene.world.z_offset,
	}
	graphics.set_world_data(
		scene.world.placement_scale,
		scene.world.placement_offset,
		noise_params,
		nil, //&asset_provider.textures[.White],
	)
	
	graphics.set_debug_data(draw_normals, draw_backfacing, draw_lod)

	// setupped shared stuff, can start drawink

	// NEXT PIPELINE
	graphics.setup_basic_pipeline()
	

	render_tank(&tank)
	render_hoverbike(&hoverbike)
	render_greyboxing(&scene.greyboxing)

	graphics.set_basic_material(&world_material)
	graphics.draw_mesh(&world_mesh, linalg.matrix4_scale_f32(world_radius * 2))

	// Player character as a capsule for debug purposes
	// graphics.set_basic_material({0.6, 0.2, 0.4}, &asset_provider.textures[.White])
	graphics.set_basic_material(&player_material)
	player_rotation : mat4
	{
		f := player_character.forward
		u := player_character.up
		r := linalg.normalize(linalg.cross(f, u))
		player_rotation = {
			r.x, f.x, u.x, 0,
			r.y, f.y, u.y, 0,
			r.z, f.z, u.z, 0,
			0, 0, 0, 1
		}
	}

	model_matrix := linalg.matrix4_translate_f32(player_get_position(&player_character) + player_character.up * f32(1.0)) *
					player_rotation *
					linalg.matrix4_scale_f32(2)
	graphics.draw_mesh(&asset_provider.meshes[.Capsule], model_matrix)

	// NEXT PIPELINE
	{
		graphics.setup_emissive_pipeline()

		texture := graphics.render_target_as_texture(&tank_render_target)
		graphics.set_emissive_material(&texture)
		position := tank.body_position + linalg.quaternion_mul_vector3(tank.body_rotation, TANK_FRONT_CAMERA_SCREEN_POSITION_LS)
		rotation := tank.body_rotation * linalg.quaternion_from_euler_angles_f32(0.5 * math.PI, 0, 0, .XYZ)
		model := linalg.matrix4_from_trs (
			position,
			rotation,
			TANK_FRONT_CAMERA_SCREEN_SIZE,
		)
		graphics.draw_mesh(&asset_provider.meshes[.Quad], model)
	}

	// NEXT PIPELINE
	graphics.setup_terrain_pipeline()
	graphics.set_terrain_material(&terrain_material)
	for p, i in scene.terrain.positions {
		model_matrix := linalg.matrix4_translate_f32(p)
		graphics.draw_mesh(&scene.terrain.meshes[i], model_matrix)
	}

	// NEXT PIPELINE
	graphics.setup_grass_pipeline(grass_cull_back)
	for _, lod in grass_system.lod_renderers {
		for _, i in grass_system.lod_renderers[lod] {
			graphics.draw_grass(grass_system.lod_renderers[lod][i], 0, 0, 0)
		}
	}

	// NEXT PIPELINE
	graphics.draw_sky()
	graphics.wait_for_grass()

	debug.draw_line(player_character.position + {0, 0, 2}, player_character.position + {1, 0, 2}, debug.RED)
	debug.draw_line(player_character.position + {0, 0, 2}, player_character.position + {0, 1, 2}, debug.GREEN)
	debug.draw_line(player_character.position + {0, 0, 2}, player_character.position + {0, 0, 3}, debug.BLUE)

	// NEXT PIPELINE
	debug.render()

	// FINISH
	// graphics.resolve_render_target(render_target)
}

// This is a mockup, really probably each component (e.g. playback) should have
// their corresponding parts there. Not sure though. 
editor_gui :: proc() {

	if imgui.Begin("Shrubs!!") {

		// Gizmo options now always visible
		{
			imgui.enum_dropdown("Gizmo", &editor.gizmo_type)

			if input.DEBUG_get_key_pressed(._1) { editor.gizmo_type = .None }
			if input.DEBUG_get_key_pressed(._2) { editor.gizmo_type = .Translate }
			if input.DEBUG_get_key_pressed(._3) { editor.gizmo_type = .Rotate }
			if input.DEBUG_get_key_pressed(._4) { editor.gizmo_type = .Size }

			imgui.enum_dropdown("Orientation", &editor.gizmo_orientation)

			if input.DEBUG_get_key_pressed(._5) { 
				o := &editor.gizmo_orientation
				o^ = .Local if o^ == .World else .World
			}
		}

		if imgui.button("Save Screenshot") { save_screenshot = true }

		if imgui.CollapsingHeader("Scenes") {
			if imgui.Button("Save Current Scene") {
				save_scene(scene)
			}

			imgui.text("Current scene: {}", scene.name)

			@static selected_scene_index : int
			imgui.slice_dropdown("##scene", &selected_scene_index, available_scenes.display_names)
			imgui.SameLine()
			if imgui.button("load") {
				unload_scene(scene)
				scene = load_scene(selected_scene_index)
				editor.loaded_scene_name = available_scenes.display_names[selected_scene_index]
			}


			imgui.Separator()
			if imgui.TreeNode("Textures") {
				for t in TextureUseName {
					if imgui.enum_dropdown(reflect.enum_string(t), &scene.texture_uses[t]) {
						scene.textures[t] = &asset_provider.textures[scene.texture_uses[t]]
					}
				}
				imgui.TreePop()
			}
		}

		if imgui.CollapsingHeader("World") { edit_world_settings(&scene.world) }

		if imgui.CollapsingHeader("Lighting") {
			l := &scene.lighting
			imgui.SliderFloat("Polar X", &l.direction_polar.x, 0, 360)
			imgui.SliderFloat("Polar Y", &l.direction_polar.y, -90, 90)
			imgui.ColorEdit3("Directional", auto_cast &l.directional_color, .HDR | .Float | .DisplayHSV)
			imgui.ColorEdit3("Ambient", auto_cast &l.ambient_color, .HDR | .Float | .DisplayHSV)
			imgui.DragFloat("Exposure", &l.exposure, 0.01)

		}

		if imgui.CollapsingHeader("Grass!") {
			if imgui.button("Save") {
				save_grass_types(&grass_types)
			}

			imgui.enum_dropdown("Scene type", &scene.grass_type)

			imgui.enum_dropdown("Edit type", &grass_type_to_edit)
			settings := &grass_types.settings[grass_type_to_edit]

			imgui.text("LOD")
			if imgui.button("auto") { lod_enabled = -1 }; imgui.SameLine() 
			if imgui.button("0") { lod_enabled = 0 }; imgui.SameLine() 
			if imgui.button("1") { lod_enabled = 1 }; imgui.SameLine() 
			if imgui.button("2") { lod_enabled = 2 }


			imgui.text("Blade")
			// mu.layout_row(ctx, label_and_element_layout)
			imgui.SliderFloat("Height", &settings.height, 0, 2)
			imgui.SliderFloat("Variation", &settings.height_variation, 0, 2)
			imgui.SliderFloat("Width", &settings.width, 0, 0.3)
			imgui.SliderFloat("Bend", &settings.bend, -1, 1)
			
			imgui.text("Clump")
			// mu.layout_row(ctx, label_and_element_layout)
			imgui.SliderFloat("Size", &settings.clump_size, 0, 3)
			imgui.SliderFloat("Height variation", &settings.clump_height_variation, 0, 2)
			imgui.SliderFloat("Squeeze in", &settings.clump_squeeze_in, -1, 1)

			imgui.ColorEdit3("top color", cast(^f32)(&settings.top_color))
			imgui.ColorEdit3("bottom color", cast(^f32)(&settings.bottom_color))

			imgui.SliderFloat("roughness", &grass_types.settings[grass_type_to_edit].roughness, 0, 1)
		}

		if imgui.CollapsingHeader("Greyboxing") {
			edit_greyboxing(&scene.greyboxing)
		}

		if imgui.CollapsingHeader("Debug") {
			imgui.checkbox("Show Timinfs", &show_timings)
			imgui.checkbox("Show Debug Values", &show_debug_values)
			imgui.checkbox("Show Imgui Demo", &show_imgui_demo)

			imgui.checkbox("Draw Normals", &draw_normals)
			imgui.checkbox("Draw Backfacing", &draw_backfacing)
			imgui.checkbox("Draw LOD", &draw_lod)
			imgui.checkbox("Grass Cull Back", &grass_cull_back)
		}
	}
	imgui.End()

	
}
