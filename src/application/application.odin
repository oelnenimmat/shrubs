package application

/*
The actual core application main file. Initialize, terminate and
update all systems from this file
*/

import "../common"
import "../window"
import "../graphics"
import "../input"
import "../gui"
import "../assets"

import "core:math"
import "core:math/linalg"
import mu "vendor:microui"

vec2 		:: common.vec2
vec3 		:: common.vec3
vec4 		:: common.vec4
dvec3 		:: common.dvec3
mat4 		:: common.mat4
quaternion 	:: common.quaternion

WINDOW_WIDTH :: 960
WINDOW_HEIGHT :: 540

APPLICATION_NAME :: "Shrubs"

camera 			: Camera

test_mesh 		: graphics.Mesh
terrain_meshes 	: []graphics.Mesh
pillar_mesh 	: graphics.Mesh
grass_mesh 		: graphics.Mesh

grass_instances : graphics.InstanceBuffer
grass_field_texture : graphics.Texture

white_texture : graphics.Texture

terrain_positions := []vec3 {
	{-15, -15, 0},
	{-5, -15, 0},
	{5, -15, 0},

	{-15, -5, 0},
	{-5, -5, 0},
	{5, -5, 0},
	
	{-15, 5, 0},
	{-5, 5, 0},
	{5, 5, 0},
}

application : struct {
	wants_to_quit : bool,
}

initialize :: proc() {
	window.initialize(WINDOW_WIDTH, WINDOW_HEIGHT, APPLICATION_NAME)
	input.initialize()
	graphics.initialize()	
	gui.initialize()

	camera = create_camera()

	{
		positions, normals, elements := assets.NOT_MEMORY_SAFE_gltf_load_node("assets/shrubs.glb", "mock_coordinate_pillar")
		pillar_mesh = graphics.create_mesh(positions, normals, nil, elements)

		delete(positions)
		delete(normals)
		delete(elements)
	}

	{
		positions, normals, elements := assets.NOT_MEMORY_SAFE_gltf_load_node("assets/shrubs.glb", "mock_shrub")
		test_mesh = graphics.create_mesh(positions, normals, nil, elements)

		delete(positions)
		delete(normals)
		delete(elements)
	}

	// Todo(Leo): allocator!!!!!
	terrain_meshes = make([]graphics.Mesh, 9)
	for i in 0..<9 {
		terrain_meshes[i] = create_static_terrain_mesh(terrain_positions[i].xy)
	}

	grass_mesh = create_grass_blade_mesh()

	grass_instances = generate_grass_positions({-10, -10, 0}, {10, 10, 0}, 200)

	// grass_field_image := assets.load_color_image("assets/cgshare-book-grass-01.jpg")
	grass_field_image := assets.load_color_image("assets/callum_andrews_ghibli_grass.png")
	defer assets.free_loaded_color_image(&grass_field_image)
	grass_field_texture = graphics.create_color_texture(
		grass_field_image.width,
		grass_field_image.height,
		grass_field_image.pixels,
	)

	white_texture = graphics.create_color_texture(1, 1, []common.Color_u8_rgba{{255, 255, 255, 255}})
}

terminate :: proc() {
	delete (terrain_meshes)

	gui.terminate()
	graphics.terminate()
	input.terminate()
	window.terminate()
}

does_want_to_quit :: proc() -> bool {
	return window.should_close() || application.wants_to_quit
}

