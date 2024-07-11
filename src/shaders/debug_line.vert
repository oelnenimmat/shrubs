#version 450

layout(std140, binding = 0) uniform PerFrame {
	mat4 projection;
	mat4 view;
};

layout(location = 2) uniform mat4 model;

layout(location = 0) in vec3 vertex_position;

void main() {
	gl_Position = projection * view * model * vec4(vertex_position, 1.0);
}