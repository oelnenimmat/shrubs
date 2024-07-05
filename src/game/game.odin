package game

/*
The actual core application main file. Initialize, terminate and
update all systems from this file
*/

import "shrubs:assets"
import "shrubs:common"
import "shrubs:debug"
import "shrubs:graphics"
import "shrubs:gui"
import "shrubs:input"
import "shrubs:physics"
import "shrubs:window"

import "core:math"
import "core:reflect"
import "core:math/linalg"
import mu "vendor:microui"

vec2 		:: common.vec2
vec3 		:: common.vec3
vec4 		:: common.vec4
dvec3 		:: common.dvec3
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

// Todo(Leo): All the components should not be here in the wild,
// can easily lead into spaghetti and/or confusion. Some more 
// service like things like camera are fine

// Actors??
player_character 	: PlayerCharacter
camera 				: Camera
tank 				: Tank

scene : ^Scene

grass_blade_count := 256

draw_normals := false
grass_cull_back := false

// post_processing : struct {
// 	exposure : f32,
// }

// Resources
white_texture 	: graphics.Texture
black_texture 	: graphics.Texture
capsule_mesh 	: graphics.Mesh

application : struct {
	wants_to_quit 	: bool,
	mode 			: enum { Game, Edit }, 
}

initialize :: proc() {
	// Todo(Leo): some of this stuff seems to bee "application" or "engine" and not "game"
	window.initialize(WINDOW_WIDTH, WINDOW_HEIGHT, APPLICATION_NAME)
	input.initialize()
	graphics.initialize()
	gui.initialize()
	debug.initialize(256)
	physics.initialize()

	// Common resources
	white_texture = graphics.create_color_texture(
		1, 1, []common.Color_u8_rgba{{255, 255, 255, 255}}, .Nearest,
	)

	black_texture = graphics.create_color_texture(
		1, 1, []common.Color_u8_rgba{{0, 0, 0, 255}}, .Nearest,
	)


	capsule_mesh = TEMP_load_mesh_gltf("assets/shapes.glb", "shape_capsule")

	// Scene independent systems
	camera 				= create_camera()
	tank 				= create_tank()
	player_character 	= create_player_character()

	// Application is started in edit mode
	application.mode = .Edit

	// Scene
	if IS_ACTUALLY_EDITOR {
		load_editor_state()
		scene = load_scene(editor.loaded_scene_name)
	}

}

terminate :: proc() {
	save_editor_state()

	// Todo(Leo): not really necessary at this point, but I keep these here
	// to remeber that destroying stuff is at times actually necessary.
	unload_scene(scene)

	physics.terminate()
	debug.terminate()
	gui.terminate()
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

	// note(Leo): in main we have delta time as f64, but for the most part
	// we now use f32 for rendering reasons, so it is more straightforward
	// to just use f32 everywhere here
	delta_time := f32(delta_time)


	///////////////////////////////////////////////////////////////////////////
	// APPLICATION UPDATE
	// Need to always call window.XXX_frame(), then input.XXX_frame
	// Todo(Leo): maybe combine, or move to main.odin
	window.begin_frame()
	input.begin_frame()
	gui.begin_frame()
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

	if application.mode == .Edit {
		editor_gui()
	}

	///////////////////////////////////////////////////////////////////////////
	// START OF GAME UPDATE
	// Todo(Leo): physics.tick()???? Maybe physics update can be done from here??
	if application.mode == .Game {

		physics.begin_frame(delta_time)


		// test collider
		physics.submit_colliders([]physics.BoxCollider{{{2, 4, 2}, quaternion(1), {2, 2, 1}}})

		// tank submits colliders that player needs to use, so that need to update first
		// Todo(Leo): maybe have a collider handle that is just updated or something, but this
		// works now, when things are not too complicated. Also there will be a need to think
		// about the order of execution
		update_tank(&tank, delta_time)
		update_player_character(&player_character, &camera, delta_time)
	} else if application.mode == .Edit {
		update_editor_camera(&camera, delta_time)
	}

	///////////////////////////////////////////////////////////////////////////
	// END OF UPDATE

	graphics.begin_frame()
	graphics.bind_main_framebuffer()

	debug_params := vec4{1 if draw_normals else 0, 0, 0, 0}

	light_direction := linalg.normalize(vec3{0, 0, -5})
	// light_direction := linalg.normalize(vec3{0, 5, -5})
	light_color := vec3{1.0, 0.95, 0.85} * 1.5
	ambient_color := vec3{0.3, 0.35, 0.4}

	projection_matrix, view_matrix := camera_get_projection_and_view_matrices(&camera)

	graphics.setup_basic_pipeline(
		projection_matrix, 
		view_matrix,
		light_direction,
		light_color,
		ambient_color,
		debug_params,
	)

	for sp in scene.set_pieces {
		graphics.set_basic_material(sp.color, sp.texture)
		model_matrix := linalg.matrix4_translate_f32(sp.position)
		graphics.draw_mesh(sp.mesh, model_matrix)
	}
	
	render_tank(&tank)

	// Player character as a capsule for debug purposes
	graphics.set_basic_material({0.6, 0.2, 0.4}, &white_texture)
	model_matrix := linalg.matrix4_translate_f32(player_character.physics_position + OBJECT_UP) *
					linalg.matrix4_scale_f32(2)
	graphics.draw_mesh(&capsule_mesh, model_matrix)

	// NEXT PIPELINE
	graphics.setup_terrain_pipeline(
		projection_matrix,
		view_matrix,
		light_direction,
		light_color,
		ambient_color,
		debug_params,
	)
	graphics.set_terrain_material(
		scene.terrain.grass_placement_map,
		scene.terrain.grass_field_texture,
		scene.terrain.road_texture,
	)
	for p, i in scene.terrain.positions {
		model_matrix := linalg.matrix4_translate_f32(p)
		graphics.draw_mesh(&scene.terrain.meshes[i], model_matrix)
	}

	// NEXT PIPELINE
	graphics.setup_debug_pipeline(projection_matrix, view_matrix)
	debug.render()

	// NEXT PIPELINE
	graphics.dispatch_grass_placement_pipeline(
		&scene.grass.instances, 
		scene.grass.placement_map,
		grass_blade_count,
	)

	// NEXT PIPELINE
	@static wind_time := f32 (0)
	@static wind_on := true
	@static wind_offset : vec2

	if wind_on {
		wind_time += delta_time
		wind_offset.x += delta_time * 0.08
		wind_offset.y += delta_time * 0.04
	}
	wind_amount := math.sin(wind_time) * 0.5

	if input.DEBUG_get_key_pressed(.U) {
		wind_on = !wind_on
	}

	graphics.setup_grass_pipeline(
		projection_matrix, 
		view_matrix,
		light_direction,
		light_color,
		ambient_color,
		wind_offset,
		debug_params,
		grass_cull_back,
	)
	graphics.set_grass_material(&scene.textures[.Grass_Field], &scene.textures[.Wind])
	graphics.draw_grass(&scene.grass.mesh, &scene.grass.instances, grass_blade_count*grass_blade_count)

	// NEXT PIPELINE
	graphics.blit_to_resolve_image()
	graphics.bind_screen_framebuffer()
	graphics.dispatch_post_process_pipeline(editor.exposure)

	// NEXT PIPELINE
	graphics.setup_gui_pipeline()
	gui.render()

	// End of pipelines
	graphics.render()

	// Need to always call window.XXX_frame(), then input.XXX_frame
	// Todo(Leo): maybe combine, or move to main.odin
	window.end_frame()
	input.end_frame()
}

