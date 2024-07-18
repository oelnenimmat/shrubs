// https://www.glfw.org/docs/3.3/vulkan_guide.html

package graphics

// todo(Leo): is this the best way? or the most proper?
// handle types are defined as distinct u64 in "vendor:vulkan"
// this needs to be untyped, so it will automatically cast to right type when used (like #defines)
// also notice, that this is not in fact in the "vendor:vulkan"
VK_NULL_HANDLE :: 0
VK_FALSE :: false
VK_TRUE :: true

import "shrubs:common"
import "shrubs:window"

vec2 :: common.vec2
vec3 :: common.vec3
vec4 :: common.vec4
mat4 :: common.mat4

import vk "vendor:vulkan"
// Todo(Leo): maybe not noce, try to move this to window.odin, might be bad to
// bypass those procedures there
import "vendor:glfw"

import "core:fmt"
import "core:os"
import "core:runtime"

VIRTUAL_FRAME_COUNT :: 3

@private
graphics : struct {
	// use this to allocate all slices in here, maybe even this struct itself down the line
	allocator : runtime.Allocator,

	virtual_frame_index : int,

	instance 		: vk.Instance,
	debug_messenger : vk.DebugUtilsMessengerEXT,
	surface 		: vk.SurfaceKHR,
	physical_device : vk.PhysicalDevice,
	device 			: vk.Device,

	swapchain 				: vk.SwapchainKHR,
	swapchain_images 		: []vk.Image,
	swapchain_image_views 	: []vk.ImageView,
	swapchain_framebuffers 	: []vk.Framebuffer,
	swapchain_image_format 	: vk.Format,
	swapchain_image_extent 	: vk.Extent2D,

	graphics_queue_family : u32,
	present_queue_family : u32,
	compute_queue_family : u32,

	graphics_queue : vk.Queue,
	present_queue : vk.Queue,
	compute_queue : vk.Queue,

	// graphics_command_pool : vk.CommandPool,
	// compute_command_pool : vk.CommandPool,
	// Todo(Leo): trying this out
	command_pools : [enum {
		Graphics,
		Compute
	}]vk.CommandPool,

	main_command_buffers : [VIRTUAL_FRAME_COUNT]vk.CommandBuffer,

	virtual_frame_in_use_fences : [VIRTUAL_FRAME_COUNT]vk.Fence,
	// Todo(Leo): one for grass compute etc :)
	rendering_complete_semaphores : [VIRTUAL_FRAME_COUNT]vk.Semaphore,
	present_complete_semaphores : [VIRTUAL_FRAME_COUNT]vk.Semaphore,

	test_pipeline_layout 	: vk.PipelineLayout,
	test_pipeline 			: vk.Pipeline,
	test_render_pass 		: vk.RenderPass,

}


@private
handle_result :: proc(result : vk.Result, loc := #caller_location) {
	if result != .SUCCESS {
		fmt.printf("VULKAN ERROR: {}\n", result)
		panic("Vulkan Error :(", loc)
	}
}

