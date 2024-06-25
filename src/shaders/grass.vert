#version 450

layout(location = 0) in vec3 vertex_position;
layout(location = 1) in vec3 vertex_normal;
layout(location = 2) in vec4 instance_position;
layout(location = 3) in vec4 instance_texcoord;

layout(location = 0) uniform mat4 projection;
layout(location = 1) uniform mat4 view;
// layout(location = 2) uniform mat4 model;

layout(location = 2) uniform vec4 wind_direction_amount;

layout(location = 0) out vec3 surface_normal;
layout(location = 1) out vec2 blade_texcoord;
layout(location = 2) out vec2 field_texcoord;

void main() {

	float angle 			= instance_texcoord.w;
	mat3 rotation_matrix 	= mat3(1.0);
	rotation_matrix[0][0] 	= cos(angle);
	rotation_matrix[1][0] 	= -sin(angle);
	rotation_matrix[0][1] 	= sin(angle);
	rotation_matrix[1][1] 	= cos(angle);

	float scale 	= instance_texcoord.z;
	vec3 position 	= rotation_matrix * vertex_position * scale + instance_position.xyz;

	// assume this is true
	float normalized_height = vertex_position.z;
	float offset_strength = normalized_height * normalized_height; 

	vec3 offset_direction = normalize(wind_direction_amount.xyz);
	float offset_amount = wind_direction_amount.w;

	vec3 offset = offset_direction * offset_amount * offset_strength;

	position += offset;

	gl_Position = projection * view * vec4(position, 1.0);

	// mat3 normal_matrix = transpose(inverse(mat3(model)));
	surface_normal = normalize(vertex_normal);

	blade_texcoord.x = vertex_position.x * 5 + 0.1;
	blade_texcoord.y = vertex_position.z;

	field_texcoord = instance_texcoord.xy;
}