// This is a mockup, really probably each component (e.g. playback) should have
// their corresponding parts there. Not sure though. 
editor_gui :: proc() {
	ctx := gui.get_mu_context()

	// Careful! Window means here both application window and the gui window inside the application!
	GUI_WINDOW_OUTER_PADDING 	:: 25

	FULL_CONTENT_WIDTH :: 260
	content_width := FULL_CONTENT_WIDTH - ctx.style.indent

	label_column_width 			:= i32(0.35 * f32(content_width))
	element_column_width 		:= content_width - label_column_width - ctx.style.spacing
	label_and_element_layout 	:= []i32 { label_column_width, element_column_width}

	two_elements_column_width 		:= i32(0.5 * f32(element_column_width)) - i32(math.ceil(f32(ctx.style.spacing) / 2))
	label_and_two_elements_layout 	:= []i32 {label_column_width, two_elements_column_width, two_elements_column_width}

	single_element_layout := []i32 {content_width}
	
	equal_column_width 		:= i32(0.5 * f32(content_width)) - i32(math.ceil(f32(ctx.style.spacing) / 2))
	two_elements_layout 	:= []i32{equal_column_width, equal_column_width}

	_, window_height := window.get_window_size()
	rectangle 	:= mu.Rect{
						GUI_WINDOW_OUTER_PADDING, 
						GUI_WINDOW_OUTER_PADDING,
						FULL_CONTENT_WIDTH + 2*ctx.style.padding,
						// Very arbitrary value for now
						500,
					} 

	if mu.window(ctx, "Controls and Settings", rectangle, {.NO_CLOSE, .NO_RESIZE}) {
		if .ACTIVE in mu.header(ctx, "Scenes", {.EXPANDED}) {
			gui.indent(ctx)

			mu.label(ctx, "Load scene")
			for name in SceneName {
				if .SUBMIT in mu.button(ctx, reflect.enum_string(name)) {
					unload_scene(scene)
					scene = load_scene(name)
					editor.loaded_scene_name = name
				}
			}

			gui.unindent(ctx)
		}

		if .ACTIVE in mu.header(ctx, "Remember texture buttons", {.EXPANDED}) {
			gui.indent(ctx)
			
			mu.layout_row(ctx, label_and_two_elements_layout)
			mu.label(ctx, "Buttons")
			if .SUBMIT in gui.texture_button(ctx, "", scene.textures[.Grass_Field]) { }
			if .SUBMIT in gui.texture_button(ctx, "", scene.textures[.Road]) { }


			gui.unindent(ctx)
		}
		
		if .ACTIVE in mu.header(ctx, "Grass!", {.EXPANDED}) {
			gui.indent(ctx)
			
			mu.layout_row(ctx, two_elements_layout)
			if .SUBMIT in mu.button(ctx, "64") { grass_blade_count = 64 }
			if .SUBMIT in mu.button(ctx, "128") { grass_blade_count = 128 }
			if .SUBMIT in mu.button(ctx, "256") { grass_blade_count = 256 }
			if .SUBMIT in mu.button(ctx, "512") { grass_blade_count = 512 }
			
			gui.unindent(ctx)
		}

		if .ACTIVE in mu.header(ctx, "Post Processing", {.EXPANDED}) {
			gui.indent(ctx)

			mu.layout_row(ctx, label_and_element_layout)
			mu.label(ctx, "Exposure")
			mu.slider(ctx, &editor.exposure, 0, 3)

			mu.layout_row(ctx, single_element_layout)
			mu.checkbox(ctx, "Draw Normals", &draw_normals)
			mu.checkbox(ctx, "Grass Cull Back", &grass_cull_back)

			gui.unindent(ctx)
		}
	}
}