#version 450

layout(std140, binding = 1) uniform Lighting {
	vec4 camera_position;
	vec4 light_direction;
	vec4 light_color;
	vec4 ambient_color;
};

layout(location = 0) out vec4 out_color;

void main() {
	// Simple, but quite nice approximation
	out_color = vec4(ambient_color.rgb, 1);
}