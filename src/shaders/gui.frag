#version 460

layout (location = 0) in vec2 texcoord;

uniform sampler2D font_or_fill_texture;
uniform vec4 fill_color;

// 0: rgba: fill_color
// 1: rgb: fill_color, alpha: texture
// 2: rgba: texture
uniform int fill_mode;

out vec4 out_color;

void main()
{
	switch (fill_mode) {
		case 0:
			out_color = fill_color;
			break;

		case 1: 
			out_color.rgb = fill_color.rgb;
			out_color.a = texture(font_or_fill_texture, texcoord).a;
			break;
		
		case 2:
			out_color = texture(font_or_fill_texture, texcoord);
			break;
	}

}