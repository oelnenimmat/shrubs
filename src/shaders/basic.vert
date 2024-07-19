#version 450

layout(set = 0, binding = 0) uniform PerFrame {
	mat4 projection;
	mat4 view;
};
// layout(location = 0) uniform mat4 model;

// layout(location = 0) in vec3 vertex_position;
// layout(location = 1) in vec3 vertex_normal;
// layout(location = 2) in vec2 vertex_texcoord;

layout(location = 0) out VS_OUT {
	vec3 surface_normal;
	vec2 texcoord;
};

void main() {
	// HACKSTART
	mat4 model = mat4(1);

	vec3 vertex_position;
	switch (gl_VertexIndex % 8) {
		case 0: vertex_position = vec3(-1, -1, -1); break;
		case 1: vertex_position = vec3(1, -1, -1); break;
		case 2: vertex_position = vec3(-1, 1, -1); break;
		case 3: vertex_position = vec3(1, -1, -1); break;
		
		case 4: vertex_position = vec3(-1, -1, 1); break;
		case 5: vertex_position = vec3(1, -1, 1); break;
		case 6: vertex_position = vec3(-1, 1, 1); break;
		case 7: vertex_position = vec3(1, -1, 1); break;
	}

	vec3 vertex_normal = normalize(vertex_position);
	vec2 vertex_texcoord = vertex_position.xy / 2 + 0.5;
	// HACKEND

	gl_Position 		= projection * view * model * vec4(vertex_position, 1.0);

	mat3 normal_matrix 	= transpose(inverse(mat3(model)));
	surface_normal 		= normalize(normal_matrix * vertex_normal);

	texcoord 			= vertex_texcoord;
}