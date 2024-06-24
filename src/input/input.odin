/*
Input filter system. All raw input from platform such as keyboard and mouse are filtered
here so that the task of managing overlapping input needs becomes easier. Also,
now we can from here support different input profiles, and whoever uses said input
can focus on doing what it has to do.

Todo(Leo): maybe its not so easy to draw line between system and its input filtering, so
more thought needs to be spend on this.
*/

package input

import "../common"
import "../window"

import "core:fmt"

vec2 :: common.vec2
vec3 :: common.vec3

// INPUT STRUCTS ------------------------------------------
/*
Use these structs to read input. They can technically be written outside, but no
reason to do so. As more systems come to be, add new ones here and in 'update' make
sure that any overlapping keybindings make sense.
*/

/*
Todo(Leo):
There is a structural issue here that this file tries to be two separate things at once
 a) generic input interface
 b) higher level input filter
Please, pick one
 a) simpler and more flexible, but easy to double use some inputs for different things at same time
 b) more structured but not too easy to do quick fixes

camera and playback below belongs to group b) and mouse to group a)
*/

camera : struct {
	move : vec3,
	look : vec2,
	reset : bool,
}

mouse : struct {
	position : vec2,
	movement : vec2,
	button_states : [3]InputKeyState,
	locked : bool
}

// CONTROL INTERFACE --------------------------------------

initialize :: proc() {
	_internal_initialize()

	mouse.locked = true
	lock_mouse(mouse.locked)

	initial_mouse_position := get_mouse_position()
	mouse.position = {f32(initial_mouse_position.x), f32(initial_mouse_position.y)}
}

terminate :: proc() { /* Nothing now, but add here if needed :) */ }

update :: proc() {

	// DEVELOPER MODE??? ------------------------------------------------------
	if key_went_down(.Escape) {
		mouse.locked = !mouse.locked
		lock_mouse(mouse.locked)
		mouse.movement = {0, 0}

		mouse_position := get_mouse_position()
		mouse.position = {f32(mouse_position.x), f32(mouse_position.y)}
	}

	// MOUSE ------------------------------------------------------------------
	new_mouse_position := get_mouse_position()
	mouse.movement.x = f32(new_mouse_position.x) - mouse.position.x 
	mouse.movement.y = f32(new_mouse_position.y) - mouse.position.y 
	mouse.position = {f32(new_mouse_position.x), f32(new_mouse_position.y)}

	mouse.button_states = secret_mouse_button_states


	// APPLICATION EVENTS -----------------------------------------------------
	events.application.exit = key_went_down_mods(.Q, {.Ctrl})


	// CAMERA -----------------------------------------------------------------
	/*
	Shortly:
		- positive x to right
		- positive y to up
		- negative z to forward
	*/

	left_down 		:= key_is_down(.A) || key_is_down(.Left)
	right_down 		:= key_is_down(.D) || key_is_down(.Right)

	back_down 		:= key_is_down(.S) || key_is_down(.Down)
	forward_down 	:= key_is_down(.W) || key_is_down(.Up)

	down_down 		:= key_is_down(.F)
	up_down 		:= key_is_down(.R)


	look_left_right := mouse.movement.x * 0.005
	look_down_up := mouse.movement.y * 0.005

	camera = {
		move = {
			axis_value_from_bool(left_down, right_down),
			axis_value_from_bool(back_down, forward_down),
			axis_value_from_bool(down_down, up_down),
		},
		look = { look_left_right, look_down_up },
		reset = key_went_down_mods(.R, {.Ctrl}),
	}


	// ------------------------------------------------------------------------

	// Input is used for this frame, reset.
	// todo(leo): does not work really :)
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

mouse_button_went_down :: proc(button : int) -> bool {
	button_state := mouse.button_states[button]
	return button_state == .Went_Down
}

mouse_button_is_down :: proc(button : int) -> bool {
	button_state := mouse.button_states[button]
	return button_state == .Is_Down || button_state == .Went_Down
}

mouse_button_went_up :: proc(button : int) -> bool {
	button_state := mouse.button_states[button]
	return button_state == .Went_Up 	
}

// HELPERS ------------------------------------------------

@private
axis_value_from_bool :: proc(negative, positive: bool) -> f32 {
	return f32(cast(int)positive - cast(int)negative)
}