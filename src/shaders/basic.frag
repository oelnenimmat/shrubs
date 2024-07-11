#version 450

layout(std140, binding = 1) uniform Lighting {
	vec4 camera_position;
	vec4 light_direction;
	vec4 light_color;
	vec4 ambient_color;
};

layout(std140, binding = 3) uniform Debug {
	float draw_normals;
	float draw_backfacing;
	float draw_lod;
} debug;

layout (location = 3) uniform vec3 surface_color;
layout (location = 7) uniform sampler2D surface_texture;

// layout (location = 0) in vec3 surface_normal;
// layout (location = 1) in vec2 texcoord;

in VS_OUT {
	vec3 surface_normal;
	vec2 texcoord;
};

out vec4 out_color;

void main() {

	vec3 normal 	= normalize(surface_normal);
	float ndotl 	= max(0, dot(-light_direction.xyz, normal));
	vec3 lighting 	= light_color.rgb * ndotl + ambient_color.rgb;
	vec3 surface 	= surface_color * texture(surface_texture, texcoord).rgb;

	vec3 color 		= lighting * surface;

	out_color = vec4(color, 1);

	if (debug.draw_normals > 0.5) {
		out_color = vec4(normal, 1);
	}
}
