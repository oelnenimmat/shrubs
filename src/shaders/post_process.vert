#version 460

out vec2 texcoord;

void main() {
	vec2 uv 	= vec2(gl_VertexID % 2, gl_VertexID / 2);
	gl_Position = vec4(uv * 2 - 1, 0, 1);
	texcoord 	= uv;
}