initialize :: proc() {
	assert(bool(glfw.VulkanSupported()))
	fmt.println("Vulkan supported, yay! :)")

	// Todo(Leo): not :)
	graphics.allocator = context.allocator

	vk.load_proc_addresses_global(rawptr(glfw.GetInstanceProcAddress))

	// ----- DEBUG INFO (used as such already in instance creation) ----------

	debug_message_handler :: proc "stdcall" (
		messageSeverity : vk.DebugUtilsMessageSeverityFlagsEXT,
		messageTypes 	: vk.DebugUtilsMessageTypeFlagsEXT,
		pCallbackData 	: ^vk.DebugUtilsMessengerCallbackDataEXT,
		pUserData 		: rawptr,
	) -> b32 {
		context = runtime.default_context()
		fmt.println(pCallbackData.pMessage)

		return false
	}

	debug_utils_messenger_create_info := vk.DebugUtilsMessengerCreateInfoEXT {
		sType 			= .DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT,
		pNext 			= nil,
		flags 			= {},
		messageSeverity = {.ERROR, .WARNING, /* .INFO, .VERBOSE */ },
		messageType 	= {/* .PERFORMANCE, */ .VALIDATION, /* .GENERAL */ },
		pfnUserCallback = debug_message_handler,
		pUserData 		= nil,
	}

	// ----- INSTANCE ------

	// Dont delete! slice to constant memory, I guess
	glfw_required_extension_names 	:= glfw.GetRequiredInstanceExtensions()
	my_extensions 					:= []cstring { vk.EXT_DEBUG_UTILS_EXTENSION_NAME }
	enabled_extensions 				:= make([]cstring, len(glfw_required_extension_names) + len(my_extensions))

	// fmt.println(glfw_required_extension_names)
	copy(enabled_extensions[:len(glfw_required_extension_names)], glfw_required_extension_names)
	copy(enabled_extensions[len(glfw_required_extension_names):], my_extensions)

	enabled_layers := []cstring{ "VK_LAYER_KHRONOS_validation" }

	application_info := vk.ApplicationInfo {
		sType = .APPLICATION_INFO,
		pApplicationName 	= "shrubs",
		applicationVersion 	= vk.MAKE_VERSION(0, 0, 1),
		pEngineName 		= "shrubs",
		engineVersion 		= vk.MAKE_VERSION(0, 0, 1),
		apiVersion 			= vk.API_VERSION_1_3,
	}

	instance_create_info := vk.InstanceCreateInfo {
		sType 					= .INSTANCE_CREATE_INFO,
		pNext 					= &debug_utils_messenger_create_info,
		pApplicationInfo 		= &application_info,
		enabledLayerCount 		= u32(len(enabled_layers)),
		ppEnabledLayerNames 	= raw_data(enabled_layers),
		enabledExtensionCount 	= u32(len(enabled_extensions)),
		ppEnabledExtensionNames = raw_data(enabled_extensions),
	}

	instance_create_result := vk.CreateInstance(&instance_create_info, nil, &graphics.instance)
	handle_result(instance_create_result)

	// instance is now created, load more functions
	vk.load_proc_addresses_instance(graphics.instance)

	fmt.println("instance created")
	fmt.println("more proc addresses loaded")

	// ----- DEBUG INFO --------

	dumc_result := vk.CreateDebugUtilsMessengerEXT(
		graphics.instance,
		&debug_utils_messenger_create_info,
		nil,
		&graphics.debug_messenger,
	)
	handle_result(dumc_result)
	fmt.println("[VULKAN]: debug utils created")

	// ------ SURFACE --------
	surface_result := glfw.CreateWindowSurface(graphics.instance, window.get_glfw_window_handle(), nil, &graphics.surface)
	handle_result(surface_result)
	fmt.println("[VULKAN]: surface created:", graphics.surface != VK_NULL_HANDLE)

	// ------ PHYSICAL DEVICE -----
	// Todo(Leo): check that these are available in the physical device
	device_extensions := []cstring { vk.KHR_SWAPCHAIN_EXTENSION_NAME }

	// Todo(Leo): I know what my computer has, but do this properly!!
	{
		available_devices_backing : [10]vk.PhysicalDevice
		count := u32(len(available_devices_backing))
		result := vk.EnumeratePhysicalDevices(graphics.instance, &count, raw_data(&available_devices_backing))
		handle_result(result)
		available_devices := available_devices_backing[:count]

		// Todo(Leo): check support for extensions, for now just pick any discrete gpu
		// (I only have exactly one of those on me laptop)
		// selected_device : vk.PhysicalDevice
		for d in available_devices {
			is_ok := true

			properties : vk.PhysicalDeviceProperties
			vk.GetPhysicalDeviceProperties(d, &properties)

			if properties.deviceType != .DISCRETE_GPU {
				is_ok = false
				continue
			}

			queue_families : [100]vk.QueueFamilyProperties
			queue_family_count := u32(len(queue_families))
			vk.GetPhysicalDeviceQueueFamilyProperties(d, &queue_family_count, raw_data(&queue_families))

			// Todo(Leo): rank better if all are available in same family?
			graphics_family_index := -1
			present_family_index := -1
			compute_family_index := -1

			for q, index in queue_families[:queue_family_count] {
				if .GRAPHICS in q.queueFlags {
					graphics_family_index = index
				}

				if .COMPUTE in q.queueFlags {
					compute_family_index = index
				}

				supports_surface := b32(false)
				vk.GetPhysicalDeviceSurfaceSupportKHR(d, u32(index), graphics.surface, &supports_surface)

				if supports_surface {
					present_family_index = index
				}
			}

			has_all_queues := graphics_family_index >= 0 &&
								compute_family_index >= 0 &&
								present_family_index >= 0

			if is_ok && has_all_queues {
				graphics.physical_device 		= d
				graphics.graphics_queue_family 	= u32(graphics_family_index)
				graphics.compute_queue_family 	= u32(compute_family_index)
				graphics.present_queue_family 	= u32(present_family_index)
				
				break
			}
		}

		// this implicitly counts for queues too, see above loop
		assert(graphics.physical_device != nil)
	}

	// ------ (LOGICAL) DEVICE --------
	{
		// Todo(Leo): obviously not like this!!
		assert(graphics.graphics_queue_family == 0)
		assert(graphics.present_queue_family == 2)
		assert(graphics.compute_queue_family == 2)
	
		priority := f32(1)

		queue_create_infos := [2]vk.DeviceQueueCreateInfo {}

		queue_create_infos[0] = {
			sType 				= .DEVICE_QUEUE_CREATE_INFO,
			queueFamilyIndex 	= graphics.graphics_queue_family,
			queueCount 			= 1,
			pQueuePriorities 	= &priority
		}
		
		queue_create_infos[1] = {
			sType 				= .DEVICE_QUEUE_CREATE_INFO,
			queueFamilyIndex 	= graphics.compute_queue_family,
			queueCount 			= 2,
			pQueuePriorities 	= &priority
		}

		// Todo(Leo): query availability
		enabled_physical_device_features := vk.PhysicalDeviceFeatures {
			fillModeNonSolid 	= true,
			wideLines 			= true,
		}

		device_create_info := vk.DeviceCreateInfo {
			sType 					= .DEVICE_CREATE_INFO,
			queueCreateInfoCount 	= 2,
			pQueueCreateInfos 		= raw_data(queue_create_infos[:]),
			pEnabledFeatures 		= &enabled_physical_device_features,
			enabledExtensionCount 	= u32(len(device_extensions)),
			ppEnabledExtensionNames = raw_data(device_extensions),
		}

		device_create_result := vk.CreateDevice(
			graphics.physical_device,
			&device_create_info,
			nil,
			&graphics.device,
		)
		handle_result(device_create_result)
	
		vk.GetDeviceQueue(graphics.device, graphics.graphics_queue_family, 0, &graphics.graphics_queue)
		vk.GetDeviceQueue(graphics.device, graphics.compute_queue_family, 0, &graphics.compute_queue)
		vk.GetDeviceQueue(graphics.device, graphics.present_queue_family, 1, &graphics.present_queue)
	}

	// ----- SWAPCHAIN ---
	{	
		g := &graphics

		available_format_count := u32(100)
		available_formats : [100]vk.SurfaceFormatKHR
		// Todo(Leo): this COULD be incmplete, SHOULD not. check result
		vk.GetPhysicalDeviceSurfaceFormatsKHR (
			g.physical_device,
			g.surface,
			&available_format_count,
			raw_data(&available_formats)
		)

		available_present_mode_count := u32(10)
		available_present_modes : [10]vk.PresentModeKHR
		// Todo(Leo): this COULD be incmplete, SHOULD not. check result
		vk.GetPhysicalDeviceSurfacePresentModesKHR(
			g.physical_device,
			g.surface,
			&available_present_mode_count,
			raw_data(&available_present_modes),
		)

		assert(available_format_count > 0)
		assert(available_present_mode_count > 0)

		preferred_format 		:= vk.Format.B8G8R8A8_UNORM
		preferred_color_space 	:= vk.ColorSpaceKHR.SRGB_NONLINEAR
		preferred_present_mode 	:= vk.PresentModeKHR.MAILBOX
	
		selection := 0
		for sf, i in available_formats[:available_format_count] {
			if sf.format == preferred_format && sf.colorSpace == preferred_color_space {
				selection = i
			}
		}
		selected_format 		:= available_formats[selection].format
		selected_color_space 	:= available_formats[selection].colorSpace

		fmt.println(selected_format)

		selected_present_mode := vk.PresentModeKHR.FIFO
		for pm in available_present_modes[:available_present_mode_count] {
			if pm == preferred_present_mode {
				selected_present_mode = preferred_present_mode
				break
			}
		}

		capabilities : vk.SurfaceCapabilitiesKHR
		vk.GetPhysicalDeviceSurfaceCapabilitiesKHR(g.physical_device, g.surface, &capabilities)

		selected_extent : vk.Extent2D
		if capabilities.currentExtent.width == max(u32) {
			w, h := window.get_window_size()
			selected_extent = { u32(w), u32(h) }
		} else {
			selected_extent = capabilities.currentExtent
		}

		// todo(Leo): think more, what would be ideal number of images. though maybe its not necessary.
		image_count := capabilities.minImageCount + 1
		if capabilities.maxImageCount > 0 {
			image_count = min(image_count, capabilities.maxImageCount)
		}

		// Todo(Leo): this depends on number of queue families so change when we fix those
		image_sharing_mode := vk.SharingMode.CONCURRENT
		queue_families := []u32 {g.graphics_queue_family, g.present_queue_family}

		swapchain_create_info := vk.SwapchainCreateInfoKHR {
			sType = .SWAPCHAIN_CREATE_INFO_KHR,
			surface = g.surface,
			minImageCount = image_count,
			imageFormat = selected_format,
			imageColorSpace = selected_color_space,
			imageExtent = selected_extent,
			imageArrayLayers = 1,
			imageUsage = { .TRANSFER_DST, .COLOR_ATTACHMENT },
			imageSharingMode = image_sharing_mode,
			queueFamilyIndexCount = 2,
			pQueueFamilyIndices = raw_data(queue_families),

			// todo(Leo): study this, may be relevant e.g. on phones
			preTransform 	= { .IDENTITY }, //surface_capabilities.currentTransform,
			compositeAlpha 	= { .OPAQUE },

			presentMode = selected_present_mode,
			clipped = true,
			oldSwapchain = VK_NULL_HANDLE,
		}
		swapchain_create_result := vk.CreateSwapchainKHR(g.device, &swapchain_create_info, nil, &g.swapchain)
		handle_result(swapchain_create_result)

		// Todo(Leo): think allocation
		swapchain_image_count : u32
		vk.GetSwapchainImagesKHR(g.device, g.swapchain, &swapchain_image_count, nil)
		g.swapchain_images = make([]vk.Image, swapchain_image_count, g.allocator)
		vk.GetSwapchainImagesKHR(
			g.device, 
			g.swapchain, 
			&swapchain_image_count, 
			raw_data(g.swapchain_images),
		)
		g.swapchain_image_format = selected_format
		g.swapchain_image_extent = selected_extent

		image_view_create_info := vk.ImageViewCreateInfo {
			sType 				= .IMAGE_VIEW_CREATE_INFO,
			viewType 			= .D2,
			format 				= g.swapchain_image_format,
			subresourceRange 	= {{ .COLOR }, 0, 1, 0, 1 }
		}

		g.swapchain_image_views = make([]vk.ImageView, swapchain_image_count, g.allocator)
		for iv, i in &g.swapchain_image_views {
			image_view_create_info.image = g.swapchain_images[i]
			image_view_create_result := vk.CreateImageView(g.device, &image_view_create_info, nil, &iv)
			handle_result(image_view_create_result)
		}
	}

	// ------- COMMAND POOLS -------
	{
		g := &graphics

		graphics_command_pool_create_info := vk.CommandPoolCreateInfo {
			sType = .COMMAND_POOL_CREATE_INFO,
			flags = { .TRANSIENT, .RESET_COMMAND_BUFFER },
			queueFamilyIndex = g.graphics_queue_family,
		}

		graphics_command_pool_create_result := vk.CreateCommandPool (
			g.device,
			&graphics_command_pool_create_info,
			nil,
			&g.command_pools[.Graphics],
		)
		handle_result(graphics_command_pool_create_result)

		compute_command_pool_create_info := vk.CommandPoolCreateInfo {
			sType = .COMMAND_POOL_CREATE_INFO,
			flags = { .TRANSIENT, .RESET_COMMAND_BUFFER },
			queueFamilyIndex = g.graphics_queue_family,
		}

		compute_command_pool_create_result := vk.CreateCommandPool (
			g.device,
			&compute_command_pool_create_info,
			nil,
			&g.command_pools[.Compute],
		)
		handle_result(compute_command_pool_create_result)
	}

	// ----- VIRTUAL FRAME INDEX -----

	// this is quite important, and easy to miss, detail
	graphics.virtual_frame_index = 0

	// ------ MAIN COMMAND BUFFERS ------
	{
		g := &graphics

		allocate_info := vk.CommandBufferAllocateInfo {
			sType 				= .COMMAND_BUFFER_ALLOCATE_INFO,
			commandPool 		= g.command_pools[.Graphics],
			level 				= .PRIMARY,
			commandBufferCount 	= VIRTUAL_FRAME_COUNT,
		}

		allocate_result := vk.AllocateCommandBuffers(
			g.device,
			&allocate_info,
			raw_data(&g.main_command_buffers),
		)
	}

	// ------ SYNCHRONIZATION ------
	{
		g := &graphics

		fence_create_info := vk.FenceCreateInfo {
			sType = .FENCE_CREATE_INFO,
			flags = { .SIGNALED },
		}

		semaphore_create_info := vk.SemaphoreCreateInfo {
			sType = .SEMAPHORE_CREATE_INFO,
		}

		for i in 0..<VIRTUAL_FRAME_COUNT {
			vk.CreateFence(g.device, &fence_create_info, nil, &g.virtual_frame_in_use_fences[i])
			vk.CreateSemaphore(g.device, &semaphore_create_info, nil, &g.rendering_complete_semaphores[i])
			vk.CreateSemaphore(g.device, &semaphore_create_info, nil, &g.present_complete_semaphores[i])
		}
	}

	// ------- TEST RENDER PASS -------
	{
		g := &graphics

		color_attachment := vk.AttachmentDescription {
			format 			= g.swapchain_image_format,
			samples 		= { ._1 },
			loadOp 			= .CLEAR,
			storeOp 		= .STORE,
			initialLayout 	= .UNDEFINED,
			finalLayout 	= .PRESENT_SRC_KHR,
		}

		color_attachment_ref := vk.AttachmentReference{
			attachment 	= 0,
			layout 		= .COLOR_ATTACHMENT_OPTIMAL,			
		}

		subpass := vk.SubpassDescription {
			pipelineBindPoint 		= .GRAPHICS,
			colorAttachmentCount 	= 1,
			pColorAttachments 		= &color_attachment_ref
		}

		render_pass_create_info := vk.RenderPassCreateInfo {
			sType 			= .RENDER_PASS_CREATE_INFO,
			attachmentCount = 1,
			pAttachments 	= &color_attachment,
			subpassCount 	= 1,
			pSubpasses 		= &subpass
		}
		render_pass_create_result := vk.CreateRenderPass(
			g.device, 
			&render_pass_create_info, 
			nil, 
			&g.test_render_pass,
		)
		handle_result(render_pass_create_result)
	}

	// Test pipeline layout
	{
		g := &graphics

		layout_create_info := vk.PipelineLayoutCreateInfo {
			sType = .PIPELINE_LAYOUT_CREATE_INFO,
		}
		layout_create_result := vk.CreatePipelineLayout(g.device, &layout_create_info, nil, &g.test_pipeline_layout)
		handle_result(layout_create_result)
	}	



	// ------- TEST SHADER/PIPELINE -------
	{
		g := &graphics

		// SHADERS
		vert_shader_code, vert_ok := os.read_entire_file("test_vert.spv")
		frag_shader_code, frag_ok := os.read_entire_file("test_frag.spv")
		defer delete(vert_shader_code)
		defer delete(frag_shader_code)

		assert(vert_ok && frag_ok)

		vert_module, frag_module : vk.ShaderModule

		vert_module_create_info := vk.ShaderModuleCreateInfo{
			sType 		= .SHADER_MODULE_CREATE_INFO,
			codeSize 	= len(vert_shader_code),
			pCode 		= cast(^u32) raw_data(vert_shader_code),
		}
		vert_module_create_result := vk.CreateShaderModule(g.device, &vert_module_create_info, nil, &vert_module)
		handle_result(vert_module_create_result)

		frag_module_create_info := vk.ShaderModuleCreateInfo{
			sType 		= .SHADER_MODULE_CREATE_INFO,
			codeSize 	= len(frag_shader_code),
			pCode 		= cast(^u32) raw_data(frag_shader_code),
		}
		frag_module_create_result := vk.CreateShaderModule(g.device, &frag_module_create_info, nil, &frag_module)
		handle_result(frag_module_create_result)

		// SHADER STAGES
		vert_stage_create_info := vk.PipelineShaderStageCreateInfo {
			sType = .PIPELINE_SHADER_STAGE_CREATE_INFO,
			stage = { .VERTEX },
			module = vert_module,
			pName = "main",
		}

		frag_stage_create_info := vk.PipelineShaderStageCreateInfo {
			sType = .PIPELINE_SHADER_STAGE_CREATE_INFO,
			stage = { .FRAGMENT },
			module = frag_module,
			pName = "main",
		}

		shader_stages := []vk.PipelineShaderStageCreateInfo {
			vert_stage_create_info, 
			frag_stage_create_info,
		}

		dynamic_states := []vk.DynamicState { .VIEWPORT, .SCISSOR }
		dynamic_state := vk.PipelineDynamicStateCreateInfo {
			sType 				= .PIPELINE_DYNAMIC_STATE_CREATE_INFO,
			dynamicStateCount 	= u32(len(dynamic_states)),
			pDynamicStates 		= raw_data(dynamic_states)
		}

		vertex_input := vk.PipelineVertexInputStateCreateInfo {
			sType = .PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO,
			vertexBindingDescriptionCount = 0,
			vertexAttributeDescriptionCount = 0,
		}

		input_assembly := vk.PipelineInputAssemblyStateCreateInfo {
			sType 					= .PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO,
			topology 				= .TRIANGLE_LIST,
			primitiveRestartEnable 	= false,
		}

		// dynamic! details at render time
		viewport_state := vk.PipelineViewportStateCreateInfo {
			sType 			= .PIPELINE_VIEWPORT_STATE_CREATE_INFO,
			viewportCount 	= 1,
			scissorCount 	= 1
		}

		rasterization := vk.PipelineRasterizationStateCreateInfo {
			sType 					= .PIPELINE_RASTERIZATION_STATE_CREATE_INFO,
			depthClampEnable 		= VK_FALSE,
			rasterizerDiscardEnable = VK_FALSE,
			polygonMode 			= .FILL,
			lineWidth 				= 1.0,
			cullMode	 			= { .BACK },
			frontFace 				= .CLOCKWISE,
			depthBiasEnable			= VK_FALSE,
		}

		multisampling := vk.PipelineMultisampleStateCreateInfo {
			sType 					= .PIPELINE_MULTISAMPLE_STATE_CREATE_INFO,
			sampleShadingEnable 	= VK_FALSE,
			rasterizationSamples 	= { ._1 },
			minSampleShading 		= 1.0,
			pSampleMask 			= nil,
			alphaToCoverageEnable 	= VK_FALSE,
			alphaToOneEnable 		= VK_FALSE,
		}

		color_blend_attachment := vk.PipelineColorBlendAttachmentState {
			colorWriteMask = { .R, .G, .B },
			blendEnable = VK_FALSE,
		}

		color_blend := vk.PipelineColorBlendStateCreateInfo {
			sType = .PIPELINE_COLOR_BLEND_STATE_CREATE_INFO,
			logicOpEnable = VK_FALSE,
			attachmentCount = 1,
			pAttachments = &color_blend_attachment,
		}

		pipeline_create_info := vk.GraphicsPipelineCreateInfo {
			sType = .GRAPHICS_PIPELINE_CREATE_INFO,
			
			stageCount 	= 2,
			pStages 	= raw_data(shader_stages),

			pVertexInputState 	= &vertex_input,
			pInputAssemblyState = &input_assembly,
			pViewportState 		= &viewport_state,
			pRasterizationState = &rasterization,
			pMultisampleState 	= &multisampling,
			pDepthStencilState 	= nil,
			pColorBlendState 	= &color_blend,
			pDynamicState 		= &dynamic_state,

			layout = g.test_pipeline_layout,
		
			renderPass 	= g.test_render_pass,
			subpass 	= 0,
		}

		pipeline_create_result := vk.CreateGraphicsPipelines(
			g.device,
			VK_NULL_HANDLE,
			1,
			&pipeline_create_info,
			nil,
			&g.test_pipeline,
		)
		handle_result(pipeline_create_result)


		// ------------------------------------------------
		vk.DestroyShaderModule(g.device, vert_module, nil)
		vk.DestroyShaderModule(g.device, frag_module, nil)
	}
	fmt.println("[VULKAN]: test shaders good!")

	// ------ MOCKUP SWAPCHAIN FRAMEBUFFERS -------
	{
		g := &graphics

		swapchain_image_count := len(g.swapchain_images)
		g.swapchain_framebuffers = make([]vk.Framebuffer, swapchain_image_count, g.allocator)

		for i in 0..<swapchain_image_count {
			framebuffer_create_info := vk.FramebufferCreateInfo {
				sType 			= .FRAMEBUFFER_CREATE_INFO,
				renderPass 		= g.test_render_pass,
				attachmentCount = 1,
				pAttachments 	= &g.swapchain_image_views[i],
				width 			= g.swapchain_image_extent.width,
				height 			= g.swapchain_image_extent.height,
				layers 			= 1,
			}

			framebuffer_create_result := vk.CreateFramebuffer(
				g.device, 
				&framebuffer_create_info, 
				nil,
				&g.swapchain_framebuffers[i],
			)
			handle_result(framebuffer_create_result)
		}
	}

	// -------- DONE ------------
	fmt.println("[VULKAN]: Vulkan graphics initialized propely!")
}

