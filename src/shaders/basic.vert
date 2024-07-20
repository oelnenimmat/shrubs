#version 450

layout(set = 0, binding = 0) uniform PerFrame {
	mat4 projection;
	mat4 view;
};

layout(push_constant) uniform MeshPerDraw {
	mat4 model;
};

layout(location = 0) in vec3 vertex_position;
// layout(location = 1) in vec3 vertex_normal;
// layout(location = 2) in vec2 vertex_texcoord;

layout(location = 0) out VS_OUT {
	vec3 surface_normal;
	vec2 texcoord;
};

// const vec3 v [14] = vec3[](
// 	vec3(-1, 1, -1),
// 	vec3(1, 1, -1),
// 	vec3(-1, -1, -1),
// 	vec3(1, -1, -1),
// 	vec3(1, -1, 1),
// 	vec3(1, 1, -1),
// 	vec3(1, 1, 1),
// 	vec3(-1, 1, -1),
// 	vec3(-1, 1, 1),
// 	vec3(-1, -1, -1),
// 	vec3(1, -1, 1),
// 	vec3(-1, 1, 1),
// 	vec3(1, 1, 1),
// 	vec3(-1, 1, 1)
// );

void main() {
	// HACKSTART

	// vec3 vertex_position = v[gl_VertexIndex];

	vec3 vertex_normal = normalize(vertex_position);
	vec2 vertex_texcoord = vertex_position.xy / 2 + 0.5;
	// HACKEND

	gl_Position 		= projection * view * model * vec4(vertex_position, 1.0);

	mat3 normal_matrix 	= transpose(inverse(mat3(model)));
	surface_normal 		= normalize(normal_matrix * vertex_normal);

	texcoord 			= vertex_texcoord;
}