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

value_int :: proc(label : string, v : int) {
	label := to_u8_array(label, 32)
	Value(cstring(&label[0]), i32(v))
}

value_f32 :: proc(label : string, v : f32) {
	label := to_u8_array(label, 32)
	Value(cstring(&label[0]), v)
}

value_bool :: proc(label : string, v : bool) {
	text("{}: {}", label, "true" if v else "false")
}

value_vec3 :: proc(label : string, v : vec3) {
	text("{}: ({:.3f}, {:.3f}, {:.3f})", label, v.x, v.y, v.z)
}

value :: proc {
	value_int,
	value_f32,
	value_bool,
	value_vec3,
}

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

slice_dropdown :: proc(label : string, selection : ^int, options : []string) -> bool {
	label := to_u8_array(label, 32)
	selected_name := to_u8_array(options[selection^], 32)

	edited := false

	if BeginCombo(cstring(&label[0]), cstring(&selected_name[0])) {
		for option, index in options {
			current_name := to_u8_array(option, 32)

			if Selectable(cstring(&current_name[0]), index == selection^) {
				selection^ = index
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

drag_vec2 :: proc(label : string, v : ^vec2, v_speed := f32(0.01), v_min := f32(0.0), v_max := f32(0.0), format := cstring("%.3f"), flags := ImGuiSliderFlags{}) -> bool {
	label := to_u8_array(label, 32)
	return cast(bool) DragFloat2(cstring(&label[0]), cast(^f32)v, v_speed, v_min, v_max, format, flags)
}

drag_vec3 :: proc(label : string, v : ^vec3, v_speed := f32(0.01), v_min := f32(0.0), v_max := f32(0.0), format := cstring("%.3f"), flags := ImGuiSliderFlags{}) -> bool {
	label := to_u8_array(label, 32)
	return cast(bool) DragFloat3(cstring(&label[0]), cast(^f32)v, v_speed, v_min, v_max, format, flags)
}

///////////////////////////////////////////////////////////////////////////////
// Gizmos
// Todo(Leo): seems like these are only used from/in the editor, maybe could be moved there?

translate_gizmo :: proc(position : ^vec3, rotation : quaternion, mode : ImGuizmo_MODE) {
	mat := linalg.matrix4_from_trs(position^, rotation, 1)
	ImGuizmo_Manipulate(
		&view_matrix,
		&projection_matrix,
		.TRANSLATE,
		mode,
		&mat,
	)
	// luckily works like this :)
	position^ = mat[3].xyz
}

rotate_gizmo :: proc(rotation : ^quaternion, position : vec3, mode : ImGuizmo_MODE) {
	mat := linalg.matrix4_from_trs(position, rotation^, 1)
	ImGuizmo_Manipulate(
		&view_matrix,
		&projection_matrix,
		.ROTATE_X | .ROTATE_Y | .ROTATE_Z,
		mode,
		&mat,
	)
	rotation^ = linalg.quaternion_from_matrix4(mat)
	rotation^ = linalg.quaternion_normalize(rotation^)
}

size_gizmo :: proc(size : ^vec3, position : vec3, rotation : quaternion) {
	mat := linalg.matrix4_from_trs(position, rotation, size^)
	ImGuizmo_Manipulate(
		&view_matrix,
		&projection_matrix,
		.SCALE,
		.LOCAL,
		&mat,
	)

	// T * R * S = mat
	// --> R^-1 * T^-1 * T * R * S = R^-1 * T^-1 * mat
	// --> S = R^-1 * T^-1 * mat
	T_inverse := linalg.inverse(linalg.matrix4_translate_f32(position))
	R_inverse := linalg.inverse(linalg.matrix4_from_quaternion(rotation))

	S := R_inverse * T_inverse * mat
	size^ = {S[0,0], S[1,1], S[2,2]}
}

///////////////////////////////////////////////////////////////////////////////
// Internal helpers

// Todo(Leo): do an arena allocator for this instead
// Copies the string to a stack variable, preserving a one character for the null
// terminator for imgui c++ calls
@private
to_u8_array :: proc(s : string, $size : int) -> [size]u8 {
	out 		:= [size]u8 {}
	s_u8 		:= transmute([]u8)s
	copy_len 	:= min(size - 1, len(s_u8))
	copy(out[:copy_len], s_u8[:copy_len])

	return out
}