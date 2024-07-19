layout(set = LIGHTING_SET, binding = 0) uniform Lighting {
	vec4 camera_position;
	vec4 light_direction;
	vec4 light_color;
	vec4 ambient_color;
};