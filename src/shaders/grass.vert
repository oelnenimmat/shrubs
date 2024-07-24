#version 450

const float pi = 3.14159265359;
const float rad_to_deg = 180 / pi;

layout(set = 0, binding = 0) uniform PerFrame {
	mat4 projection;
	mat4 view;
};

// layout(std140, binding = 2) uniform Wind {
// 	vec2 texture_offset;
// 	float texture_scale;
// 	float _;
// } wind;
// layout(location = 2) uniform sampler2D wind_texture;

// x: segment count
// y: lod
// layout (location = 9) uniform vec4 segment_count;

layout(location = 0, component = 0) in vec3 instance_position;
layout(location = 0, component = 3) in float XXX_instance_angle;

layout(location = 1, component = 0) in vec2 instance_texcoord;
layout(location = 1, component = 2) in float instance_height;
layout(location = 1, component = 3) in float instance_width;

layout(location = 2, component = 0) in vec3 instance_test_color;
layout(location = 2, component = 3) in float instance_bend;

layout(location = 3, component = 0) in vec2 instance_facing;
layout(location = 3, component = 2) in vec2 instance_type_index;

layout(location = 0) out VS_OUT {
	vec3 surface_normal;
	vec2 blade_texcoord;
	vec2 field_texcoord;
	vec3 frag_view_position;
	vec3 frag_position;
	vec3 voronoi_color;
	flat uint type_index;
};

void main() {

	// Todo(Leo): put to uniform/input
	int segment_count = 5;

	int x_id = gl_VertexIndex % 2;
	int y_id = gl_VertexIndex / 2;

	// LS: local space
	vec3 vertex_position;
	vec3 vertex_normal;

	// Todo(Leo): Instance facing describes y direction, x direction is rotated
	// 90 degrees, and z is just up
	vec3 x_direction = vec3(instance_facing.y, -instance_facing.x, 0);
	vec3 y_direction = vec3(instance_facing, 0);
	vec3 z_direction = vec3(0, 0, 1);

	// Wind
	// Todo(Leo): wind here is actually just the turbulence
	// vec2 wind_uv 		= instance_position.xy * wind.texture_scale + wind.texture_offset;
	// vec2 wind_amounts 	= textureLod(wind_texture, wind_uv, 0).xy;
	vec2 wind_amounts 	= vec2(0.5);
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
	frag_position = instance_position.xyz + vertex_position;

	voronoi_color = instance_test_color;

	type_index = uint(instance_type_index.x);
}