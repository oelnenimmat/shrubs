#version 460

uniform vec2 window_size;
uniform vec4 screen_rect;
uniform vec4 texture_rect;

// 0(Solid): 		rgba: fill_color
// 1(Text/Icon): 	rgb: fill_color, alpha: texture
// 2(Image): 		rgba: texture
uniform int fill_mode;

layout (location = 0) out vec2 texcoord;

void main()
{
	vec2 screen_position;
	vec2 font_texcoord;
	vec2 image_texcoord;
	switch (gl_VertexID) {
		case 0:
			screen_position = vec2(screen_rect.x, screen_rect.y + screen_rect.w);
			font_texcoord 	= vec2(texture_rect.x, texture_rect.y + texture_rect.w);
			image_texcoord 	= vec2(0, 0);
			break;

		case 1: 
			screen_position = vec2(screen_rect.x + screen_rect.z, screen_rect.y + screen_rect.w);
			font_texcoord 	= vec2(texture_rect.x + texture_rect.z, texture_rect.y + texture_rect.w);
			image_texcoord 	= vec2(1, 0);
			break;

		case 2: 
			screen_position = vec2(screen_rect.x, screen_rect.y);
			font_texcoord 	= vec2(texture_rect.x, texture_rect.y);
			image_texcoord 	= vec2(0, 1);
			break;

		case 3: 
			screen_position = vec2(screen_rect.x + screen_rect.z, screen_rect.y);
			font_texcoord 	= vec2(texture_rect.x + texture_rect.z, texture_rect.y);
			image_texcoord 	= vec2(1, 1);
			break;
	}

	float normalized_screen_x = 2 * screen_position.x / window_size.x - 1.0;
	float normalized_screen_y = 1.0 - 2 * screen_position.y / window_size.y ;
	
	gl_Position = vec4(normalized_screen_x, normalized_screen_y, 0.0, 1.0);

	switch (fill_mode) {
		case 0: break;
		case 1: texcoord = font_texcoord; break;
		case 2: texcoord = image_texcoord; break;
	}
}