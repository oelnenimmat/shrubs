#version 450

layout (location = 7) uniform sampler2D surface_texture;

// Todo(Leo): use different one here
in VS_OUT {
	vec3 surface_normal; // not used, but part of common VS_OUT
	vec2 texcoord;
};

out vec4 out_color;

void main() {
	out_color = vec4(texture(surface_texture, texcoord).rgb, 1);
}