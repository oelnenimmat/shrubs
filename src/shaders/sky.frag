#version 450

#define LIGHTING_SET 0
#include "lighting.glsl"

layout(location = 0) out vec4 out_color;

void main() {
	// Simple, but quite nice approximation
	out_color = vec4(ambient_color.rgb, 1);
}