#version 450

void main() {
	// expect 3 vertices -> the infamous full screen triangle
	// remember that this is now for vulkan, and (0,0) is at top left corner
	float x = (gl_VertexIndex % 2) * 4 - 1;
	float y = 1 - (gl_VertexIndex / 2) * 4;

	gl_Position = vec4(x, y, 1, 1);
}