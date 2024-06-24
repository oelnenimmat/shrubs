#version 450

layout (location = 0) in vec3 surface_normal;
layout (location = 1) in vec2 texcoord;

layout (location = 3) uniform vec3 surface_color;
layout (location = 4) uniform vec3 light_direction;
layout (location = 5) uniform vec3 light_color;
layout (location = 6) uniform vec3 ambient_color;

out vec4 out_color;

void main() {

	vec3 lighting 	= light_color * dot(-light_direction, normalize(surface_normal)) + ambient_color;
	vec3 surface 	= surface_color * texcoord.y;

	vec3 color 		= lighting * surface;

	out_color = vec4(color, 1);
}
