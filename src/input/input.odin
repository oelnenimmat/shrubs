/*
Todo(Leo): All get input functions are now DEBUG, as I'm not yet ready to make 
proper decisions. These might work fine, and we will see that in time, but
these are now reminding that this still needs more thought, and the usage
code is also aware of this.

Also, might be that we need to some sort of click counting or whatever, time
will tell :)
*/

package input

import "shrubs:common"
import "shrubs:window"

import "core:fmt"

vec2 :: common.vec2
vec3 :: common.vec3

Key :: enum {
	Invalid = 0,

	A, B, C, D, E, F, G,
	H, I, J, K, L, M, N,
	O, P, Q, R, S, T, U,
	V, W, X, Y, Z,

	_0, _1, _2, _3, _4, _5, _6, _7, _8, _9,

	Left, Right, Down, Up,

	Escape, Space,
}


DEBUG_get_key_axis :: proc(negative, positive : Key) -> f32 {
	return f32(
		cast(int)DEBUG_get_key_held(positive) - 
		cast(int)DEBUG_get_key_held(negative)
	)
}

// Todo(Leo): I'm a little hesitant on "pressed", as it might mean to
// someone (like me) that the key is being pressed down longterm, what
// held is supposed to be, but this should be clear enough in the context.
DEBUG_get_key_pressed :: proc(key: Key, mods: KeyModifiers = {}) -> bool {
	went_down 	:= input_keys[key] == .Went_Down
	mods_agree 	:= (mods & key_modifiers) == mods

	return went_down && mods_agree
}

DEBUG_get_key_held :: proc(key: Key, mods: KeyModifiers = {}) -> bool {
	state 		:= input_keys[key]
	is_down 	:= state == .Is_Down || state == .Went_Down
	mods_agree 	:= (mods & key_modifiers) == mods

	return is_down && mods_agree
}

DEBUG_get_key_released :: proc(key: Key, mods: KeyModifiers = {}) -> bool {
	went_up 	:= input_keys[key] == .Went_Up
	mods_agree 	:= (mods & key_modifiers) == mods

	return went_up && mods_agree
}

DEBUG_get_mouse_movement :: proc(axis : int) -> f32 {
	assert(axis == 0 || axis == 1)
	return mouse.movement[axis]
}

DEBUG_get_mouse_position :: proc(axis : int) -> f32 {
	assert(axis == 0 || axis == 1)
	return mouse.position[axis]
}

// Todo(Leo): I'm a little hesitant on "pressed", as it might mean to
// someone (like me) that the key is being pressed down longterm, what
// held is supposed to be, but this should be clear enough in the context.
DEBUG_get_mouse_button_pressed :: proc(button : int) -> bool {
	button_state := mouse.button_states[button]
	return button_state == .Went_Down
}

DEBUG_get_mouse_button_held :: proc(button : int) -> bool {
	button_state := mouse.button_states[button]
	return button_state == .Is_Down || button_state == .Went_Down
}

DEBUG_get_mouse_button_released :: proc(button : int) -> bool {
	button_state := mouse.button_states[button]
	return button_state == .Went_Up 	
}

@private
mouse : struct {
	position : vec2,
	movement : vec2,
	button_states : [3]InputKeyState,
	locked : bool
}

initialize :: proc() {
	glfw_internal_initialize()

	mouse.locked = true
	glfw_lock_mouse(mouse.locked)

	initial_mouse_position := glfw_get_mouse_position()
	mouse.position = {f32(initial_mouse_position.x), f32(initial_mouse_position.y)}
}

terminate :: proc() { /* Nothing now, but add here if needed :) */ }

begin_frame :: proc() {

	// DEVELOPER MODE??? ------------------------------------------------------
	if DEBUG_get_key_pressed(.Escape) {
		mouse.locked = !mouse.locked
		glfw_lock_mouse(mouse.locked)
		mouse.movement = {0, 0}

		mouse_position := glfw_get_mouse_position()
		mouse.position = {f32(mouse_position.x), f32(mouse_position.y)}
	}

	// MOUSE ------------------------------------------------------------------
	new_mouse_position := glfw_get_mouse_position()
	mouse.movement.x = f32(new_mouse_position.x) - mouse.position.x 
	mouse.movement.y = f32(new_mouse_position.y) - mouse.position.y 
	mouse.position = {f32(new_mouse_position.x), f32(new_mouse_position.y)}

	mouse.button_states = secret_mouse_button_states
}

end_frame :: proc() {

	// Before polling for new events, we must advance "Went_X" key states from
	// previous frame to "Is_X" state
	for _, i in input_keys {
		#partial switch input_keys[i] {
			case .Went_Down: 	input_keys[i] = .Is_Down
			case .Went_Up: 		input_keys[i] = .Is_Up
		}
	}

	for _, i in secret_mouse_button_states {
		#partial switch secret_mouse_button_states[i] {
			case .Went_Down: 	secret_mouse_button_states[i] = .Is_Down
			case .Went_Up: 		secret_mouse_button_states[i] = .Is_Up
		}
	}

	key_modifiers = {}
}