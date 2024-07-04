#version 450

layout (location = 0) in vec3 surface_normal;
layout(location = 1) in vec2 blade_texcoord;
layout(location = 2) in vec2 field_texcoord;

layout (location = 5) uniform vec3 light_direction;
layout (location = 6) uniform vec3 light_color;
layout (location = 7) uniform vec3 ambient_color;

layout (location = 8) uniform sampler2D field_texture;

out vec4 out_color;

void main() {
	vec3 normal 	= normalize(surface_normal);// * (gl_FrontFacing ? 1 : -1); 
	float ndotl 	= abs(dot(-light_direction, normal));
	vec3 lighting 	= light_color * ndotl + ambient_color;

	vec3 surface_color 	= texture(field_texture, field_texcoord).rgb;
	vec3 surface 		= surface_color; // * (0.6 + 0.4 * blade_texcoord.y);

	vec3 color 		= lighting * surface;
	out_color = vec4(color, 1);
}
