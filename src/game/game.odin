package game

/*
The actual core application main file. Initialize, terminate and
update all systems from this file
*/

import "shrubs:assets"
import "shrubs:common"
import "shrubs:debug"
import "shrubs:graphics"
import "shrubs:imgui"
import "shrubs:input"
import "shrubs:physics"
import "shrubs:window"

import "core:fmt"
import "core:intrinsics"
import "core:math"
import "core:math/linalg"
import "core:reflect"

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
grass_types : GrassTypes
grass_system : Grass

grass_blade_count := 32
grass_segment_count := 3

lod_enabled := 0
draw_normals := false
draw_backfacing := false
draw_lod := false
grass_cull_back := false

grass_chunk_size := f32(5)

grass_type_to_edit : GrassType

// Resources
white_texture 	: graphics.Texture
black_texture 	: graphics.Texture
DEBUG_rock_texture : graphics.Texture
capsule_mesh 	: graphics.Mesh
cube_mesh 		: graphics.Mesh

application : struct {
	wants_to_quit 	: bool,
	mode 			: enum { Game, Edit },
}

show_imgui_demo := false
show_timings := true
timings : struct {
	frame_time : SmoothValue,
}

test_position : vec3

initialize :: proc() {
	// Todo(Leo): some of this stuff seems to bee "application" or "engine" and not "game"
	window.initialize(WINDOW_WIDTH, WINDOW_HEIGHT, APPLICATION_NAME)
	input.initialize()
	graphics.initialize()
	imgui.initialize(window.get_glfw_window_handle())
	debug.initialize(256)
	physics.initialize()

	// Common resources
	white_texture = graphics.create_color_texture(
		1, 1, []common.Color_u8_rgba{{255, 255, 255, 255}}, .Nearest,
	)

	black_texture = graphics.create_color_texture(
		1, 1, []common.Color_u8_rgba{{0, 0, 0, 255}}, .Nearest,
	)
	DEBUG_rock_texture = TEMP_load_color_texture("assets/rock_01_diff_4k.jpg")


	capsule_mesh = TEMP_load_mesh_gltf("assets/shapes.glb", "shape_capsule")
	cube_mesh = TEMP_load_mesh_gltf("assets/shapes.glb", "shape_cube")

	// Scene independent systems
	camera 				= create_camera()
	tank 				= create_tank()
	player_character 	= create_player_character()

	// Application is started in edit mode
	application.mode = .Edit

	// Todo(Leo): Not sure how to categorize this yet?
	grass_types = create_grass_types()
	load_grass_types(&grass_types)
	grass_system = create_grass()

	// Scene
	if IS_ACTUALLY_EDITOR {
		load_editor_state()
		scene = load_scene(editor.loaded_scene_name)
	}

}

