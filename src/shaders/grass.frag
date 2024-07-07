#version 450

layout (location = 0) in vec3 surface_normal;
layout(location = 1) in vec2 blade_texcoord;
layout(location = 2) in vec2 field_texcoord;
layout(location = 3) in vec3 view_position;
layout(location = 4) in vec3 frag_position;
layout(location = 5) in vec3 voronoi_color;

layout (location = 5) uniform vec3 light_direction;
layout (location = 6) uniform vec3 light_color;
layout (location = 7) uniform vec3 ambient_color;

layout (location = 8) uniform sampler2D field_texture;

// x: segment count
// y: lod
layout (location = 9) uniform vec4 segment_count;
layout (location = 10) uniform vec4 debug_params;

// todo(Leo): explicit locations
uniform vec4 bottom_color;
uniform vec4 top_color;

// x: roughness
uniform vec4 surface_params;
uniform vec4 camera_position;

out vec4 out_color;

void main() {
	vec3 normal = normalize(surface_normal);
	if (!gl_FrontFacing) {
		normal = -normal;
	}
	float ndotl = dot(-light_direction, normal);
	// HACK: translucency??
	// Todo(Leo): just turn off while testing reflections
#if 1
	if (ndotl < 0) {
		ndotl = 0.6 * -ndotl;
	}
#else
	ndotl = max(0, ndotl);
#endif

	// vec3 surface_color 	= texture(field_texture, field_texcoord).rgb;
	vec3 surface_color 	= mix(bottom_color.rgb, top_color.rgb, blade_texcoord.y);
	vec3 surface 		= surface_color;

	if (debug_params.w > 0.5) {
		switch (int(segment_count.y)) {
			case 0: surface = vec3(0.2, 0.2, 0.8); break;
			case 1: surface = vec3(0.8, 0.2, 0.8); break;
			case 2: surface = vec3(0.8, 0.8, 0.2); break;
		}
	}

	float roughness = surface_params.x;
	// Todo(Leo): very crappy specular, will do for now
	// https://computergraphics.stackexchange.com/a/12742
	float shininess = 2 / (roughness * roughness) - 2;

	vec3 view_direction = normalize(camera_position.xyz - frag_position);
	vec3 half_vector = normalize(-light_direction + view_direction);
	vec3 specular = light_color * pow(1 - roughness, 2) * pow(max(0, dot(normal, half_vector)), shininess);

	vec3 diffuse = light_color * ndotl * surface_color;

	vec3 ambient = ambient_color * surface_color;

	out_color = vec4(diffuse + specular + ambient, 1);

	// out_color = vec4(voronoi_color * ndotl, 1);

	if (debug_params.x > 0.5) {
		out_color = vec4(ndotl.xxx, 1);
		out_color = vec4(normal.x, -normal.y, 0, 1);
		out_color = vec4(normal.z, -normal.z, 0, 1);
		out_color = vec4(normal, 1);
	}

	if (debug_params.y > 0.5) {
		if (gl_FrontFacing) {
			out_color = vec4(0.8, 0, 0, 1);
		} else {
			out_color = vec4(0, 0, 0.8, 1);
		}
	}
}
