package game

import "shrubs:debug"
import graphics "shrubs:graphics/vulkan"
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
	base_position : vec3,
	base_rotation : vec3,

	boxes : [dynamic]Box,

	material : graphics.BasicMaterial,
}

// Todo(Leo): add allocator
create_greyboxing :: proc() -> Greyboxing {
	g : Greyboxing

	g.material = graphics.create_basic_material(&asset_provider.textures[.Rock])
	g.material.mapped.surface_color = {1, 1, 1, 1}

	// Todo(Leo): no need to do this explicitly now, as we dont have a
	// specific allocator
	// g.boxes = make([dynamic]Box, 0)

	return g
}

destroy_greyboxing :: proc(g : ^Greyboxing) {
	delete (g.boxes)
	graphics.destroy_basic_material(&g.material)

	g^ = {}
}

SerializedGreyboxing :: struct {
	base_position 	: vec3,
	base_rotation 	: vec3,
	boxes 			: []Box,
}

serialize_greyboxing :: proc(g : ^Greyboxing) -> SerializedGreyboxing {
	return { g.base_position, g.base_rotation, g.boxes[:] }
}

@(warning = "whoever passes the serialized pointer needs to delete the memory")
deserialize_greyboxing :: proc(g : ^Greyboxing, s : ^SerializedGreyboxing) {
	g.boxes = make([dynamic]Box, len(s.boxes))
	copy(g.boxes[:], s.boxes)
	g.selection_index = -1

	g.base_position = s.base_position
	g.base_rotation = s.base_rotation
}


render_greyboxing :: proc(g : ^Greyboxing) {

	base_transform := linalg.matrix4_from_trs(
		g.base_position,
		linalg.quaternion_from_euler_angles(g.base_rotation.x, g.base_rotation.y, g.base_rotation.z, .XYZ),
		vec3(1),
	)

	// graphics.set_basic_material({1, 1, 1}, scene.textures[.Rock])
	graphics.set_basic_material(&g.material)
	for b in g.boxes {
		transform := linalg.matrix4_from_trs(
			b.position, 
			linalg.quaternion_from_euler_angles(b.rotation.x, b.rotation.y, b.rotation.z, .XYZ), 
			b.size,
		)
		graphics.draw_mesh(&asset_provider.meshes[.Cube], base_transform * transform)
	}
}

edit_greyboxing :: proc(g : ^Greyboxing) {

	imgui.drag_vec3("base position", &g.base_position, 0.01)
	imgui.drag_vec3("base rotation", &g.base_rotation, 0.01)
	imgui.Separator()

	{
		imgui.input_int("Selection", &g.selection_index)

		// need to loop/clamp selection 
		total_count_including_minus_one := len(g.boxes) + 1
		offset_index 					:= g.selection_index + 1 + total_count_including_minus_one
		offset_index 					%= total_count_including_minus_one
		g.selection_index 				= offset_index - 1
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

		imgui.SameLine()
		if imgui.button("Duplicate") {
			append(&g.boxes, g.boxes[g.selection_index])
			g.selection_index = len(g.boxes) - 1
		}
	}

	imgui.SameLine()
	imgui.text("Count {}", len(g.boxes))

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