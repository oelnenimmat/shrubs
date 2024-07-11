#version 450

layout(std140, binding = 0) uniform PerFrame {
	mat4 projection;
	mat4 view;
};
layout(location = 2) uniform mat4 model;

layout(location = 0) in vec3 vertex_position;
layout(location = 1) in vec3 vertex_normal;
layout(location = 2) in vec2 vertex_texcoord;

layout(location = 0) out vec3 surface_normal;
layout(location = 1) out vec2 texcoord;

void main() {
	gl_Position 		= projection * view * model * vec4(vertex_position, 1.0);

	mat3 normal_matrix 	= transpose(inverse(mat3(model)));
	surface_normal 		= normalize(normal_matrix * vertex_normal);

	texcoord 			= vertex_texcoord;
}