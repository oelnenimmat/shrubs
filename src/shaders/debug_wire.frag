#version 450

layout(push_constant) uniform WirePerDraw {
	mat4 model;
	vec4 color;
};

layout(location = 0) out vec4 out_color;

void main() {
	out_color = vec4(color.rgb * 2, 1);
}
