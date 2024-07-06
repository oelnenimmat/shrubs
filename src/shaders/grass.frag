#version 450

layout (location = 0) in vec3 surface_normal;
layout(location = 1) in vec2 blade_texcoord;
layout(location = 2) in vec2 field_texcoord;

layout (location = 5) uniform vec3 light_direction;
layout (location = 6) uniform vec3 light_color;
layout (location = 7) uniform vec3 ambient_color;

layout (location = 8) uniform sampler2D field_texture;

layout (location = 10) uniform vec4 debug_params;


out vec4 out_color;

void main() {
	vec3 normal 	= normalize(surface_normal);// * (gl_FrontFacing ? 1 : -1); 
		// normal.z = - normal.z;
	if (debug_params.z > 0.5 && !gl_FrontFacing) {
		normal = -normal;
	}

	// if (debug_params.w > 0.5 && !gl_FrontFacing) {
	// 	normal.x *= -1;
	// 	normal.y *= -1;
	// }

	// float ndotl 	= max(0, dot(-light_direction, normal));
	// HACK: translucency??
	float ndotl = dot(-light_direction, normal);
#if 1
	if (ndotl < 0) {
		ndotl = 0.3 * -ndotl;
	}
#else
	ndotl = max(0, ndotl);
#endif
	vec3 lighting 	= light_color * ndotl + ambient_color;

	// vec3 surface_color 	= texture(field_texture, field_texcoord).rgb;
	vec3 surface_color 	= texture(field_texture, vec2(0,0)).rgb;
	vec3 surface 		= surface_color; // * (0.6 + 0.4 * blade_texcoord.y);

	vec3 color 		= lighting * surface;
	out_color = vec4(color, 1);

	if (debug_params.x > 0.5) {
		out_color = vec4(ndotl.xxx, 1);
		out_color = vec4(normal.z, -normal.z, 0, 1);
		out_color = vec4(normal.x, -normal.y, 0, 1);
		// out_color = vec4(normal, 1);
	}

	if (debug_params.y > 0) {
		if (gl_FrontFacing) {
			out_color = vec4(0.8, 0, 0, 1);
		} else {
			out_color = vec4(0, 0, 0.8, 1);
		}
	}
}
