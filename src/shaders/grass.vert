#version 450

const float pi = 3.14159265359;
const float rad_to_deg = 180 / pi;

// layout(location = 0) in vec3 vertex_position;
// layout(location = 1) in vec3 vertex_normal;
layout(location = 2) in vec4 instance_position;
layout(location = 3, component = 0) in vec2 instance_texcoord;
layout(location = 3, component = 2) in float instance_height;
layout(location = 3, component = 3) in float instance_angle;

layout(location = 0) uniform mat4 projection;
layout(location = 1) uniform mat4 view;

// xy: offset
// z: scale
layout(location = 3) uniform vec4 wind_params;
layout(location = 4) uniform sampler2D wind_texture;

layout(location = 0) out vec3 surface_normal;
layout(location = 1) out vec2 blade_texcoord;
layout(location = 2) out vec2 field_texcoord;

void main() {

	// LS: local space
	vec3 position_LS;
	vec3 normal_LS;

	// todo(Leo): if we only rotate unit-x vector, we dont need the full matrix
	float angle 			= instance_angle;
	mat3 rotation_matrix 	= mat3(1.0);
	rotation_matrix[0][0] 	= cos(angle);
	rotation_matrix[1][0] 	= -sin(angle);
	rotation_matrix[0][1] 	= sin(angle);
	rotation_matrix[1][1] 	= cos(angle);


	vec2 wind_uv 		= instance_position.xy * wind_params.z + wind_params.xy;
	vec2 wind_amounts 	= textureLod(wind_texture, wind_uv, 0).xy;
	wind_amounts 		= wind_amounts * 2 - vec2(1, 1);
	float wind_amount 	= length(wind_amounts);
	vec2 wind_direction = normalize(wind_amounts);

	float full_height = 1;
	int segments = 4;

	float height_percent = float(gl_VertexID / 2) / float(segments);

	float width 			= 0.1;
	float segment_height 	= full_height / segments;

	// map from [-1, 1] to [-pi/2, pi/2]
	float bend_angle = wind_amount * pi / 2;

	// Bezier curved blades shorten a little bit as they take a shortcut. This
	// is used as approximation to stretch the bezier arms. The approximation
	// assumes that the curve length is equal to the average of the arm's lengths
	// and the direct length. While this is most likely a little of, the actual
	// length will be longer than direct length and shorter than the combined arms'
	// lengths. This is further approximated a polynomial as the exact formula
	// requires a cosine and a square root.
	float length_correction = 1 + 2e-5 * pow(bend_angle * rad_to_deg, 2);

	float arm_length = full_height / 2 * length_correction;
	vec2 bezier_0 = vec2(0, 0);
	vec2 bezier_1 = vec2(0, arm_length);
	vec2 bezier_2 = vec2(
		sin(bend_angle) * arm_length,
		arm_length + cos(bend_angle) * arm_length
	);

	vec2 bezier_01 = mix(bezier_0, bezier_1, height_percent);
	vec2 bezier_12 = mix(bezier_1, bezier_2, height_percent);
	vec2 bezier_012 = mix(bezier_01, bezier_12, height_percent);

	float z = bezier_012.y;
	float x = bezier_012.x * wind_direction.x;
	float y = bezier_012.x * wind_direction.y;

	float width_factor = 1 - pow(height_percent / (4*segment_height), 3);
	float xx = (-(0.5 * width) + (gl_VertexID % 2) * width) * width_factor;

	vec3 x_direction = rotation_matrix * vec3(1, 0, 0);
	vec3 y_direction = rotation_matrix * vec3(0, 1, 0);

	position_LS = vec3(x, y, z) + x_direction * xx;
	
	vec2 nezier_normal = mix(
		vec2(1, 0),
		vec2(cos(bend_angle), sin(bend_angle)),
		height_percent
	);

	// as in non rotated blade
	vec3 bended_normal = vec3(0, nezier_normal.x, -nezier_normal.y);
	float ddd = dot(y_direction.xy, normalize(wind_direction.xy));

	normal_LS = mix(y_direction, rotation_matrix * bended_normal, ddd);
	
	float scale 	= instance_height;
	vec3 position 	= position_LS * scale + instance_position.xyz;

	gl_Position = projection * view * vec4(position, 1.0);

	surface_normal = normalize(normal_LS);

	blade_texcoord.x = position_LS.x * 5 + 0.1;
	blade_texcoord.y = position_LS.z;

	field_texcoord = instance_texcoord.xy;
}