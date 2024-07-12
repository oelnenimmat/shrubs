package game

import "shrubs:debug"
import "shrubs:graphics"
import "shrubs:imgui"

import "core:math"
import "core:math/linalg"

Box :: struct {
	position 	: vec3,
	rotation 	: vec3,
	size 		: vec3,
}

Greyboxing :: struct {
	// Todo(Leo): these are not game variables, need to something with that
	// could be that instead of rendering this in the game, we just generate
	// a game rendering thing with this.
	selection_index : int,

	boxes : [dynamic]Box,
}

// Todo(Leo): add allocator
// create_greyboxing :: proc() -> Greyboxing {
// 	g : Greyboxing

// 	// Todo(Leo): no need to do this explicitly now, as we dont have a
// 	// specific allocator
// 	// g.boxes = make([dynamic]Box, 0)

// 	return g
// }

destroy_greyboxing :: proc(g : ^Greyboxing) {
	delete (g.boxes)
	g^ = {}
}

SerializedGreyboxing :: struct {
	boxes : []Box,
}

serialize_greyboxing :: proc(g : ^Greyboxing) -> SerializedGreyboxing {
	return { g.boxes[:] }
}

deserialize_greyboxing :: proc(g : ^Greyboxing, s : ^SerializedGreyboxing) {
	g.boxes = make([dynamic]Box, len(s.boxes))
	copy(g.boxes[:], s.boxes)
	g.selection_index = -1
}


render_greyboxing :: proc(g : ^Greyboxing) {

	graphics.set_basic_material({1, 1, 1}, &DEBUG_rock_texture)
	for b in g.boxes {
		graphics.draw_mesh(&cube_mesh, linalg.matrix4_from_trs(
			b.position, 
			linalg.quaternion_from_euler_angles(b.rotation.x, b.rotation.y, b.rotation.z, .XYZ), 
			b.size
		))
	}
}

edit_greyboxing :: proc(g : ^Greyboxing) {

	{
		imgui.input_int("Selection", &g.selection_index)

		// need to loop/clamp selection 
		g.selection_index = ((g.selection_index + 1) % (len(g.boxes) + 1)) - 1
	}
	
	if imgui.button("Add") {
		append(&g.boxes, Box{vec3(0), vec3(0), vec3(1)})
		g.selection_index = len(g.boxes) - 1
	}
	if g.selection_index >= 0 {
		imgui.SameLine()
		if imgui.button("Delete") {
			unordered_remove(&g.boxes, g.selection_index)
			g.selection_index = -1
		}
	}

	if g.selection_index >= 0 {
		b := &g.boxes[g.selection_index]
		imgui.drag_vec3("position", &b.position, 0.01)
		imgui.drag_vec3("rotation", &b.rotation, 0.01)
		imgui.drag_vec3("size", &b.size, 0.01)

		editor_gizmo_transform(&b.position, &b.rotation, &b.size)

		debug.draw_wire_cube(
			b.position, 
			linalg.quaternion_from_euler_angles(b.rotation.x, b.rotation.y, b.rotation.z, .XYZ), 
			b.size,
			debug.BRIGHT_PURPLE,
		)
	}
}