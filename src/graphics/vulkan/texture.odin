package graphics

Texture :: struct {}
TextureFilterMode :: enum { Nearest, Linear }
create_color_texture :: proc(
	width, height : int,
	pixels_u8_rgba : []u8,
	filter_mode : TextureFilterMode,
) -> Texture {
	return {}
}
destroy_texture :: proc(texture : ^Texture) {}