package game

import "shrubs:assets"
import "shrubs:graphics"

import "core:fmt"
import "core:math/linalg"

DEBUG_MAX_DRAW_COUNT :: 256

DEBUG_RED 	:: vec3{0.9, 0.1, 0.1}
DEBUG_GREEN :: vec3{0.1, 0.9, 0.1}
DEBUG_BLUE 	:: vec3{0.1, 0.1, 0.9}

DEBUG_YELLOW :: vec3{0.9, 0.9, 0.1}
DEBUG_BLACK :: vec3{0.1, 0.1, 0.1}

DebugDraw :: struct {
	position : vec3,
	size : f32,
	color : vec3,
}

debug_drawing : struct {
	count 		: int,
	draws 		: []DebugDraw,
	sphere_mesh : graphics.Mesh,
}

initialize_debug_drawing :: proc(capacity : int) {
	dd := &debug_drawing
	dd^ = {}

	dd.count = 0
	dd.draws = make([]DebugDraw, capacity)

	{
		positions, normals, elements := assets.NOT_MEMORY_SAFE_gltf_load_node("assets/shapes.glb", "shape_sphere")
		dd.sphere_mesh = graphics.create_mesh(positions, normals, nil, elements)

		delete(positions)
		delete(normals)
		delete(elements)
	}
}

terminate_debug_drawing :: proc() {
	dd := &debug_drawing

	delete (dd.draws)

	dd^ = {}
}

debug_drawing_new_frame :: proc() {
	debug_drawing.count = 0
}

render_debug_drawing :: proc() {
	dd := &debug_drawing
	
	for draw in dd.draws[0:dd.count] {
		// Todo(Leo): not nice to set material every frame, maybe limit palette
		// and sort, but also doesn't really matter (escpecially right now :))
		graphics.set_debug_line_material(draw.color)
		model_matrix := linalg.matrix4_translate_f32(draw.position) *
						linalg.matrix4_scale_f32(draw.size)
		graphics.draw_debug_mesh(&dd.sphere_mesh, model_matrix)
	}

}

debug_draw_sphere :: proc(position : vec3, size : f32, color : vec3) {
	dd := &debug_drawing

	if dd.count < len(dd.draws) {
		dd.draws[dd.count] = {position, size, color}
		dd.count += 1
	} else {
		fmt.println("[DEBUG]: draw capacity exceeded")
	}
}