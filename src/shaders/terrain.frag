#version 450

layout (location = 0) in vec3 surface_normal;
layout (location = 1) in vec2 texcoord;

layout (location = 3) uniform vec3 surface_color;
layout (location = 4) uniform vec3 light_direction;
layout (location = 5) uniform vec3 light_color;
layout (location = 6) uniform vec3 ambient_color;

// layout (location = 7) uniform sampler2D surface_texture;

layout (location = 7) uniform sampler2D splatter_texture;
layout (location = 8) uniform sampler2D grass_texture;
layout (location = 9) uniform sampler2D road_texture;

out vec4 out_color;

void main() {

	vec3 normal 	= normalize(surface_normal);
	float ndotl		= max(0, dot(-light_direction, normal));
	vec3 lighting 	= light_color * ndotl + ambient_color;
	
	float splatter = texture(splatter_texture, texcoord).r;
	vec3 surface = mix(
		texture(road_texture, texcoord * 10).rgb,
		texture(grass_texture, texcoord).rgb,
		splatter
	);

	vec3 color 		= lighting * surface;

	out_color = vec4(color, 1);
	// out_color = vec4(ndotl.xxx, 1);
}
