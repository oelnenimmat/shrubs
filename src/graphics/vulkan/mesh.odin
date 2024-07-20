package graphics

Mesh :: struct {}
create_mesh :: proc(
	vertex_positions 	: []vec3,
	vertex_normals 		: []vec3,
	vertex_texcoords	: []vec2, 
	elements 			: []u16,
) -> Mesh {
	return {}
}
destroy_mesh :: proc(mesh : ^Mesh) {}
draw_mesh :: proc(mesh : ^Mesh, model : mat4) {
	draw_basic_mesh()
}