terminate :: proc() {
	destroy_grass(&grass_system)
	save_grass_types(&grass_types)
	destroy_grass_types(&grass_types)

	save_editor_state()

	// Todo(Leo): not really necessary at this point, but I keep these here
	// to remeber that destroying stuff is at times actually necessary.
	unload_scene(scene)

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

	@static wind_time := f32 (0)
	@static wind_on := true
	@static wind_offset : vec2

	if wind_on {
		wind_time += delta_time
		wind_offset.x += delta_time * 0.06
		wind_offset.y += delta_time * 0.03
	}
	wind_amount := math.sin(wind_time) * 0.5

	if input.DEBUG_get_key_pressed(.U) {
		wind_on = !wind_on
	}

	// END OF UPDATE
	///////////////////////////////////////////////////////////////////////////

	///////////////////////////////////////////////////////////////////////////
	// GUI


	// Todo(Leo): these are from last frame, does it matter? Probably not much, as
	// typically we are not operating camera and gizmo in the same frame
	{
		projection, view := camera_get_projection_and_view_matrices(&camera)

		imgui.begin_frame(projection, view)
		if show_imgui_demo {
			imgui.ShowDemoWindow()
		}		
	}


	imgui.SetNextWindowPos({10, 10})
	imgui.SetNextWindowSize({300, 0})
	next_window_Y := f32(10)
	if show_timings {
		if imgui.Begin("Timings") {
			if imgui.BeginTable("time table", 2) {

				imgui.TableNextRow()
				imgui.TableNextColumn()
				imgui.text("frame time")
				imgui.TableNextColumn()
				imgui.text("{:5.2f} ms (fps {})", timings.frame_time.value * 1000, int(1 / timings.frame_time.value))

				imgui.EndTable()
			}
		}
		next_window_Y = 10 + imgui.GetWindowHeight() + 10
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

	///////////////////////////////////////////////////////////////////////////
	// Rendering

	graphics.begin_frame()
	graphics.bind_main_framebuffer()

	light_direction := matrix4_mul_vector(
						linalg.matrix4_rotate_f32(scene.lighting.direction_polar.x * math.PI / 180, OBJECT_UP) *
						linalg.matrix4_rotate_f32(scene.lighting.direction_polar.y * math.PI / 180, OBJECT_RIGHT),
						OBJECT_FORWARD)
	light_color := scene.lighting.directional_color.rgb * scene.lighting.directional_color.w
	ambient_color := scene.lighting.ambient_color.rgb * scene.lighting.ambient_color.w

	projection_matrix, view_matrix := camera_get_projection_and_view_matrices(&camera)

	graphics.set_per_frame_data(view_matrix, projection_matrix)
	graphics.set_lighting_data(camera.position, light_direction, light_color, ambient_color)
	graphics.set_wind_data(wind_offset, 0.005, &scene.textures[.Wind])
	graphics.set_debug_data(draw_normals, draw_backfacing, draw_lod)

	graphics.setup_basic_pipeline()

	for sp in scene.set_pieces {
		graphics.set_basic_material(sp.color, sp.texture)
		model_matrix := linalg.matrix4_translate_f32(sp.position)
		graphics.draw_mesh(sp.mesh, model_matrix)
	}
	
	render_tank(&tank)
	render_greyboxing(&scene.greyboxing)

	// Player character as a capsule for debug purposes
	graphics.set_basic_material({0.6, 0.2, 0.4}, &white_texture)
	model_matrix := linalg.matrix4_translate_f32(player_character.physics_position + OBJECT_UP) *
					linalg.matrix4_scale_f32(2)
	graphics.draw_mesh(&capsule_mesh, model_matrix)

	// compute grass lods
	grass_lods 			: [100]int
	lod_segment_counts 	: [100]int
	lod_instance_counts : [100]int
	lod_check_position 	:= player_character.physics_position
	for lod, i in &grass_lods {
		chunk_center := grass_system.positions[i] + vec2(2.5)

		to_player := lod_check_position.xy - chunk_center
		distance_to_player := linalg.length(to_player) 
	
		if lod_enabled == -1 {
			switch {
				case distance_to_player < 7.5: lod = 0
				case distance_to_player < 15: lod = 1
				case: lod = 2
			}
		} else {
			lod = lod_enabled
		}

		lod_instance_counts[i] = grass_lod_settings[lod].instance_count
		lod_segment_counts[i] = grass_lod_settings[lod].segment_count
	}

	// NEXT PIPELINE
	graphics.setup_debug_pipeline()
	debug.render()

	// NEXT PIPELINE
	graphics.setup_terrain_pipeline()
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
	// This is bound both for the grass placement and grass rendering
	graphics.bind_uniform_buffer(&grass_types.types_buffer, graphics.GRASS_TYPES_BUFFER_BINDING)
	
	for i in 0..<len(grass_system.instance_buffers) {
		graphics.dispatch_grass_placement_pipeline(
			&grass_system.instance_buffers[i], 
			grass_system.placement_map,
			lod_instance_counts[i],
			grass_system.positions[i],
			grass_chunk_size,
			int(scene.name),
		)
	}

	// NEXT PIPELINE
	graphics.setup_grass_pipeline(grass_cull_back)
	for i in 0..<len(grass_system.instance_buffers) {
		graphics.draw_grass(
			grass_system.renderers[i],
			lod_instance_counts[i] * lod_instance_counts[i],
			lod_segment_counts[i],
			grass_lods[i],
		)
	}

	// NEXT PIPELINE
	graphics.draw_sky()

	// NEXT PIPELINE
	graphics.blit_to_resolve_image()
	graphics.bind_screen_framebuffer()
	graphics.dispatch_post_process_pipeline(scene.lighting.exposure)

	// NEXT PIPELINE
	imgui.render()

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

	// Careful! Window means here both application window and the gui window inside the application!
	// GUI_WINDOW_OUTER_PADDING 	:: 25

	// FULL_CONTENT_WIDTH :: 260
	// content_width := FULL_CONTENT_WIDTH - ctx.style.indent

	// label_column_width 			:= i32(0.35 * f32(content_width))
	// element_column_width 		:= content_width - label_column_width - ctx.style.spacing
	// label_and_element_layout 	:= []i32 { label_column_width, element_column_width}

	// two_elements_column_width 		:= i32(0.5 * f32(element_column_width)) - i32(math.ceil(f32(ctx.style.spacing) / 2))
	// label_and_two_elements_layout 	:= []i32 {label_column_width, two_elements_column_width, two_elements_column_width}

	// single_element_layout := []i32 {content_width}
	
	// two_columns_width 		:= i32(0.5 * f32(content_width)) - i32(math.ceil(f32(ctx.style.spacing) / 2))
	// two_left_over			:= content_width - (2 * two_columns_width + 1 * ctx.style.spacing)
	// two_elements_layout 	:= []i32{two_columns_width, two_columns_width + two_left_over}

	// three_columns_width 	:= i32(0.333 * f32(content_width)) - i32(math.ceil(0.667 * f32(ctx.style.spacing)))
	// three_left_over			:= content_width - (3 * three_columns_width + 2 * ctx.style.spacing)
	// three_columns_layout 	:= []i32{three_columns_width, three_columns_width, three_columns_width + three_left_over}

	// four_columns_width 		:= i32(0.25 * f32(content_width)) - i32(math.ceil(0.75 * f32(ctx.style.spacing)))
	// four_left_over			:= content_width - (4 * four_columns_width + 3 * ctx.style.spacing)
	// four_columns_layout		:= []i32{four_columns_width, four_columns_width, four_columns_width, four_columns_width + four_left_over}


	_, window_height := window.get_window_size()
	// rectangle 	:= mu.Rect{
	// 					GUI_WINDOW_OUTER_PADDING, 
	// 					GUI_WINDOW_OUTER_PADDING,
	// 					FULL_CONTENT_WIDTH + 2*ctx.style.padding,
	// 					// Very arbitrary value for now
	// 					900,
	// 				} 
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

		if imgui.CollapsingHeader("Scenes") {
			if imgui.Button("Save Current Scene") {
				save_scene(scene)
			}

			imgui.text("Load scene")
			for name in SceneName {
				if imgui.button(reflect.enum_string(name)) {
					unload_scene(scene)
					scene = load_scene(name)
					editor.loaded_scene_name = name
				}
			}
		}

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

			imgui.enum_dropdown("Edit type", &grass_type_to_edit)
			settings := &grass_types.settings[grass_type_to_edit]

			imgui.text("LOD")
			if imgui.button("auto") { lod_enabled = -1 }; imgui.SameLine() 
			if imgui.button("0") { lod_enabled = 0 }; imgui.SameLine() 
			if imgui.button("1") { lod_enabled = 1 }; imgui.SameLine() 
			if imgui.button("2") { lod_enabled = 2 };


			imgui.text("Blade");
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
			imgui.checkbox("Show Imgui Demo", &show_imgui_demo)

			imgui.checkbox("Draw Normals", &draw_normals)
			imgui.checkbox("Draw Backfacing", &draw_backfacing)
			imgui.checkbox("Draw LOD", &draw_lod)
			imgui.checkbox("Grass Cull Back", &grass_cull_back)
		}
	}
	imgui.End()

	
}