terminate :: proc() {
	g := &graphics
	vk.DeviceWaitIdle(g.device)

	for i in 0..<len(g.swapchain_framebuffers) {
		vk.DestroyFramebuffer(g.device, g.swapchain_framebuffers[i], nil)
	}

	vk.DestroyRenderPass(g.device, g.test_render_pass, nil)
	vk.DestroyPipelineLayout(g.device, g.test_pipeline_layout, nil)
	vk.DestroyPipeline(g.device, g.test_pipeline, nil)


	for i in 0..<VIRTUAL_FRAME_COUNT {
		vk.DestroyFence(g.device, g.virtual_frame_in_use_fences[i], nil)
		vk.DestroySemaphore(g.device, g.rendering_complete_semaphores[i], nil)
		vk.DestroySemaphore(g.device, g.present_complete_semaphores[i], nil)
	}

	for cp in g.command_pools {
		vk.DestroyCommandPool(g.device, cp, nil)
	}

	{
		for iv in g.swapchain_image_views {
			vk.DestroyImageView(g.device, iv, nil)
		}
		vk.DestroySwapchainKHR(g.device, g.swapchain, nil)
	}

	vk.DestroyDevice(g.device, nil)

	vk.DestroySurfaceKHR(g.instance, g.surface, nil)

	vk.DestroyDebugUtilsMessengerEXT(g.instance, g.debug_messenger, nil)

	vk.DestroyInstance(g.instance, nil)

	fmt.println("Vulkan graphics terminated propely!")
}

