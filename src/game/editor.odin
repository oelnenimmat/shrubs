package game

import "core:fmt"
import "core:os"
import "core:encoding/json"

EDITOR_STATE_SAVE_FILE_NAME :: "local/editor_state.json"

EditorState :: struct {
	loaded_scene_name : SceneName
}

editor : EditorState

save_editor_state :: proc() {
	data, error := json.marshal(editor)
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
}

