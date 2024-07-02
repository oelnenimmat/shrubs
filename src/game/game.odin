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

scene : Scene

// Resources
white_texture 		: graphics.Texture

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

	// Application is started in game mode
	application.mode = .Game
	input.lock_mouse(true)

	// Common assets
	white_texture = graphics.create_color_texture(
		1, 1, []common.Color_u8_rgba{{255, 255, 255, 255}}, .Nearest,
	)

	// Scene independent systems
	camera 				= create_camera()
	tank 				= create_tank()
	player_character 	= create_player_character()

	// Scene
	load_scene(&scene)

}

terminate :: proc() {
	// Todo(Leo): not really necessary at this point, but I keep these here
	// to remeber that destroying stuff is at times actually necessary.
	unload_scene(&scene)

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
		input.lock_mouse(application.mode == .Game)
	}

	if application.mode == .Edit {
		MOCKUP_do_gui()
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
	}

	///////////////////////////////////////////////////////////////////////////
	// END OF UPDATE

	graphics.begin_frame()

	light_direction := linalg.normalize(vec3{1, 2, -10})
	light_color := vec3{1.0, 0.95, 0.85}
	ambient_color := vec3{0.3, 0.35, 0.4} * 3

	projection_matrix, view_matrix := camera_get_projection_and_view_matrices(&camera)

	graphics.setup_basic_pipeline(
		projection_matrix, 
		view_matrix,
		light_direction,
		light_color,
		ambient_color,
	)

	for sp in scene.set_pieces {
		graphics.set_basic_material(sp.color, sp.texture)
		model_matrix := linalg.matrix4_translate_f32(sp.position)
		graphics.draw_mesh(sp.mesh, model_matrix)
	}

	graphics.set_basic_material({0.4, 0.4, 0.4}, &scene.grass_field_texture)
	for p, i in scene.terrain.positions {
		model_matrix := linalg.matrix4_translate_f32(p)
		graphics.draw_mesh(&scene.terrain.meshes[i], model_matrix)
	}

	render_tank(&tank)

	// NEXT PIPELINE
	graphics.setup_debug_pipeline(projection_matrix, view_matrix)
	debug.render()


	// NEXT PIPELINE
	@static wind_time := f32 (0)
	wind_time += delta_time
	wind_amount := math.sin(wind_time) * 0.2

	graphics.setup_grass_pipeline(
		projection_matrix, 
		view_matrix,
		light_direction,
		light_color,
		ambient_color,
		{0, 1, 0}, wind_amount
	)
	graphics.set_grass_material(&scene.grass_field_texture)
	graphics.draw_mesh_instanced(&scene.grass.mesh, &scene.grass.instances)

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
MOCKUP_do_gui :: proc() {
	ctx := gui.get_mu_context()

	// val  : f32 =  1e6
	// DEBUG limits
	lo   : f32 :  1.0
	hi   : f32 :  10
	step : f32 :  0.0

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
		if .ACTIVE in mu.header(ctx, "Playback", {.EXPANDED}) {
			gui.indent(ctx)
			
			// PLAY / PAUSE
			mu.layout_row(ctx, two_elements_layout) 
			if .SUBMIT in mu.button(ctx, "Play") {  }
			if .SUBMIT in mu.button(ctx, "Pause") {  }


			// PLAYBACK SPEED
			// Compute and string format playback speed.
			// Todo(Leo): no need to make and destroy this every frame, just store somewhere, reset and reuse.
			// Also consider expressing in days/s for smaller values or smth. Also make extra sure that this
			// is fine as the defer will fire long before than the text is used (i.e. rendered).
			// playback_speed_text_builder 		:= strings.builder_make_len(32)
			// defer strings.builder_destroy(&playback_speed_text_builder)
			// playback_speed_years_per_second 	:= settings.playback_time_scale / 3600 / 24 / 365.4
			// fmt.sbprintf(&playback_speed_text_builder, "Playback speed: {:.3f} yr / s", playback_speed_years_per_second)

			// mu.label(ctx, strings.to_string(playback_speed_text_builder))

			mu.layout_row(ctx, two_elements_layout)
			if .SUBMIT in mu.button(ctx, "Slower") {  }
			if .SUBMIT in mu.button(ctx, "Faster") {  }

			// SNAPSHOT
			// mu.layout_row(ctx, single_element_layout) 
			// snapshot_text_builder 	:= strings.builder_make_len(32)
			// defer strings.builder_destroy(&snapshot_text_builder)
			// current_snapshot_index 	:= playback_get_current_snapshot_index(&snapshot_interpolation) + 1
			// snapshot_count 			:= playback_get_snapshot_count(&snapshot_interpolation)
			// fmt.sbprintf(&snapshot_text_builder, "Snapshots {} to {} (of {})", current_snapshot_index, current_snapshot_index + 1, snapshot_count)
			// mu.label(ctx, strings.to_string(snapshot_text_builder))


			mu.layout_row(ctx, two_elements_layout)
			if .SUBMIT in mu.button(ctx, "First") {  }
			//if .SUBMIT in mu.button(ctx, "Previous") { input.events.playback.skip_to_previous = true }
			if .SUBMIT in mu.button(ctx, "Next") {  }
			
			// _val := math.log(settings.playback_time_scale, 10)
			// mu.slider(ctx, &_val, lo, hi, step, "%.1f", {.ALIGN_CENTER})
			// settings.playback_time_scale = math.pow(10, _val)

			mu.layout_row(ctx, label_and_two_elements_layout)
			mu.label(ctx, "Distances")
			if .SUBMIT in gui.texture_button(ctx, "", scene.grass_field_texture) { }
			if .SUBMIT in gui.texture_button(ctx, "", scene.grass_field_texture) { }

			// Todo(Leo): these are not implemented yet on the other side, requires changes to graphics
			// mu.label(ctx, "Sizes")
			// if .SUBMIT in mu.button(ctx, "Smaller") { visuals_trigger_event(&snapshot_interpolation, .Smaller_Size)}
			// if .SUBMIT in mu.button(ctx, "Bigger") { visuals_trigger_event(&snapshot_interpolation, .Bigger_Size)}



			// mu.layout_row(ctx, single_element_layout) 
			// info_text_builder := strings.builder_make_len(256)
			// defer strings.builder_destroy(&info_text_builder)
			// particle_count := playback_get_test_particle_count(&snapshot_interpolation)
			// fmt.sbprintf(&info_text_builder, "INFO:\n")
			// fmt.sbprintf(&info_text_builder, "Test particle count: {}\n", particle_count)
			// mu.text(ctx, strings.to_string(info_text_builder))

			gui.unindent(ctx)
		}
		

		// mu.layout_row(ctx, {content_width})
		// if .ACTIVE in mu.header(ctx, "Particle Visual Settings", {.EXPANDED})
		// {
		// 	gui.indent(ctx)

		// 	mu.layout_row(ctx, label_and_element_layout)
	
		// 	mu.label(ctx, "Data Channel")
		// 	DATA_CHANNEL_POPUP_NAME :: "data channel popup"
		// 	if .SUBMIT in mu.button(ctx, reflect.enum_string(snapshot_interpolation.data_channel_type)) {
		// 		mu.open_popup(ctx, DATA_CHANNEL_POPUP_NAME)
		// 	}

		// 	if mu.begin_popup(ctx, DATA_CHANNEL_POPUP_NAME) {
		// 		for type in DataChannelType {
		// 			if .SUBMIT in mu.button(ctx, reflect.enum_string(type)) {
		// 				visuals_set_data_channel(&snapshot_interpolation, type)
		// 				mu.get_current_container(ctx).open = false
		// 			}
		// 		}
		// 		mu.end_popup(ctx)
		// 	}

		// 	mu.label(ctx, "Coloring")
		// 	GRADIENT_POPUP_NAME :: "gradient popup"
		// 	if .SUBMIT in gui.texture_button(ctx, "", assets.gradient_textures[snapshot_interpolation.gradient_index]) {
		// 		mu.open_popup(ctx, GRADIENT_POPUP_NAME)
		// 	}

		// 	if mu.begin_popup(ctx, GRADIENT_POPUP_NAME) {
		// 		for i in 0..<len(assets.gradient_textures) {
		// 			if .SUBMIT in gui.texture_button(ctx, "", assets.gradient_textures[i]) {
		// 				visuals_set_gradient(&snapshot_interpolation, i)
		// 				mu.get_current_container(ctx).open = false
		// 			} 
		// 		}
		// 		mu.end_popup(ctx)
		// 	}

		// 	gui.unindent(ctx)
		// }

		if .ACTIVE in mu.header(ctx, "Developer") //, {.EXPANDED})
		{
			gui.indent(ctx)
			
			mu.layout_row(ctx, single_element_layout) 
			if .SUBMIT in mu.button(ctx, "camera preset 1") {  }
			if .SUBMIT in mu.button(ctx, "camera preset 2") {  }
			if .SUBMIT in mu.button(ctx, "camera preset 3") {  }
			if .SUBMIT in mu.button(ctx, "camera preset p12 side") {  }

			if .SUBMIT in mu.button(ctx, "print camera position") {  }
			
			gui.unindent(ctx)
		}
	}
}