#version 460

layout(location = 0) out vec2 texcoord;

void main() {
	// expect 3 vertices -> the infamous full screen triangle
	// remember that this is now for vulkan, and (-1,-1) is at top left corner
	// tho also remember that uv range also goes "wrong" direction
	float x = (gl_VertexIndex % 2) * 4 - 1;
	float y = (gl_VertexIndex / 2) * 4 - 1;

	texcoord = vec2(
		(x + 1) / 2,
		(y + 1) / 2
	);

	gl_Position = vec4(x, y, 1, 1);
}