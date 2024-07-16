package graphics

import "shrubs:common"

vec2 :: common.vec2
vec3 :: common.vec3
vec4 :: common.vec4
mat4 :: common.mat4

initialize :: proc() {}
terminate :: proc() {}

begin_frame :: proc() {}
render :: proc() {}

// rndom
bind_screen_framebuffer :: proc() {}
bind_uniform_buffer :: proc(buffer : ^Buffer, binding : u32) {}
read_screen_framebuffer :: proc() -> (width, height : int, pixels_u8_rgba : []u8) {
	return width, height, pixels_u8_rgba
}
