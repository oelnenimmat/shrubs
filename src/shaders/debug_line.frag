#version 450

layout(push_constant) uniform LinePerDraw {
	vec4 points[2];
	vec4 color;
};
layout(location = 0) out vec4 out_color;

void main() {
	out_color = vec4(color.rgb * 2, 1);
}
