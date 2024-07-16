package graphics

import "shrubs:common"

vec2 :: common.vec2
vec3 :: common.vec3
vec4 :: common.vec4
mat4 :: common.mat4

PER_FRAME_BUFFER_BINDING 	:: 0
LIGHTING_BUFFER_BINDING 	:: 1
WIND_BUFFER_BINDING 		:: 2
WORLD_BUFFER_BINDING 		:: 3

DEBUG_BUFFER_BINDING 		:: 20

GRASS_TYPES_BUFFER_BINDING 		:: 10
GRASS_INSTANCE_BUFFER_BINDING 	:: 11

initialize :: proc() {}
terminate :: proc() {}

begin_frame :: proc() {}
render :: proc() {}

RenderTarget :: struct {}
create_render_target :: proc(width, height, multisample_count : i32) -> RenderTarget{
	return {}
}
destroy_render_target :: proc(rt : ^RenderTarget) {}
render_target_as_texture :: proc(rt : ^RenderTarget) -> Texture {
	return {}
}
bind_render_target :: proc(rt : ^RenderTarget) {}
resolve_render_target :: proc(rt : ^RenderTarget) {}

bind_screen_framebuffer :: proc() {}
bind_uniform_buffer :: proc(buffer : ^Buffer, binding : u32) {}
read_screen_framebuffer :: proc() -> (width, height : int, pixels_u8_rgba : []u8) {
	return width, height, pixels_u8_rgba
}

Mesh :: struct {}
create_mesh :: proc(
	vertex_positions 	: []vec3,
	vertex_normals 		: []vec3,
	vertex_texcoords	: []vec2, 
	elements 			: []u16,
) -> Mesh {
	return {}
}
destroy_mesh :: proc(mesh : ^Mesh) {}
draw_mesh :: proc(mesh : ^Mesh, model : mat4) {}

Texture :: struct {}
TextureFilterMode :: enum { Nearest, Linear }
create_color_texture :: proc(
	width, height : int,
	pixels_u8_rgba : []u8,
	filter_mode : TextureFilterMode,
) -> Texture {
	return {}
}
destroy_texture :: proc(texture : ^Texture) {}

Buffer :: struct {}
create_buffer :: proc(data_size : int, needs_to_be_writeable := false) -> Buffer {	
	return {}
}
destroy_buffer :: proc(b : ^Buffer) {}
buffer_write_data :: proc(b : ^Buffer, data : []$DataType) {}

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

set_per_frame_data :: proc(view, projection : mat4) {}
set_lighting_data :: proc(camera_position, directional_direction, directional_color, ambient_color : vec3) {}
set_wind_data :: proc(texture_offset : vec2, texture_scale : f32, texture : ^Texture) {}
set_world_data :: proc(scale, offset : vec2) {}
set_debug_data :: proc(draw_normals, draw_backfacing, draw_lod : bool) {}
