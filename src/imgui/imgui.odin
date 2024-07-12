package imgui

import "base:intrinsics"

import "core:fmt"
import "core:math/linalg"
import "core:reflect"
import "core:strings"

import "vendor:glfw"

import "shrubs:common"

vec2 :: common.vec2
vec3 :: common.vec3
vec4 :: common.vec4
quaternion :: common.quaternion

mat3 :: common.mat3
mat4 :: common.mat4

///////////////////////////////////////////////////////////////////////////////
/// Maintenance API

@private projection_matrix : mat4
@private view_matrix : mat4

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

begin_frame :: proc(projection, view : mat4) {
	ImGui_ImplGlfw_NewFrame()
	ImGui_ImplOpenGL3_NewFrame()
	NewFrame()

	ImGuizmo_BeginFrame()

	io := GetIO()
	ImGuizmo_SetRect(0, 0, io.DisplaySize.x, io.DisplaySize.y)

	projection_matrix 	= projection
	view_matrix 		= view
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
	label := to_u8_array(label, 32)
	return cast(bool) Button(cstring(&label[0]), size)
}

checkbox :: proc(label : string, value : ^bool) -> bool {
	value_b8 	:= b8(value^)
	label 		:= to_u8_array(label, 32)
	result 		:= cast(bool) Checkbox(cstring(&label[0]), &value_b8)
	value^ 		= bool(value_b8)
	return result
}

enum_dropdown :: proc(label : string, v : ^$T) -> bool where intrinsics.type_is_enum(T) {
	label := to_u8_array(label, 32)
	selected_name := to_u8_array(reflect.enum_string(v^), 32)

	edited := false

	if BeginCombo(cstring(&label[0]), cstring(&selected_name[0])) {
		for value in T {
			current_name := to_u8_array(reflect.enum_string(value), 32)

			if Selectable(cstring(&current_name[0]), value == v^) {
				v^ = value
				edited = true
			}
		}
		EndCombo()
	}

	return edited
} 

input_int :: proc(label : string, v : ^int, step := 1, step_fast := 100, flags := ImGuiInputTextFlags(0)) -> bool {
	label := to_u8_array(label, 32)

	v_i32 	:= i32(v^)
	edited 	:= cast(bool) InputInt(cstring(&label[0]), &v_i32, i32(step), i32(step_fast), flags)
	v^ 		= int(v_i32)

	return edited
}

drag_vec3 :: proc(label : string, v : ^vec3, v_speed := f32(1.0), v_min := f32(0.0), v_max := f32(0.0), format := cstring("%.3f"), flags := ImGuiSliderFlags{}) -> bool {
	label := to_u8_array(label, 32)
	return cast(bool) DragFloat3(cstring(&label[0]), cast(^f32)v, v_speed, v_min, v_max, format, flags)
}

///////////////////////////////////////////////////////////////////////////////
// Gizmos

translate_gizmo :: proc(position : ^vec3, rotation : quaternion, mode : ImGuizmo_MODE) {
	mat := linalg.matrix4_from_trs(position^, rotation, 1)
	ImGuizmo_Manipulate(
		cast(^f32) &view_matrix,
		cast(^f32) &projection_matrix,
		.TRANSLATE,
		mode,
		cast(^f32) &mat,
	)
	// luckily works like this :)
	position^ = mat[3].xyz
}

rotate_gizmo :: proc(rotation : ^quaternion, position : vec3, mode : ImGuizmo_MODE) {
	mat := linalg.matrix4_from_trs(position, rotation^, 1)
	ImGuizmo_Manipulate(
		cast(^f32) &view_matrix,
		cast(^f32) &projection_matrix,
		.ROTATE, //.ROTATE_X | .ROTATE_Z,
		mode,
		cast(^f32) &mat,
	)
	rotation^ = linalg.quaternion_from_matrix4(mat)
	rotation^ = linalg.quaternion_normalize(rotation^)
}

///////////////////////////////////////////////////////////////////////////////
// Internal helpers

@private
to_u8_array :: proc(s : string, $size : int) -> [size]u8 {
	out 		:= [size]u8 {}
	s_u8 		:= transmute([]u8)s
	copy_len 	:= min(size - 1, len(s_u8))
	copy(out[:copy_len], s_u8[:copy_len])

	return out
}