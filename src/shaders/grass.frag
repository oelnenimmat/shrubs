#version 450

const int LIGHTING_SET = 1;
const int GRASS_TYPES_SET = 2;

#include "lighting.glsl"
#include "grass_types.glsl"


layout(location = 0) in VS_OUT {
	vec3 surface_normal;
	vec2 blade_texcoord;
	vec2 field_texcoord;
	vec3 frag_view_position;
	vec3 frag_position;
	vec3 voronoi_color;
	flat uint type_index;
};

layout (location = 0) out vec4 out_color;

void main() {
	// out_color = vec4(0, 0.6, 0, 1);
	
	vec3 normal = normalize(surface_normal);
	if (!gl_FrontFacing) {
		normal = -normal;
	}
	float ndotl = dot(-light_direction.xyz, normal);
	// HACK: translucency??
	// Todo(Leo): just turn off while testing reflections
#if 1
	if (ndotl < 0) {
		ndotl = 0.6 * -ndotl;
	}
#else
	ndotl = max(0, ndotl);
#endif

	vec3 surface_color 	= mix(types[type_index].bottom_color.rgb, types[type_index].top_color.rgb, blade_texcoord.y);
	vec3 surface 		= surface_color;

	float roughness = types[type_index].roughness;
	// Todo(Leo): very crappy specular, will do for now
	// https://computergraphics.stackexchange.com/a/12742
	float shininess = 2 / (roughness * roughness) - 2;

	vec3 view_direction = normalize(camera_position.xyz - frag_position);
	vec3 half_vector = normalize(-light_direction.xyz + view_direction);
	vec3 specular = light_color.rgb * pow(1 - roughness, 2) * pow(max(0, dot(normal, half_vector)), shininess);

	vec3 diffuse = light_color.rgb * ndotl * surface_color;

	vec3 ambient = ambient_color.rgb * surface_color;

	out_color = vec4(diffuse + specular + ambient, 1);

	// out_color = vec4(voronoi_color * ndotl, 1);

	// if (debug.draw_normals > 0.5) {
	// 	out_color = vec4(ndotl.xxx, 1);
	// 	out_color = vec4(normal.x, -normal.y, 0, 1);
	// 	out_color = vec4(normal.z, -normal.z, 0, 1);
	// 	out_color = vec4(normal, 1);
	// }

	// if (debug.draw_backfacing > 0.5) {
	// 	if (gl_FrontFacing) {
	// 		out_color = vec4(0.8, 0, 0, 1);
	// 	} else {
	// 		out_color = vec4(0, 0, 0.8, 1);
	// 	}
	// }
	
}
