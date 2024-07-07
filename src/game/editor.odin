package game

import "core:fmt"
import "core:os"
import "core:encoding/json"
import "core:math/linalg"

import "shrubs:input"

EDITOR_STATE_SAVE_FILE_NAME :: "local/editor_state.json"
EDITOR_CAMERA_MOVE_SPEED :: 6

EditorMode :: enum { ClickyClicky, FlyView }

editor : struct {
	loaded_scene_name : SceneName,

	mode : EditorMode,

	// Odin team has problem with quaternions, so we need to
	// serialize camera rotation with direction vectors 
	camera_view_forward : vec3,
	camera_view_up 		: vec3,
	camera_position 	: vec3,

	// Todo(Leo): definetly not here, but this was easiest to serialize
	exposure : f32,
}

save_editor_state :: proc() {
	data, error := json.marshal(editor, opt = { pretty = true })
	defer delete(data)
	if error == nil {
		fmt.println("Editor state saved")
		fmt.println(string(data))
		os.write_entire_file(EDITOR_STATE_SAVE_FILE_NAME, data)
	} else {
		fmt.println("[EDITOR SAVE ERROR]:", error)
	}

}

load_editor_state :: proc() {
	data, success := os.read_entire_file(EDITOR_STATE_SAVE_FILE_NAME)
	if success {
		json.unmarshal(data, &editor)
	} else {
		fmt.println("Editor file did not exist or smth, creating new one next time application is closed.")
	}

	fmt.println("Editor state loaded")


	// Lets just always start in this to lessen nausea
	editor.mode = .ClickyClicky

	// Make sure that variables have reasonable values
	{
		using linalg

		if abs(length(editor.camera_view_forward) - 1) > 0.001 {
			editor.camera_view_forward = OBJECT_FORWARD
		}

		if abs(length(editor.camera_view_up) - 1) > 0.001 {
			editor.camera_view_up = OBJECT_UP
		}
	}
}

update_editor_camera :: proc(camera : ^Camera, delta_time : f32) {
	if input.DEBUG_get_key_pressed(.Tab) {
		editor.mode = .FlyView if editor.mode == .ClickyClicky else .ClickyClicky

		input.lock_mouse(editor.mode == .FlyView)
	}

	// Camera gets sometimes annoingly tilted, this is the siml
	if input.DEBUG_get_key_pressed(.R, {.Ctrl}) {
		editor.camera_view_forward = OBJECT_FORWARD
		editor.camera_view_up = OBJECT_UP
	}

	if editor.mode == .FlyView {

		// Gather input
		move := vec3 {
			input.DEBUG_get_key_axis(.A, .D),
			input.DEBUG_get_key_axis(.S, .W),
			input.DEBUG_get_key_axis(.F, .R),
		}	

		look := vec2{
			input.DEBUG_get_mouse_movement(0) * 0.005,
			input.DEBUG_get_mouse_movement(1) * 0.005,
		}

		using linalg

		forward := editor.camera_view_forward
		up 		:= editor.camera_view_up
		right 	:= normalize(cross(forward, up))


		// Todo(Leo): for now we have flat plane as a world, but this will prob
		// change. To move along the plane, we need to know what is the local
		// up at that point of the world.
		world_local_up := OBJECT_UP

		pan 	:= quaternion_angle_axis_f32(-look.x, world_local_up)
		tilt 	:= quaternion_angle_axis_f32(-look.y, right)

		editor.camera_view_forward = normalize(mul(pan * tilt, forward))
		editor.camera_view_up = normalize(mul(pan * tilt, up))
		
		movement := right * move.x + forward * move.y + world_local_up * move.z
		editor.camera_position += movement * EDITOR_CAMERA_MOVE_SPEED * delta_time
	}

	// Camera position needs to be set regardless of editor mode
	{
		using linalg

		forward := editor.camera_view_forward
		up 		:= editor.camera_view_up
		right 	:= normalize(cross(forward, up))


		r := right
		f := forward
		u := up
		m := mat4{
			r.x, f.x, u.x, 0,
			r.y, f.y, u.y, 0,
			r.z, f.z, u.z, 0,
			0, 0, 0, 1,
		}
		
		camera.position = editor.camera_position
		camera.rotation = quaternion_from_matrix4(m)
	}

}