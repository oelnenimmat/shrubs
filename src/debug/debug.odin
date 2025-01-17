package debug

import "shrubs:assets"
import "shrubs:common"
import graphics "shrubs:graphics/vulkan"

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

BRIGHT_PURPLE 	:: vec3{0.8, 0.0, 1.0}
BRIGHT_CYAN 	:: vec3{0.0, 1.0, 0.8}
BRIGHT_ORANGE 	:: vec3{1.0, 0.8, 0.0}

@private
DrawCall :: struct {
	model_matrix 	: mat4,
	color 			: vec3,
	mesh 			: ^graphics.Mesh,
}

@private
LineDrawCall :: struct {
	points 	: [2]vec3,
	color 	: vec3,
}

@private
debug_drawing : struct {
	// Todo(Leo): these become obsolete once we get debug command buffer on
	// graphics side, but then its is unclear to me what is going on in their
	// dynamic allocations
	draws 		: [dynamic]DrawCall,
	line_draws 	: [dynamic]LineDrawCall,

	sphere_mesh : graphics.Mesh,
	cube_mesh 	: graphics.Mesh,
}

initialize :: proc(capacity : int) {
	dd := &debug_drawing
	dd^ = {}

	// Todo(Leo): allocator
	dd.draws = make([dynamic]DrawCall, 0, 256, context.allocator)
	dd.line_draws = make([dynamic]LineDrawCall, 0, 256, context.allocator)

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
	delete (dd.line_draws)

	graphics.destroy_mesh(&dd.sphere_mesh)
	graphics.destroy_mesh(&dd.cube_mesh)

	dd^ = {}
}

new_frame :: proc() {
	// debug_drawing.count = 0
	resize(&debug_drawing.draws, 0)
	resize(&debug_drawing.line_draws, 0)
}

render :: proc() {
	dd := &debug_drawing

	graphics.setup_wire_pipeline()
	for d in dd.draws {
		// Todo(Leo): not nice to set material every frame, maybe limit palette
		// and sort, but also doesn't really matter (escpecially right now :))
		graphics.draw_wire_mesh(d.mesh, d.model_matrix, d.color)
	}

	graphics.setup_line_pipeline()
	for l in dd.line_draws {
		graphics.draw_line(l.points, l.color)
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

draw_wire_capsule :: proc(position : vec3, up : vec3, radius : f32, height : f32, color : vec3) {
	dd := &debug_drawing

	// up := linalg.mul(rotation, vec3{0, 0, 1})

	h := height / 2 - radius

	m1 := linalg.matrix4_from_trs_f32(position - up * h, quaternion(1), vec3(radius * 2))
	m2 := linalg.matrix4_from_trs_f32(position + up * h, quaternion(1), vec3(radius * 2))

	draw(m1, color, &dd.sphere_mesh)
	draw(m2, color, &dd.sphere_mesh)
}

draw_line :: proc(p0, p1 : vec3, color : vec3) {
	dd := &debug_drawing

	append(&dd.line_draws, LineDrawCall{{p0, p1}, color})
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