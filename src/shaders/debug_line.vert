#version 450

layout(set = 0, binding = 0) uniform PerFrame {
	mat4 projection;
	mat4 view;
};

layout(push_constant) uniform WirePerDraw {
	mat4 model;
	vec4 color;
};

layout(location = 0) in vec3 vertex_position;

void main() {
	gl_Position = projection * view * model * vec4(vertex_position, 1.0);
}