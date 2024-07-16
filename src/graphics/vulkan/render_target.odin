package graphics

RenderTarget :: struct {}
create_render_target :: proc(width, height, multisample_count : i32) -> RenderTarget{
	return {}
}
destroy_render_target :: proc(rt : ^RenderTarget) {}
render_target_as_texture :: proc(rt : ^RenderTarget) -> Texture {
	return {}
}
bind_render_target :: proc(rt : ^RenderTarget) {}
resolve_render_target :: proc(rt : ^RenderTarget) {}