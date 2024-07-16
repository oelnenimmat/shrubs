package graphics

PER_FRAME_BUFFER_BINDING 	:: 0
LIGHTING_BUFFER_BINDING 	:: 1
WIND_BUFFER_BINDING 		:: 2
WORLD_BUFFER_BINDING 		:: 3

DEBUG_BUFFER_BINDING 		:: 20

GRASS_TYPES_BUFFER_BINDING 		:: 10
GRASS_INSTANCE_BUFFER_BINDING 	:: 11

// Shared
set_per_frame_data :: proc(view, projection : mat4) {}
set_lighting_data :: proc(camera_position, directional_direction, directional_color, ambient_color : vec3) {}
set_wind_data :: proc(texture_offset : vec2, texture_scale : f32, texture : ^Texture) {}
set_world_data :: proc(scale, offset : vec2) {}
set_debug_data :: proc(draw_normals, draw_backfacing, draw_lod : bool) {}

// Others
setup_basic_pipeline :: proc () {}
set_basic_material :: proc(color : vec3, texture : ^Texture) {}

setup_debug_pipeline :: proc () {}
draw_debug_mesh :: proc(mesh : ^Mesh, model : mat4, color : vec3) {}

setup_emissive_pipeline :: proc() {}
set_emissive_material :: proc(texture : ^Texture) {}

setup_grass_pipeline :: proc(cull_back : bool) {}
GrassRenderer :: struct {}
create_grass_renderer :: proc(instance_buffer : ^Buffer) -> GrassRenderer {
	return {}
}
destroy_grass_renderer :: proc(gr : ^GrassRenderer) {}
draw_grass :: proc(gr : GrassRenderer, instance_count : int, segment_count : int, lod : int) {}

dispatch_grass_placement_pipeline :: proc (
	instances 				: ^Buffer,
	placement_texture 		: ^Texture,
	blade_count 			: int,
	chunk_position 			: vec2,
	chunk_size 				: f32,
	type_index				: int,
	noise_params 			: vec4,
) {}

dispatch_post_process_pipeline :: proc(render_target : ^RenderTarget, exposure : f32) {}

draw_sky :: proc() {}

setup_terrain_pipeline :: proc () {}
set_terrain_material :: proc(
	splatter_texture : ^Texture,
	grass_texture : ^Texture,
	road_texture : ^Texture,
) {}