#version 450

layout(std140, binding = 0) uniform PerFrame {
	mat4 projection;
	mat4 view;
};

layout(std140, binding = 3) uniform World {
	vec2 placement_texcoord_scale;
	vec2 placement_texcoord_offset;
};

layout(location = 0) uniform mat4 model;

layout(location = 0) in vec3 vertex_position;
layout(location = 1) in vec3 vertex_normal;

// this is not need rn, but it is still in the mesh data probably
// layout(location = 2) in vec2 vertex_texcoord;

out VS_OUT {
	vec3 surface_normal;
	vec2 texcoord;
};

void main() {
	vec4 world_position = model * vec4(vertex_position, 1.0);
	gl_Position 		= projection * view * world_position;

	mat3 normal_matrix 	= transpose(inverse(mat3(model)));
	surface_normal 		= normalize(normal_matrix * vertex_normal);

	// scale and offset are in world units, and the end must be in texcoord units
	// ([0,1] and wrapping) so add offset first, scale then. Also scale is used to
	// divide as it is essentially a normalizing factor.
	// Todo(Leo): make a function of this in the common shader files once we get those.
	texcoord = (world_position.xy + placement_texcoord_offset) / placement_texcoord_scale;
}