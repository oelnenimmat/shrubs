#version 460

layout(set = 0, binding = 0) uniform sampler2D color_image;

// x: exposure
// uniform vec4 params;
layout(set = 1, binding = 0) uniform AAARGH {
	float 	exposure;
	float 	_nothing1;
	vec2 	_nothing2;
};

layout(location = 0) in vec2 texcoord;
layout(location = 0) out vec4 out_color;

void main() {
	vec3 in_color = texture(color_image, texcoord).rgb;

	vec3 color = in_color;

	// HDR to LDR
	color = 1.0 - exp(-color * exposure);

	out_color = vec4(color, 1);

	if (texcoord.x > 1 || texcoord.y > 1) {
		out_color.rgb = vec3(0, 0, 1);
	}

	if (texcoord.x < 0 || texcoord.y < 0) {
		out_color.rgb = vec3(0, 1, 0);
	}
}