begin_frame :: proc() {
	g := &graphics

	// WAIT
	vk.WaitForFences(g.device, 1, &g.virtual_frame_in_use_fences[g.virtual_frame_index], true, max(u64))

	// RESET
	main_cmd := g.main_command_buffers[g.virtual_frame_index]
	// Todo(Leo): this is apparently implicit
	// reset_result := vk.ResetCommandBuffer(main_cmd, {})
	// handle_result(reset_result)

	main_cmd_begin_info := vk.CommandBufferBeginInfo {
		sType = .COMMAND_BUFFER_BEGIN_INFO,
		flags = {},
		// flags = { .ONE_TIME_SUBMIT },
	}
	main_cmd_begin_result := vk.BeginCommandBuffer(main_cmd, &main_cmd_begin_info)
	handle_result(main_cmd_begin_result)
}

render :: proc() {
	g := &graphics

	main_cmd := g.main_command_buffers[g.virtual_frame_index]

	// Todo(Leo): think again if present_complete_semaphores make sense with virtual frame stuff
	virtual_frame_in_use_fence 		:= g.virtual_frame_in_use_fences[g.virtual_frame_index]
	present_complete_semaphore 		:= g.present_complete_semaphores[g.virtual_frame_index]
	rendering_complete_semaphore 	:= g.rendering_complete_semaphores[g.virtual_frame_index]

	// ---- PROCESS THE SWAPCHAIN IMAGE -----
	swapchain_image_index : u32
	acquire_result := vk.AcquireNextImageKHR(
		g.device,
		g.swapchain,
		max(u64),
		present_complete_semaphore,
		VK_NULL_HANDLE,
		&swapchain_image_index,
	)
	handle_result(acquire_result)

	// Testingfgjogisj	
	clear_color := vk.ClearValue { color = { float32 = {1, 0, 0, 1}}}

	render_pass_begin_info := vk.RenderPassBeginInfo {
		sType 				= .RENDER_PASS_BEGIN_INFO,
		renderPass 			= g.test_render_pass,
		framebuffer 		= g.swapchain_framebuffers[swapchain_image_index],		
		renderArea 			= {{0, 0}, g.swapchain_image_extent},
		clearValueCount 	= 1,
		pClearValues 		= &clear_color,
	}
	vk.CmdBeginRenderPass(main_cmd, &render_pass_begin_info, .INLINE)

	vk.CmdBindPipeline(main_cmd, .GRAPHICS, g.test_pipeline)
	viewport := vk.Viewport {
		x 		= 0,
		y 		= 0,
		width 	= f32(g.swapchain_image_extent.width),
		height 	= f32(g.swapchain_image_extent.height),
	}
	vk.CmdSetViewport(main_cmd, 0, 1, &viewport)

	scissor := vk.Rect2D {
		offset = {0, 0},
		extent = g.swapchain_image_extent,
	}
	vk.CmdSetScissor(main_cmd, 0, 1, &scissor)

	vk.CmdDraw(main_cmd, 3, 1, 0, 0)

	vk.CmdEndRenderPass(main_cmd)

	// {
	// 	// Todo(Leo): this is still the test thing, so transfer is not correct one
	// 	transition_barrier := vk.ImageMemoryBarrier {
	// 		sType 				= .IMAGE_MEMORY_BARRIER,
	// 		srcAccessMask 		= { .TRANSFER_WRITE }, // wait until TRANSFER_WRITE is done
	// 		dstAccessMask 		= { .TRANSFER_READ }, // don't start TRANSFER_READ until waiting is done // here, TRANSFER_READ refers to presenting
	// 		oldLayout 			= .UNDEFINED,
	// 		newLayout 			= .PRESENT_SRC_KHR,
	// 		srcQueueFamilyIndex = vk.QUEUE_FAMILY_IGNORED,
	// 		dstQueueFamilyIndex = vk.QUEUE_FAMILY_IGNORED,
	// 		image 				= g.swapchain_images[swapchain_image_index],
	// 		subresourceRange 	= {{.COLOR}, 0, 1, 0, 1},
	// 	}

	// 	vk.CmdPipelineBarrier(
	// 		main_cmd,
	// 		{ .TRANSFER }, { .TRANSFER },
	// 		{},
	// 		0, nil, 0, nil, 1, &transition_barrier,
	// 	)
	// }


	// --- MAIN COMMAND BUFFER ------
	vk.EndCommandBuffer(main_cmd)

	// Note that fence is intentionally reset only after acquiring the next image,
	// Todo(Leo): but I cant remember why.
	vk.ResetFences(g.device, 1, &virtual_frame_in_use_fence)

	wait_mask := vk.PipelineStageFlags { .COLOR_ATTACHMENT_OUTPUT }

	main_cmd_submit_info := vk.SubmitInfo {
		sType 					= .SUBMIT_INFO,
		waitSemaphoreCount 		= 1,
		pWaitSemaphores 		= &present_complete_semaphore,
		pWaitDstStageMask 		= &wait_mask,
		commandBufferCount 		= 1,
		pCommandBuffers 		= &main_cmd,
		signalSemaphoreCount 	= 1, 
		pSignalSemaphores 		= &rendering_complete_semaphore,
	}
	main_cmd_submit_result := vk.QueueSubmit(g.graphics_queue, 1, &main_cmd_submit_info, virtual_frame_in_use_fence)

	// ------ PRESENT -------
	present_info := vk.PresentInfoKHR {
		sType 				= .PRESENT_INFO_KHR,
		waitSemaphoreCount 	= 1,
		pWaitSemaphores 	= &rendering_complete_semaphore,
		swapchainCount 		= 1,
		pSwapchains 		= &g.swapchain,
		pImageIndices 		= &swapchain_image_index,
		pResults 			= nil,
	}
	present_result := vk.QueuePresentKHR(g.present_queue, &present_info)

	// NEXT VIRTUAL FRAME
	// We are done with this frame and next frame we use next frame, duh
	g.virtual_frame_index += 1
	g.virtual_frame_index %= VIRTUAL_FRAME_COUNT

}

// rndom
bind_screen_framebuffer :: proc() {}
bind_uniform_buffer :: proc(buffer : ^Buffer, binding : u32) {}
read_screen_framebuffer :: proc() -> (width, height : int, pixels_u8_rgba : []u8) {
	return width, height, pixels_u8_rgba
}
