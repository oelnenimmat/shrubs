#version 460

layout (location = 0) in vec4 font_color;
layout (location = 1) in vec2 font_texture_coord;
layout (location = 2) in vec2 fill_texture_coord;

uniform sampler2D font_or_fill_texture;
uniform float use_fill_texture;

out vec4 FragColor;

void main()
{
    if (use_fill_texture == 0) {
        FragColor   = font_color;
        FragColor.a *= texture(font_or_fill_texture, font_texture_coord).a;
    } else {
        FragColor       = texture(font_or_fill_texture, fill_texture_coord);
    }
}