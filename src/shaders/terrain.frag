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

	vec3 lighting 	= light_color * dot(-light_direction, normalize(surface_normal)) + ambient_color;
	
	float splatter = texture(splatter_texture, texcoord).r;
	vec3 surface = mix(
		texture(road_texture, texcoord).rgb,
		texture(grass_texture, texcoord).rgb,
		splatter
	);

	// Todo(Leo): this is debug darkening, for darkenign reasons
	surface *= vec3(0.4, 0.4, 0.4);
	// vec3 surface 	= surface_color * texture(surface_texture, texcoord).rgb;

	vec3 color 		= lighting * surface;

	out_color = vec4(color, 1);
}
