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

layout (location = 7) uniform sampler2D splatter_texture;
layout (location = 8) uniform sampler2D grass_texture;
layout (location = 9) uniform sampler2D road_texture;

in VS_OUT {
	vec3 surface_normal;
	vec2 texcoord;
};

out vec4 out_color;

void main() {

	vec3 normal 	= normalize(surface_normal);
	float ndotl		= max(0, dot(-light_direction.xyz, normal));
	vec3 lighting 	= light_color.rgb * ndotl + ambient_color.rgb;
	
	float splatter = texture(splatter_texture, texcoord).r;
	vec3 surface = mix(
		texture(road_texture, texcoord * 10).rgb,
		texture(grass_texture, texcoord).rgb * vec3(0.25, 0.2, 0.25),
		splatter
	);

	vec3 color = lighting * surface;

	out_color = vec4(color, 1);

	if (debug.draw_normals > 0.5) {
		out_color = vec4(normal, 1);
	}
}
