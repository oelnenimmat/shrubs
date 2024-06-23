#version 450

layout (location = 0) in vec3 surface_normal;

layout (location = 3) uniform vec3 surface_color;
layout (location = 4) uniform vec3 light_direction;
layout (location = 5) uniform vec3 light_color;

out vec4 out_color;

void main() {

	vec3 lighting = light_color * dot(-light_direction, normalize(surface_normal));
	vec3 surface = surface_color;

	vec3 color = lighting * surface;

	out_color = vec4(color, 1);
}
