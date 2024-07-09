package imgui

import "base:intrinsics"

import "core:fmt"
import "core:reflect"
import "core:strings"

import "vendor:glfw"

///////////////////////////////////////////////////////////////////////////////
/// Maintenance API

initialize :: proc(window : glfw.WindowHandle) {
	imgui_context := CreateContext(nil)
	SetCurrentContext(imgui_context)
	StyleColorsDark(nil)

	ImGui_ImplGlfw_InitForOpenGL(window, true)
	ImGui_ImplOpenGL3_Init()
}

terminate :: proc() {
	ImGui_ImplGlfw_Shutdown()
	ImGui_ImplOpenGL3_Shutdown()

	DestroyContext(nil)
}

begin_frame :: proc() {
	ImGui_ImplGlfw_NewFrame()
	ImGui_ImplOpenGL3_NewFrame()
	NewFrame()
}

end_frame :: proc() {
	EndFrame()
}

render :: proc () {
	Render()

	ImGui_ImplOpenGL3_RenderDrawData(GetDrawData())
}

///////////////////////////////////////////////////////////////////////////////
/// Usage API

text :: proc(format : string, stuff : ..any) {
	// todo(Leo): use imgui specific allocator
	// thoguh, why? becuse context temp allocator may be used by game and imgui is not supposed to ship
	// so it may introduce weirdlings
	builder := strings.builder_make(context.temp_allocator)
	fmt.sbprintf(&builder, format, ..stuff)
	append(&builder.buf, 0) // append just something so we can take last actual characters address with indexing

	start 	:= transmute(cstring) &builder.buf[0]
	end 	:= transmute(cstring) &builder.buf[len(builder.buf) - 1]

	// Todo(Leo): TextUnformatted actually should take ^u8 or [^]u8 instead of cstring. its same, but different
	// the generator needs to be changed for this
	TextUnformatted(start, end)
}

button :: proc(label : string, size := ImVec2{0, 0}) -> bool {
	label := as_u8_array(label, 32)
	return cast(bool) Button(cstring(&label[0]), size)
}

checkbox :: proc(label : string, value : ^bool) -> bool {
	value_b8 	:= b8(value^)
	label 		:= as_u8_array(label, 32)
	result 		:= cast(bool) Checkbox(cstring(&label[0]), &value_b8)
	value^ 		= bool(value_b8)
	return result
}

enum_dropdown :: proc(label : string, v : ^$T) -> bool where intrinsics.type_is_enum(T) {
	label := as_u8_array(label, 32)
	selected_name := as_u8_array(reflect.enum_string(v^), 32)

	edited := false

	if BeginCombo(cstring(&label[0]), cstring(&selected_name[0])) {
		for value in T {
			current_name := as_u8_array(reflect.enum_string(value), 32)

			if Selectable(cstring(&current_name[0]), value == v^) {
				v^ = value
				edited = true
			}
		}
		EndCombo()
	}

	return edited
} 

///////////////////////////////////////////////////////////////////////////////
// Internal helpers

@private
as_u8_array :: proc(s : string, $size : int) -> [size]u8 {
	out 		:= [size]u8 {}
	s_u8 		:= transmute([]u8)s
	copy_len 	:= min(size - 1, len(s_u8))
	copy(out[:copy_len], s_u8[:copy_len])

	return out
}