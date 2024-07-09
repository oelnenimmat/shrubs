package imgui

// In this file are MORE things that were not in the generator, but also are not
// directly for the api

import "vendor:glfw"

foreign import cimgui "../../lib/cimgui.lib"

foreign cimgui {
	ImGui_ImplOpenGL3_Init :: proc (glsl_version : cstring = nil) -> bool ---
	ImGui_ImplOpenGL3_Shutdown :: proc () ---
	ImGui_ImplOpenGL3_NewFrame :: proc () ---
	ImGui_ImplOpenGL3_RenderDrawData :: proc (draw_data : ^ImDrawData) ---

	ImGui_ImplGlfw_InitForOpenGL :: proc (window : glfw.WindowHandle, install_callbacks : bool) -> bool ---
	ImGui_ImplGlfw_Shutdown :: proc () ---
	ImGui_ImplGlfw_NewFrame :: proc () ---
}

ImVector :: struct($T : typeid) {
	Size : i32,
	Capacity : i32,
	Data : ^T,
}

ImS8    :: distinct i8
ImU8    :: distinct u8
ImS16   :: distinct i16
ImU16   :: distinct u16
ImS32   :: distinct i32
ImU32   :: distinct u32
ImS64   :: distinct i64
ImU64   :: distinct u64

ImWchar16   :: distinct u16
ImWchar32   :: distinct u32
ImWchar     :: ImWchar16

ImTextureID :: distinct rawptr
ImDrawIdx   :: distinct u16

// todo(Leo): maybe generate from cimgui typedefs json
ImGuiID :: distinct i32

// Some typedefs
ImDrawCallback 			:: proc(parent_list : ^ImDrawList, cmd : ^ImDrawCmd) // this' signature can be changed, together with the backends'(backend calls this)
ImGuiSizeCallback 		:: proc(data : ^ImGuiSizeCallbackData)
ImGuiInputTextCallback 	:: proc(data : ^ImGuiInputTextCallbackData) -> i32
ImGuiMemAllocFunc 		:: proc(size : u64, user_data : rawptr) -> rawptr
ImGuiMemFreeFunc 		:: proc(ptr : rawptr, user_data : rawptr)

// Opaque handles I guess. 
ImGuiContext :: struct {}
ImFontBuilderIO :: struct {}
ImDrawListSharedData :: struct {}

// These are only used as a pointer type with ImVector, so should be okay
ImGuiStoragePair :: struct {}

ImGuiKeyChord :: distinct i32 //ImGuiModFlags