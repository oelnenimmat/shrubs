#version 450

#define LIGHTING_SET 1
#include "lighting.glsl"

// layout(set = 2, binding = 0) uniform Debug {
// 	float draw_normals;
// 	float draw_backfacing;
// 	float draw_lod;
// } debug;

// layout (location = 3) uniform vec3 surface_color;
// layout (location = 7) uniform sampler2D surface_texture;

layout(location = 0) in VS_OUT {
	vec3 surface_normal;
	vec2 texcoord;
};

layout(location = 0) out vec4 out_color;

void main() {

	vec3 normal 	= normalize(surface_normal);
	float ndotl 	= max(0, dot(-light_direction.xyz, normal));
	vec3 lighting 	= light_color.rgb * ndotl + ambient_color.rgb;
	vec3 surface 	= vec3(0.9, 0.85, 0.2); //surface_color * texture(surface_texture, texcoord).rgb;

	vec3 color 		= lighting * surface;

	out_color = vec4(color, 1);

	// if (debug.draw_normals > 0.5) {
	// 	out_color = vec4(normal, 1);
	// }
}
