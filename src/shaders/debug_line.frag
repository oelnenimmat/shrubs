#version 450

layout (location = 3) uniform vec3 color;

out vec4 out_color;

void main() {
	out_color = vec4(color, 1);
}
