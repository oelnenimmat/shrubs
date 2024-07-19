#version 450

void main() {
	// expect 3 vertices -> the infamous full screen triangle
	float x = (gl_VertexIndex % 2) * 4 - 1;
	float y = (gl_VertexIndex / 2) * 4 - 1;

	gl_Position = vec4(x, y, 1, 1);
}