#version 450

const float pi = 3.14159265359;
const float rad_to_deg = 180 / pi;

layout(location = 0, component = 0) in vec3 instance_position;
layout(location = 0, component = 3) in float instance_angle;
layout(location = 1, component = 0) in vec2 instance_texcoord;
layout(location = 1, component = 2) in float instance_height;
layout(location = 1, component = 3) in float instance_width;
layout(location = 2, component = 0) in float instance_bend;
layout(location = 2, component = 1) in vec3 _unused;

layout(location = 0) uniform mat4 projection;
layout(location = 1) uniform mat4 view;

// xy: offset
// z: scale
layout(location = 3) uniform vec4 wind_params;
layout(location = 4) uniform sampler2D wind_texture;

layout(location = 0) out vec3 surface_normal;
layout(location = 1) out vec2 blade_texcoord;
layout(location = 2) out vec2 field_texcoord;
layout(location = 4) out vec3 frag_position;

// Todo(Leo): this is probably not used
layout(location = 3) out vec3 view_position;

// x: segment count
// y: lod
layout (location = 9) uniform vec4 segment_count;
layout (location = 10) uniform vec4 debug_params;

void main() {

	int x_id = gl_VertexID % 2;
	int y_id = gl_VertexID / 2;

	// LS: local space
	vec3 vertex_position;
	vec3 vertex_normal;

	// todo(Leo): if we only rotate unit-x vector, we dont need the full matrix
	// Todo(Leo): optimize by inlining, and maybe test a lookup table and interpolation also for selected values
	mat3 rotation_matrix 	= mat3(1.0);
	rotation_matrix[0][0] 	= cos(instance_angle);
	rotation_matrix[1][0] 	= -sin(instance_angle);
	rotation_matrix[0][1] 	= sin(instance_angle);
	rotation_matrix[1][1] 	= cos(instance_angle);

	// Todo(Leo): we only use the matrix here, can inline
	// Todo(Leo): optimize by flipping around when are backfacing
	vec3 x_direction = rotation_matrix * vec3(1, 0, 0);
	vec3 y_direction = rotation_matrix * vec3(0, 1, 0);

	// Todo(Leo): the rotation matrix is now only around z axis, so this wont matter
	// this might change with the spherical planet thing
	// vec3 z_direction = rotation_matrix * vec3(0, 0, 1);
	vec3 z_direction = vec3(0, 0, 1);

	// Wind
	// Todo(Leo): wind here is actually just the turbulence
	vec2 wind_uv 		= instance_position.xy * wind_params.z + wind_params.xy;
	vec2 wind_amounts 	= textureLod(wind_texture, wind_uv, 0).xy;
	wind_amounts 		= wind_amounts * 2 - vec2(1, 1);
	float wind_amount 	= length(wind_amounts) * 2;
	vec2 wind_direction = normalize(wind_amounts);

	float height_percent = float(y_id) / segment_count.x;

	// These are correct for the wind
	vec2 bend_direction = wind_direction;
	float bend_angle 	= wind_amount * pi / 2; // [-1, 1] --> [-pi/2, pi/2]

	vec2 bend_direction_2 = y_direction.xy;
	float bend_angle_2 	= instance_bend * pi / 2; // [-1, 1] --> [-pi/2, pi/2]


	// Bezier curved blades shorten a little bit as they take a shortcut. This
	// is used as approximation to stretch the bezier arms. The approximation
	// assumes that the curve length is equal to the average of the arm's lengths
	// and the direct length. While this is most likely a little of, the actual
	// length will be longer than direct length and shorter than the combined arms'
	// lengths. This is further approximated a polynomial as the exact formula
	// requires a cosine and a square root.
	float length_correction = 1 + 2e-5 * pow(bend_angle * rad_to_deg, 2);

	// 3d bezier
	float arm_length_3D = 0.5 * instance_height; // * length_correction
	vec3 b0 = vec3(0, 0, 0);
	vec3 b1 = vec3(0, 0, arm_length_3D);
	vec3 b2 = vec3(	
		(bend_direction.x * (-sin(bend_angle)) + bend_direction_2.x * (-sin(bend_angle_2))) * arm_length_3D,
		(bend_direction.y * (-sin(bend_angle)) + bend_direction_2.y * (-sin(bend_angle_2))) * arm_length_3D,
		(1 + cos(bend_angle)) * arm_length_3D
	);

	vec3 b01 = mix(b0, b1, height_percent);
	vec3 b12 = mix(b1, b2, height_percent);
	vec3 b012 = mix(b01, b12, height_percent);
/*
	// 2d bezier, i.e. on YZ-plane
	float arm_length 	= 0.5 * instance_height * length_correction;
	vec2 bezier_0 		= vec2(0, 0);
	vec2 bezier_1 		= vec2(0, arm_length);
	vec2 bezier_2 		= vec2(
		-sin(bend_angle) * arm_length,
		arm_length + cos(bend_angle) * arm_length
	);

	vec2 bezier_01 = mix(bezier_0, bezier_1, height_percent);
	vec2 bezier_12 = mix(bezier_1, bezier_2, height_percent);
	vec2 bezier_012 = mix(bezier_01, bezier_12, height_percent);

	// Bezier plane Y(x-component) maps to wind direction and Z(y-component)
	// to the regular z-axis
	float x = bezier_012.x * bend_direction.x;
	float y = bezier_012.x * bend_direction.y;
	float z = bezier_012.y;
*/
	float x = b012.x;
	float y = b012.y;
	float z = b012.z;

	// width_factor curves the blade edge along the local unbended z and
	// the the local_x is the vertex on the edge.
	float width_factor 	= 1 - pow(height_percent, 3);
	float local_x 		= (-(0.5 * instance_width) + x_id * instance_width) * width_factor;

	vertex_position = vec3(x, y, z) + x_direction * local_x;
	
	// We have lost the angle directions when taking angle from length of
	// the wind vector.
	vec3 front_facing_direction = normalize(-y_direction);
	float bend_forward = dot(front_facing_direction.xy, bend_direction);
	if (bend_forward > 0) {
		bend_angle = -bend_angle;
	}		

	vec2 nezier_normal = mix(
		vec2(-1, 0),
		vec2(-cos(bend_angle), -sin(bend_angle)),
		height_percent
	);
	vec3 bended_normal 	= nezier_normal.x * y_direction + nezier_normal.y * z_direction;
	vertex_normal 		= mix(
		front_facing_direction, 
		bended_normal, 
		abs(bend_forward)
	);

	gl_Position = projection * view * vec4(instance_position.xyz + vertex_position, 1.0);


	surface_normal = normalize(vertex_normal);
	blade_texcoord.x = (y_id == segment_count.x) ? 0.5 : x_id;
	blade_texcoord.y = height_percent;
	field_texcoord = instance_texcoord.xy;
	view_position = view[3].xyz;
	frag_position = instance_position.xyz + vertex_position;
}