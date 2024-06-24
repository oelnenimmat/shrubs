package assets

import "../common"

import stbi "vendor:stb/image"


Color_u8_rgba :: common.Color_u8_rgba

LoadedColorImage :: struct {
	width, height 	: int,
	pixels 			: []Color_u8_rgba
}

free_loaded_color_image :: proc(image : ^LoadedColorImage) {
	stbi.image_free(raw_data(image.pixels))

	image^ = {}
}

@(warning = "return type might be a hazard for casting the memory thing :)")
load_color_image :: proc(filename : cstring) -> LoadedColorImage {
	width, height, channels : i32

	pixels := stbi.load(filename, &width, &height, &channels, 4)
	pixel_count := width * height
	return { int(width), int(height), (cast([^]Color_u8_rgba)pixels)[0:pixel_count] }
}