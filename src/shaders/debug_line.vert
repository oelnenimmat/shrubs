#version 450

layout(location = 0) in vec3 vertex_position;

layout(location = 0) uniform mat4 projection;
layout(location = 1) uniform mat4 view;
layout(location = 2) uniform mat4 model;


void main() {
	gl_Position = projection * view * model * vec4(vertex_position, 1.0);
}