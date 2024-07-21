#version 450

#define LIGHTING_SET 2
#include "lighting.glsl"

// layout(std140, binding = 20) uniform Debug {
// 	float draw_normals;
// 	float draw_backfacing;
// 	float draw_lod;
// } debug;

layout (set = 3, binding = 0) uniform sampler2D splatter_texture;
layout (set = 3, binding = 1) uniform sampler2D grass_texture;
layout (set = 3, binding = 2) uniform sampler2D road_texture;

layout(location = 0) in VS_OUT {
	vec3 surface_normal;
	vec2 texcoord;
};

layout(location = 0) out vec4 out_color;

void main() {

	vec3 normal 	= normalize(surface_normal);
	float ndotl		= max(0, dot(-light_direction.xyz, normal));
	vec3 lighting 	= light_color.rgb * ndotl + ambient_color.rgb;
	
	float splatter = texture(splatter_texture, texcoord).r;
	vec3 surface = mix(
		texture(road_texture, texcoord).rgb,
		texture(grass_texture, texcoord).rgb,
		splatter
	);

	vec3 color = lighting * surface;

	out_color = vec4(color, 1);

	// if (debug.draw_normals > 0.5) {
	// 	out_color = vec4(normal, 1);
	// }
}
