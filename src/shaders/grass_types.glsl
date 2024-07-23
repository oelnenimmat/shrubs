struct GrassTypeData {
	float base_height;
	float height_variation;
	float width;
	float bend;

	float clump_size;
	float clump_height_variation;
	float clump_squeeze_in;
	float more_data;

	vec4 top_color;

	vec4 bottom_color;

	float roughness;
	float more_data_2;
	vec2 more_data_3;
};

const int GRASS_TYPE_COUNT = 3;

layout (set = GRASS_TYPES_SET, binding = 0) uniform grass_types {
	GrassTypeData types[GRASS_TYPE_COUNT];
};