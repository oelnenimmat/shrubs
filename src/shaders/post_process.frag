#version 460

uniform sampler2D color_image;

// x: exposure
uniform vec4 params;

in vec2 texcoord;

out vec4 out_color;

void main() {
	vec3 in_color = texture(color_image, texcoord).rgb;

	vec3 color = in_color;

	// HDR to LDR
	color = 1.0 - exp(-color * params.x);

	out_color = vec4(color, 1);
}