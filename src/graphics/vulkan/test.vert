#version 450

layout(location = 0) out vec4 color;

void main() {
	float x = (gl_VertexIndex % 2) - 0.5;
	float y = 1 - (gl_VertexIndex / 2) - 0.5;

	gl_Position = vec4(x, y, 0.9999, 1);

	color.rgb = vec3 (
		gl_VertexIndex == 0,
		gl_VertexIndex == 1,
		gl_VertexIndex == 2
	);
	color.a = 1;
}