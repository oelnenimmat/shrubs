package imgui

// In this file are MORE things that were not in the generator, but also are not
// directly for the api

import "core:c"
import "vendor:glfw"
import vk "vendor:vulkan"

foreign import cimgui "../../lib/cimgui.lib"

ImGui_ImplVulkan_InitInfo :: struct {}

foreign cimgui {

	ImGui_ImplVulkan_Init :: proc (info : ^ImGui_ImplVulkan_InitInfo) -> bool ---
	ImGui_ImplVulkan_Shutdown :: proc () ---
	ImGui_ImplVulkan_NewFrame :: proc () ---
	ImGui_ImplVulkan_RenderDrawData :: proc (draw_data : ^ImDrawData, command_buffer : vk.CommandBuffer, pipeline : vk.Pipeline = 0) ---
	ImGui_ImplVulkan_CreateFontsTexture :: proc () -> bool ---
	ImGui_ImplVulkan_DestroyFontsTexture :: proc () ---
	// ImGui_ImplVulkan_SetMinImageCount :: proc (min_image_count : u32) ---

	ImGui_ImplVulkan_LoadFunctions :: proc(
		loader_func : proc(function_name : cstring, user_data : rawptr) -> vk.ProcVoidFunction,
		user_data : rawptr,
	) ---

	ImGui_ImplGlfw_InitForVulkan :: proc (window : glfw.WindowHandle, install_callbacks : bool) -> bool ---
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

///////////////////////////////////////////////////////////////////////////////
// ImGuizmo

ImGuizmo_MODE :: enum c.int { LOCAL, WORLD }

ImGuizmo_OPERATION :: enum c.int {
	TRANSLATE_X      = 1 << 0,
	TRANSLATE_Y      = 1 << 1,
	TRANSLATE_Z      = 1 << 2,
	ROTATE_X         = 1 << 3,
	ROTATE_Y         = 1 << 4,
	ROTATE_Z         = 1 << 5,
	ROTATE_SCREEN    = 1 << 6,
	SCALE_X          = 1 << 7,
	SCALE_Y          = 1 << 8,
	SCALE_Z          = 1 << 9,
	BOUNDS           = 1 << 10,
	SCALE_XU         = 1 << 11,
	SCALE_YU         = 1 << 12,
	SCALE_ZU         = 1 << 13,

	TRANSLATE 	= TRANSLATE_X | TRANSLATE_Y | TRANSLATE_Z,
	ROTATE 		= ROTATE_X | ROTATE_Y | ROTATE_Z | ROTATE_SCREEN,
	SCALE 		= SCALE_X | SCALE_Y | SCALE_Z,
	SCALEU 		= SCALE_XU | SCALE_YU | SCALE_ZU, // universal
	UNIVERSAL 	= TRANSLATE | ROTATE | SCALEU,
}

@(default_calling_convention = "c")
foreign cimgui {
	ImGuizmo_BeginFrame :: proc() ---
	ImGuizmo_SetDrawlist :: proc(drawlist : ^ImDrawList) ---
	ImGuizmo_Manipulate :: proc(
		view 			: ^mat4,
		projection 		: ^mat4,
		operation 		: ImGuizmo_OPERATION,
		mode 			: ImGuizmo_MODE,
		transform 		: ^mat4,
		delta_transform : ^mat4 = nil,
		snap 			: ^f32 = nil,
		localBounds 	: ^f32 = nil,
		boundsSnap 		: ^f32 = nil,
	) -> c.bool ---
	ImGuizmo_SetRect :: proc(x, y, width, height : f32) ---
}