update :: proc(delta_time: f64) {

	// note(Leo): in main we have delta time as f64, but for the most part
	// we now use f32 for rendering reasons, so it is more straightforward
	// to just use f32 everywhere here
	delta_time := f32(delta_time)

	window.begin_frame()
	input.update()
	gui.begin_frame()

	// Some events are fired from here, needs to be done before updates
	// Todo(Leo): This is a little spaghetti now, as we fire events in
	// input package to control values in application package (where this
	// is and should be too) so get rid of that extra path. See e.g. 
	// visuals_set_gradient 
	// MOCKUP_do_gui(&gui.gui_state.mu_ctx)

	update_camera(&camera, delta_time)

	if input.events.application.exit {
		application.wants_to_quit = true
	}

	// Events can only be used before this. This is as intended.
	input.reset_events()

	graphics.begin_frame()

	light_direction := linalg.normalize(vec3{1, 2, -10})
	light_color := vec3{1.0, 0.95, 0.85}
	ambient_color := vec3{0.3, 0.35, 0.4} * 3
	graphics.set_lighting(light_direction, light_color, ambient_color)

	graphics.set_cull(.On)
	graphics.set_surface({0.5, 0.5, 0.6})
	graphics.use_texture(white_texture)
	graphics.draw_mesh(&pillar_mesh, mat4(1))

	shrub_positions := []vec3{
		{3, 0, 0},
		{2.8, 1, 0},
		{0, 2, 0},
		{1, 3, 0},
	}
	graphics.set_surface({0.4, 0.35, 0.35})
	graphics.use_texture(white_texture)
	for p in shrub_positions {
		model_matrix := linalg.matrix4_translate_f32(p)
		graphics.draw_mesh(&test_mesh, model_matrix)
	}


	graphics.set_surface({0.15, 0.2, 0.05})
	graphics.use_texture(grass_field_texture)
	for p, i in terrain_positions {
		model_matrix := linalg.matrix4_translate_f32(p)
		graphics.draw_mesh(&terrain_meshes[i], model_matrix)
	}

	@static wind_time := f32 (0)
	wind_time += delta_time
	wind_amount := math.sin(wind_time) * 0.2

	graphics.set_cull(.Off)
	graphics.set_surface({0.2, 0.4, 0.1})
	graphics.set_wind({0, 1, 0}, wind_amount)
	graphics.use_texture(grass_field_texture)
	graphics.draw_mesh_instanced(&grass_mesh, &grass_instances)

	// gui.render()
	graphics.render()
	window.end_frame()
}

