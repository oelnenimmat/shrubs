//+private
package input

import "vendor:glfw"

import "../window"

input_keys : [Key] InputKeyState

KeyModifiers :: bit_set[enum {Ctrl, Shift, Alt, AltGr}]
key_modifiers : KeyModifiers

// Todo(Leo): this is called secret, since there is another stupid not secret version of this
// on the public interface
secret_mouse_button_states : [3] InputKeyState

InputKeyState :: enum {
	Is_Up,
	Went_Down,
	Is_Down,
	Went_Up,
}

glfw_key_proc :: proc "c" (window: glfw.WindowHandle, key, scancode, action, mods: i32) {

	input_key := Key.Invalid

	switch key {
	case glfw.KEY_A :		input_key = .A
	case glfw.KEY_B :		input_key = .B
	case glfw.KEY_C :		input_key = .C
	case glfw.KEY_D :		input_key = .D
	case glfw.KEY_E :		input_key = .E
	case glfw.KEY_F :		input_key = .F
	case glfw.KEY_G :		input_key = .G
	case glfw.KEY_H :		input_key = .H
	case glfw.KEY_I :		input_key = .I
	case glfw.KEY_J :		input_key = .J
	case glfw.KEY_K :		input_key = .K
	case glfw.KEY_L :		input_key = .L
	case glfw.KEY_M :		input_key = .M
	case glfw.KEY_N :		input_key = .N
	case glfw.KEY_O :		input_key = .O
	case glfw.KEY_P :		input_key = .P
	case glfw.KEY_Q :		input_key = .Q
	case glfw.KEY_R :		input_key = .R
	case glfw.KEY_S :		input_key = .S
	case glfw.KEY_T :		input_key = .T
	case glfw.KEY_U :		input_key = .U
	case glfw.KEY_V :		input_key = .V
	case glfw.KEY_W :		input_key = .W
	case glfw.KEY_X :		input_key = .X
	case glfw.KEY_Y :		input_key = .Y
	case glfw.KEY_Z :		input_key = .Z
	
	case glfw.KEY_0: 		input_key = ._0
	case glfw.KEY_1: 		input_key = ._1
	case glfw.KEY_2: 		input_key = ._2
	case glfw.KEY_3: 		input_key = ._3
	case glfw.KEY_4: 		input_key = ._4
	case glfw.KEY_5: 		input_key = ._5
	case glfw.KEY_6: 		input_key = ._6
	case glfw.KEY_7: 		input_key = ._7
	case glfw.KEY_8: 		input_key = ._8
	case glfw.KEY_9: 		input_key = ._9
	
	case glfw.KEY_LEFT: 	input_key = .Left
	case glfw.KEY_RIGHT: 	input_key = .Right
	case glfw.KEY_DOWN: 	input_key = .Down
	case glfw.KEY_UP: 		input_key = .Up
	
	case glfw.KEY_ESCAPE: 	input_key = .Escape
	case glfw.KEY_SPACE: 	input_key = .Space
	}

	if input_key != .Invalid {
		state := &input_keys[input_key]
		if action == glfw.PRESS && state^ != .Is_Down {
			state^ = .Went_Down
		}
		if action == glfw.RELEASE && state^ != .Is_Up {
			state^ = .Went_Up
		}
	}


	if (mods & glfw.MOD_ALT) != {} { key_modifiers += {.Alt} }
	if (mods & glfw.MOD_CONTROL) != {} { key_modifiers += {.Ctrl} }
	if (mods & glfw.MOD_SHIFT) != {} { key_modifiers += {.Shift} }
	
}

glfw_mouse_proc :: proc "c" (window: glfw.WindowHandle, button, action, mods: i32) {

	mouse_number := -1

	switch button {
	case glfw.MOUSE_BUTTON_LEFT: 	mouse_number = 0 
	case glfw.MOUSE_BUTTON_RIGHT: 	mouse_number = 1
	case glfw.MOUSE_BUTTON_MIDDLE: 	mouse_number = 2
	}

	if mouse_number != -1 {
		state := &secret_mouse_button_states[mouse_number]
		if action == glfw.PRESS && state^ != .Is_Down {
			state^ = .Went_Down
		}
		if action == glfw.RELEASE && state^ != .Is_Up {
			state^ = .Went_Up
		}
	}
}

glfw_internal_initialize :: proc() {
	glfw.SetKeyCallback(window.get_glfw_window_handle(), glfw_key_proc)
	glfw.SetMouseButtonCallback(window.get_glfw_window_handle(), glfw_mouse_proc)
}

glfw_lock_mouse :: proc(locked : bool) {
	mode := cast(i32) glfw.CURSOR_DISABLED if locked else glfw.CURSOR_NORMAL
	glfw.SetInputMode(window.get_glfw_window_handle(), glfw.CURSOR, mode)
}

glfw_get_mouse_position :: proc() -> [2]i32 {
	window := window.get_glfw_window_handle()
	xPos, yPos := glfw.GetCursorPos(window)
	return [2]i32{i32(xPos), i32(yPos)}
}
