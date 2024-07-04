/*
This file implements basic window handling functions isolating the 3rd party
glfw implementation from the actual application.

As per convention: use 'initialize' in startup and 'terminate' in closedown

Instead of regular 'update', call 'begin_frame' at the beginning and 
'end_frame' at the end of a frame (single application loop).
*/
package window

import "core:fmt"
import "core:strings"

import "vendor:glfw"

@private
window_handle : glfw.WindowHandle

// PLATFORM AGNOSTIC INTERFACE -------------------------------

initialize :: proc(width, height: int, application_name: string) {
	inited_succesfully := cast(bool) glfw.Init()
	assert(inited_succesfully)

	application_name_cstring := strings.clone_to_cstring(application_name)
	defer delete(application_name_cstring)

	glfw.WindowHint(glfw.SAMPLES, 4)
	window_handle = glfw.CreateWindow(i32(width), i32(height), application_name_cstring, nil, nil)
	assert(window_handle != nil)

	glfw.MakeContextCurrent(window_handle)

	// Create window with small size, and then maximize so we get nice
	// big screen but also if need to see the underlying console there
	// is reasonable sized window to restore to with windows hotkeys quickly
	glfw.MaximizeWindow(window_handle)
}

terminate :: proc() {
	glfw.DestroyWindow(window_handle)
	glfw.Terminate()
}

begin_frame :: proc() {
	glfw.PollEvents()
}

end_frame :: proc() {
	glfw.SwapBuffers(window_handle)
}

get_window_size :: proc() -> (width, height: int) {
	w, h := glfw.GetWindowSize(window_handle)
	return int(w), int(h)
}

should_close :: proc() -> bool {
	return cast(bool) glfw.WindowShouldClose(window_handle)
}

// PLATFORM SPECIFIC INTERFACE -------------------------------

get_glfw_window_handle :: proc() -> glfw.WindowHandle {
	return window_handle
}