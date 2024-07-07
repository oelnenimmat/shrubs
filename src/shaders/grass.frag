#version 450

layout (location = 0) in vec3 surface_normal;
layout(location = 1) in vec2 blade_texcoord;
layout(location = 2) in vec2 field_texcoord;

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

out vec4 out_color;

void main() {
	vec3 normal = normalize(surface_normal);
	if (!gl_FrontFacing) {
		normal = -normal;
	}
	float ndotl = dot(-light_direction, normal);
	// HACK: translucency??
	// if (debug_params.z > 0.5) {
		if (ndotl < 0) {
			ndotl = 0.4 * -ndotl;
		}
	// } else {
	// 	ndotl = max(0, ndotl);
	// }
	vec3 lighting 	= light_color * ndotl + ambient_color;

	// vec3 surface_color 	= texture(field_texture, field_texcoord).rgb;
	vec3 surface_color = mix(bottom_color.rgb, top_color.rgb, blade_texcoord.y);
	vec3 surface = surface_color;
	// surface = vec3(blade_texcoord.yyy);

	if (debug_params.w > 0.5) {
		switch (int(segment_count.y)) {
			case 0: surface = vec3(0.2, 0.2, 0.8); break;
			case 1: surface = vec3(0.8, 0.2, 0.8); break;
			case 2: surface = vec3(0.8, 0.8, 0.2); break;
		}
	}

	vec3 color 	= lighting * surface;
	out_color 	= vec4(color, 1);

	if (debug_params.x > 0.5) {
		out_color = vec4(ndotl.xxx, 1);
		out_color = vec4(normal.x, -normal.y, 0, 1);
		out_color = vec4(normal, 1);
		out_color = vec4(normal.z, -normal.z, 0, 1);
	}

	if (debug_params.y > 0.5) {
		if (gl_FrontFacing) {
			out_color = vec4(0.8, 0, 0, 1);
		} else {
			out_color = vec4(0, 0, 0.8, 1);
		}
	}

	// out_color = vec4(floor(blade_texcoord.xxx * 3) / 3, 1);

}
