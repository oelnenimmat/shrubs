#version 450

layout(set = 0, binding = 0) uniform PerFrame {
	mat4 projection;
	mat4 view;
};

layout(push_constant) uniform LinePerDraw {
	vec4 points[2];
	vec4 color;
};

void main() {
	vec3 position 	= points[gl_VertexIndex].xyz;
	gl_Position 	= projection * view * vec4(position, 1.0);
}