/*
// This is a mockup, really probably each component (e.g. playback) should have
// their corresponding parts there. Not sure though. 
MOCKUP_do_gui :: proc(ctx: ^mu.Context) {
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
			if .SUBMIT in mu.button(ctx, "Play") { playback_resume(&snapshot_interpolation) }
			if .SUBMIT in mu.button(ctx, "Pause") { playback_pause(&snapshot_interpolation) }


			// PLAYBACK SPEED
			// Compute and string format playback speed.
			// Todo(Leo): no need to make and destroy this every frame, just store somewhere, reset and reuse.
			// Also consider expressing in days/s for smaller values or smth. Also make extra sure that this
			// is fine as the defer will fire long before than the text is used (i.e. rendered).
			playback_speed_text_builder 		:= strings.builder_make_len(32)
			defer strings.builder_destroy(&playback_speed_text_builder)
			playback_speed_years_per_second 	:= settings.playback_time_scale / 3600 / 24 / 365.4
			fmt.sbprintf(&playback_speed_text_builder, "Playback speed: {:.3f} yr / s", playback_speed_years_per_second)

			mu.label(ctx, strings.to_string(playback_speed_text_builder))

			mu.layout_row(ctx, two_elements_layout)
			if .SUBMIT in mu.button(ctx, "Slower") { input.events.playback.slow_down = true }
			if .SUBMIT in mu.button(ctx, "Faster") { input.events.playback.speed_up = true }

			// SNAPSHOT
			mu.layout_row(ctx, single_element_layout) 
			snapshot_text_builder 	:= strings.builder_make_len(32)
			defer strings.builder_destroy(&snapshot_text_builder)
			current_snapshot_index 	:= playback_get_current_snapshot_index(&snapshot_interpolation) + 1
			snapshot_count 			:= playback_get_snapshot_count(&snapshot_interpolation)
			fmt.sbprintf(&snapshot_text_builder, "Snapshots {} to {} (of {})", current_snapshot_index, current_snapshot_index + 1, snapshot_count)
			mu.label(ctx, strings.to_string(snapshot_text_builder))


			mu.layout_row(ctx, two_elements_layout)
			if .SUBMIT in mu.button(ctx, "First") { input.events.playback.reset = true }
			//if .SUBMIT in mu.button(ctx, "Previous") { input.events.playback.skip_to_previous = true }
			if .SUBMIT in mu.button(ctx, "Next") { input.events.playback.skip_to_next = true }
			
			// _val := math.log(settings.playback_time_scale, 10)
			// mu.slider(ctx, &_val, lo, hi, step, "%.1f", {.ALIGN_CENTER})
			// settings.playback_time_scale = math.pow(10, _val)

			mu.layout_row(ctx, label_and_two_elements_layout)
			mu.label(ctx, "Distances")
			if .SUBMIT in mu.button(ctx, "Closer") { visuals_trigger_event(&snapshot_interpolation, .Smaller_Distance)}
			if .SUBMIT in mu.button(ctx, "Farther") { visuals_trigger_event(&snapshot_interpolation, .Bigger_Distance)}

			// Todo(Leo): these are not implemented yet on the other side, requires changes to graphics
			// mu.label(ctx, "Sizes")
			// if .SUBMIT in mu.button(ctx, "Smaller") { visuals_trigger_event(&snapshot_interpolation, .Smaller_Size)}
			// if .SUBMIT in mu.button(ctx, "Bigger") { visuals_trigger_event(&snapshot_interpolation, .Bigger_Size)}



			mu.layout_row(ctx, single_element_layout) 
			info_text_builder := strings.builder_make_len(256)
			defer strings.builder_destroy(&info_text_builder)
			particle_count := playback_get_test_particle_count(&snapshot_interpolation)
			fmt.sbprintf(&info_text_builder, "INFO:\n")
			fmt.sbprintf(&info_text_builder, "Test particle count: {}\n", particle_count)
			mu.text(ctx, strings.to_string(info_text_builder))

			gui.unindent(ctx)
		}
		

		// mu.layout_row(ctx, {content_width})
		if .ACTIVE in mu.header(ctx, "Particle Visual Settings", {.EXPANDED})
		{
			gui.indent(ctx)

			mu.layout_row(ctx, label_and_element_layout)
	
			mu.label(ctx, "Data Channel")
			DATA_CHANNEL_POPUP_NAME :: "data channel popup"
			if .SUBMIT in mu.button(ctx, reflect.enum_string(snapshot_interpolation.data_channel_type)) {
				mu.open_popup(ctx, DATA_CHANNEL_POPUP_NAME)
			}

			if mu.begin_popup(ctx, DATA_CHANNEL_POPUP_NAME) {
				for type in DataChannelType {
					if .SUBMIT in mu.button(ctx, reflect.enum_string(type)) {
						visuals_set_data_channel(&snapshot_interpolation, type)
						mu.get_current_container(ctx).open = false
					}
				}
				mu.end_popup(ctx)
			}

			mu.label(ctx, "Coloring")
			GRADIENT_POPUP_NAME :: "gradient popup"
			if .SUBMIT in gui.texture_button(ctx, "", assets.gradient_textures[snapshot_interpolation.gradient_index]) {
				mu.open_popup(ctx, GRADIENT_POPUP_NAME)
			}

			if mu.begin_popup(ctx, GRADIENT_POPUP_NAME) {
				for i in 0..<len(assets.gradient_textures) {
					if .SUBMIT in gui.texture_button(ctx, "", assets.gradient_textures[i]) {
						visuals_set_gradient(&snapshot_interpolation, i)
						mu.get_current_container(ctx).open = false
					} 
				}
				mu.end_popup(ctx)
			}

			gui.unindent(ctx)
		}

		if .ACTIVE in mu.header(ctx, "Developer") //, {.EXPANDED})
		{
			gui.indent(ctx)
			
			mu.layout_row(ctx, single_element_layout) 
			if .SUBMIT in mu.button(ctx, "camera preset 1") { camera_set_preset(&camera, 1) }
			if .SUBMIT in mu.button(ctx, "camera preset 2") { camera_set_preset(&camera, 2) }
			if .SUBMIT in mu.button(ctx, "camera preset 3") { camera_set_preset(&camera, 3) }
			if .SUBMIT in mu.button(ctx, "camera preset p12 side") { camera_set_preset(&camera, 4) }

			if .SUBMIT in mu.button(ctx, "print camera position") { input.events.debug.print_camera_position = true }
			
			gui.unindent(ctx)
		}
	}
}
*/