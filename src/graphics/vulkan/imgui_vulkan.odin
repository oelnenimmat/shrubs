package graphics

import vk "vendor:vulkan"

ImGui_ImplVulkan_InitInfo :: struct {
	Instance : vk.Instance,
	PhysicalDevice : vk.PhysicalDevice,
	Device : vk.Device,
	QueueFamily : u32,
	Queue : vk.Queue,
	DescriptorPool : vk.DescriptorPool,
	RenderPass : vk.RenderPass,
	MinImageCount : u32,
	ImageCount : u32,
	MSAASamples : vk.SampleCountFlags,

	// (Optional)
	PipelineCache : vk.PipelineCache,
	Subpass : u32,

	// (Optional) Dynamic Rendering
	// Need to explicitly enable VK_KHR_dynamic_rendering extension to use this, even for Vulkan 1.3.
	UseDynamicRendering : b32,
// This is enabled if vulkan is 1.3, which it is
// #ifdef IMGUI_IMPL_VULKAN_HAS_DYNAMIC_RENDERING
	PipelineRenderingCreateInfo : vk.PipelineRenderingCreateInfoKHR,
// #endif

	Allocator : ^vk.AllocationCallbacks,
	CheckVkResultFn : proc "c" (err : vk.Result),
	
	// Minimum allocation size. Set to 1024*1024 to satisfy zealous best practices validation layer and waste a little memory.
	MinAllocationSize : vk.DeviceSize,
}

get_imgui_init_info :: proc() -> ImGui_ImplVulkan_InitInfo {
	g := &graphics

	swapchain_image_count := u32(len(g.swapchain_images))
	info := ImGui_ImplVulkan_InitInfo {
		Instance 		= g.instance,
		PhysicalDevice 	= g.physical_device,
		Device 			= g.device,
		QueueFamily 	= g.graphics_queue_family,
		Queue 			= g.graphics_queue,
		DescriptorPool 	= g.descriptor_pool,
		RenderPass 		= g.test_render_pass,
		MinImageCount 	= swapchain_image_count,
		ImageCount 		= swapchain_image_count,
		MSAASamples 	= {._1},

		PipelineCache = VK_NULL_HANDLE,
		Subpass = 0,

		UseDynamicRendering = false,

		Allocator 			= nil,
		CheckVkResultFn 	= nil,
		MinAllocationSize 	= 1024 * 1024
	}

	return info
}

get_imgui_command_buffer :: proc() -> vk.CommandBuffer {
	g := &graphics
	return g.main_command_buffers[g.virtual_frame_index]
}