package debug

import "shrubs:assets"
import "shrubs:common"
import graphics "shrubs:graphics/opengl"

import "core:fmt"
import "core:math/linalg"

vec2 		:: common.vec2
vec3 		:: common.vec3
vec4 		:: common.vec4
mat3 		:: common.mat3
mat4 		:: common.mat4
quaternion 	:: common.quaternion

RED 	:: vec3{0.9, 0.1, 0.1}
GREEN 	:: vec3{0.1, 0.9, 0.1}
BLUE 	:: vec3{0.1, 0.1, 0.9}

YELLOW 	:: vec3{0.9, 0.9, 0.1}
BLACK 	:: vec3{0.1, 0.1, 0.1}

BRIGHT_PURPLE :: vec3{0.8, 0.0, 1.0}

@private
DrawCall :: struct {
	model_matrix 	: mat4,
	color 			: vec3,
	mesh 			: ^graphics.Mesh,
}

@private
debug_drawing : struct {
	draws : [dynamic]DrawCall,

	sphere_mesh : graphics.Mesh,
	cube_mesh 	: graphics.Mesh,
}

initialize :: proc(capacity : int) {
	dd := &debug_drawing
	dd^ = {}

	{
		positions, normals, texcoords, elements := assets.NOT_MEMORY_SAFE_gltf_load_node("assets/shapes.glb", "shape_sphere")
		dd.sphere_mesh = graphics.create_mesh(positions, normals, texcoords, elements)

		delete(positions)
		delete(normals)
		delete(texcoords)
		delete(elements)
	}

	{
		positions, normals, texcoords, elements := assets.NOT_MEMORY_SAFE_gltf_load_node("assets/shapes.glb", "shape_cube")
		dd.cube_mesh = graphics.create_mesh(positions, normals, texcoords, elements)

		delete(positions)
		delete(normals)
		delete(texcoords)
		delete(elements)
	}
}

terminate :: proc() {
	dd := &debug_drawing

	delete (dd.draws)

	graphics.destroy_mesh(&dd.sphere_mesh)
	graphics.destroy_mesh(&dd.cube_mesh)

	dd^ = {}
}

new_frame :: proc() {
	// debug_drawing.count = 0
	resize(&debug_drawing.draws, 0)
}

render :: proc() {
	dd := &debug_drawing

	for d in dd.draws {
		// Todo(Leo): not nice to set material every frame, maybe limit palette
		// and sort, but also doesn't really matter (escpecially right now :))
		graphics.draw_debug_mesh(d.mesh, d.model_matrix, d.color)
	}

}

@private
draw :: proc(model_matrix : mat4, color : vec3, mesh : ^graphics.Mesh) {
	dd := &debug_drawing
	append(&dd.draws, DrawCall{model_matrix, color, mesh})
}

draw_wire_sphere :: proc(position : vec3, size : f32, color : vec3) {
	dd 				:= &debug_drawing
	model_matrix 	:= linalg.matrix4_from_trs_f32(position, quaternion(1), vec3(size))
	draw(model_matrix, color, &dd.sphere_mesh)
}

draw_wire_cube :: proc(position : vec3, rotation : quaternion, size : vec3, color : vec3) {
	dd 				:= &debug_drawing
	model_matrix 	:= linalg.matrix4_from_trs_f32(position, rotation, size)
	draw(model_matrix, color, &dd.cube_mesh)
}

// Todo(Leo): this is a start of more proper debug messaging thing, this way we don't
// end up with fmt.printlns everywhere, when this is in fact what we want. Later print
// to gui or smth
message :: proc(msg: string, args: ..any, loc := #caller_location) {
	PRINT_ADDRESS :: false
	when PRINT_ADDRESS {
		fmt.printf("[{}(line {})]: ", loc.procedure, loc.line)
	}

	fmt.printfln(msg, ..args, flush=true)
}