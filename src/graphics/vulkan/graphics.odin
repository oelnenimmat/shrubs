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

// Setting this to one results only in a complaint about there being an resolve attachment
// (ofc it is happy accident that only works on my computer, so fix)
// Todo(Leo): dont do resolving when this is one.
// Todo(Leo): make this configurable and recreate (everything??) when changed
MULTI_SAMPLE_COUNT :: vk.SampleCountFlags {._2}

@private
Graphics :: struct {
	// use this to allocate all slices in here, maybe even this struct itself down the line
	allocator : runtime.Allocator,

	virtual_frame_index : int,

	instance 		: vk.Instance,
	debug_messenger : vk.DebugUtilsMessengerEXT,
	surface 		: vk.SurfaceKHR,
	physical_device : vk.PhysicalDevice,
	device 			: vk.Device,

	swapchain 				: vk.SwapchainKHR,
	swapchain_image_index 	: u32,
	swapchain_images 		: []vk.Image,
	// swapchain_image_views 	: []vk.ImageView,
	// swapchain_framebuffers 	: []vk.Framebuffer,
	// swapchain_image_format 	: vk.Format,
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

	main_command_buffers 	: [VIRTUAL_FRAME_COUNT]vk.CommandBuffer,
	screen_command_buffers 	: [VIRTUAL_FRAME_COUNT]vk.CommandBuffer,
	imgui_command_buffers 	: [VIRTUAL_FRAME_COUNT]vk.CommandBuffer,

	grass_placement_complete_fences : [VIRTUAL_FRAME_COUNT]vk.Fence,
	virtual_frame_in_use_fences 	: [VIRTUAL_FRAME_COUNT]vk.Fence,
	// Todo(Leo): one for grass compute etc :)
	rendering_complete_semaphores 	: [VIRTUAL_FRAME_COUNT]vk.Semaphore,
	present_complete_semaphores 	: [VIRTUAL_FRAME_COUNT]vk.Semaphore,

	descriptor_pool : vk.DescriptorPool,

	// Render passes
	main_render_pass 	: vk.RenderPass,
	screen_render_pass 	: vk.RenderPass,
	imgui_render_pass 	: vk.RenderPass,

	// Pipelines
	pipelines : Pipelines,

	// Render target
	render_target_framebuffer 	: vk.Framebuffer,
	render_target_color_format 	: vk.Format,
	render_target_depth_format 	: vk.Format,
	render_target_extent 		: vk.Extent2D,

	// Deepth
	depth_image 		: vk.Image,
	depth_image_view 	: vk.ImageView,
	depth_memory 		: vk.DeviceMemory,

	// Coolor
	color_image 		: vk.Image,
	color_image_view 	: vk.ImageView,
	color_memory 		: vk.DeviceMemory,

	color_resolve_image 		: vk.Image,
	color_resolve_image_view 	: vk.ImageView,
	color_resolve_memory 		: vk.DeviceMemory,

	color_image_descriptor_layout 	: vk.DescriptorSetLayout,
	color_image_descriptor_set 		: vk.DescriptorSet,


	// Screeeen
	screen_image 		: vk.Image,
	screen_image_format : vk.Format,
	screen_image_view 	: vk.ImageView,
	screen_memory 		: vk.DeviceMemory,
	screen_image_extent : vk.Extent2D,
	screen_framebuffer 	: vk.Framebuffer,

	screenshot_format 	: vk.Format,
	screenshot_image 	: vk.Image,
	screenshot_memory 	: vk.DeviceMemory,

	screenshot_copy_buffer : vk.Buffer,
	screenshot_copy_memory : vk.DeviceMemory,
	screenshot_copy_mapped : [^]u8,

	// Staging
	SWAG_staging_capacity 	: vk.DeviceSize,
	staging_buffer 		: vk.Buffer,
	staging_memory 		: vk.DeviceMemory,
	staging_mapped 		: rawptr,

	// Textures
	linear_sampler : vk.Sampler,
}

@private
graphics : Graphics

@private
get_staging_memory :: proc($Type : typeid, count : int) -> []Type {
	g := &graphics

	size := vk.DeviceSize(size_of(Type) * count)
	fmt.assertf(size <= g.SWAG_staging_capacity, "capacity: {}, size: {}", g.SWAG_staging_capacity, size)

	return (cast([^]Type)g.staging_mapped)[:count]
}

@private
align_up :: proc(#any_int address, alignment : vk.DeviceSize) -> vk.DeviceSize {
	if (address % alignment) == 0 {
		return address
	} else {
		return (address / alignment + 1) * alignment
	}
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
		vk.GetDeviceQueue(graphics.device, graphics.compute_queue_family, 1, &graphics.compute_queue)
		vk.GetDeviceQueue(graphics.device, graphics.present_queue_family, 1, &graphics.present_queue)
	}

	// ----- SWAPCHAIN ---
	create_swapchain()

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
			queueFamilyIndex = g.compute_queue_family,
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

	// ------ Allocate COMMAND BUFFERS ------
	{
		g := &graphics

		allocate_command_buffers :: proc(
			command_pool 	: vk.CommandPool, 
			level 			: vk.CommandBufferLevel,
			$COUNT 			: u32,
		) -> [COUNT]vk.CommandBuffer {
			g := &graphics
			
			info := vk.CommandBufferAllocateInfo {
				sType 				= .COMMAND_BUFFER_ALLOCATE_INFO,
				commandPool 		= command_pool,
				level 				= level,
				commandBufferCount 	= COUNT,
			}

			cmds : [COUNT]vk.CommandBuffer
			result := vk.AllocateCommandBuffers(g.device, &info, raw_data(&cmds))
			handle_result(result)

			return cmds
		}

		g.main_command_buffers = allocate_command_buffers(
			g.command_pools[.Graphics],
			.PRIMARY,
			VIRTUAL_FRAME_COUNT,
		)

		g.screen_command_buffers = allocate_command_buffers(
			g.command_pools[.Graphics],
			.SECONDARY,
			VIRTUAL_FRAME_COUNT,
		)

		g.imgui_command_buffers = allocate_command_buffers(
			g.command_pools[.Graphics],
			.SECONDARY,
			VIRTUAL_FRAME_COUNT,
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
			vk.CreateFence(g.device, &fence_create_info, nil, &g.grass_placement_complete_fences[i])
			vk.CreateSemaphore(g.device, &semaphore_create_info, nil, &g.rendering_complete_semaphores[i])
			vk.CreateSemaphore(g.device, &semaphore_create_info, nil, &g.present_complete_semaphores[i])
		}
	}


	// DESCRIPTOR POOLS
	{
		g := &graphics

		descriptor_pool_sizes := [] vk.DescriptorPoolSize {
			{ .UNIFORM_BUFFER, 100 },
			{ .COMBINED_IMAGE_SAMPLER, 100 },
		}

		descriptor_pool_create_info := vk.DescriptorPoolCreateInfo {
			sType 			= .DESCRIPTOR_POOL_CREATE_INFO,
			flags 			= { .FREE_DESCRIPTOR_SET },
			maxSets 		= 400, // no idea really. 100 is too little early on
			poolSizeCount 	= u32(len(descriptor_pool_sizes)),
			pPoolSizes 		= raw_data(descriptor_pool_sizes),
		}

		descriptor_pool_create_result := vk.CreateDescriptorPool (
			graphics.device,
			&descriptor_pool_create_info,
			nil,
			&g.descriptor_pool,
		)
		handle_result(descriptor_pool_create_result)
	}

	// Samplers
	{
		g := &graphics

		// https://docs.vulkan.org/tutorial/latest/06_Texture_mapping/01_Image_view_and_sampler.html
		// Todo(Leo): anisotropy sampling

		create_info := vk.SamplerCreateInfo {
			sType = .SAMPLER_CREATE_INFO,
			pNext = nil,
			flags = {},
			magFilter = .LINEAR,
			minFilter = .LINEAR,
			mipmapMode = .LINEAR,
			addressModeU = .REPEAT,
			addressModeV = .REPEAT,
			addressModeW = .REPEAT,

			mipLodBias = 0,

			// Todo(Leo): enable, see above, today im lazy
			anisotropyEnable = false,
			// maxAnisotropy = ,

			compareEnable = false,
			compareOp = .ALWAYS,

			minLod = 0,
			maxLod = vk.LOD_CLAMP_NONE,

			borderColor = .INT_OPAQUE_BLACK,
			unnormalizedCoordinates = false,
		}
		create_result := vk.CreateSampler(g.device, &create_info, nil, &g.linear_sampler)
	}

	// RENDER TARGET
	// Todo(Leo): check format properties that we can actually do what we want to with these
	// formats. Also check other gpu properties
	graphics.render_target_color_format = .R32G32B32A32_SFLOAT
	graphics.render_target_depth_format = .D32_SFLOAT
	graphics.render_target_extent = {1920, 1080} //{1280, 720}

	graphics.screen_image_format = .R8G8B8A8_SRGB

	{
		g := &graphics

		g.color_image_descriptor_layout = create_descriptor_set_layout({
			{0, .COMBINED_IMAGE_SAMPLER, 1, { .FRAGMENT }, nil },
		})
		g.color_image_descriptor_set = allocate_descriptor_set(g.color_image_descriptor_layout)
	}


	create_color()
	create_depth()

	// ------- MAIN Render Pass -------
	{
		g := &graphics

		attachments := []vk.AttachmentDescription {
			{
				format 			= g.render_target_color_format,
				samples 		= MULTI_SAMPLE_COUNT,
				loadOp 			= .CLEAR,
				storeOp 		= .STORE,
				initialLayout 	= .UNDEFINED,
				finalLayout 	= .SHADER_READ_ONLY_OPTIMAL,
			},
			{
				format 			= g.render_target_depth_format,
				samples 		= MULTI_SAMPLE_COUNT,
				loadOp 			= .CLEAR,
				storeOp 		= .DONT_CARE,
				stencilLoadOp 	= .DONT_CARE,
				stencilStoreOp 	= .DONT_CARE,
				initialLayout 	= .UNDEFINED,
				finalLayout 	= .DEPTH_STENCIL_ATTACHMENT_OPTIMAL,
			},
			{
				format 			= g.render_target_color_format,
				samples 		= { ._1 },
				loadOp 			= .DONT_CARE,
				storeOp 		= .STORE,
				initialLayout 	= .UNDEFINED,
				finalLayout 	= .SHADER_READ_ONLY_OPTIMAL,
			},
		}

		color_attachment_ref := vk.AttachmentReference{0, .COLOR_ATTACHMENT_OPTIMAL}
		depth_attachment_ref := vk.AttachmentReference{1, .DEPTH_STENCIL_ATTACHMENT_OPTIMAL}
		resolve_attachment_ref := vk.AttachmentReference{2, .COLOR_ATTACHMENT_OPTIMAL}

		subpass := vk.SubpassDescription {
			pipelineBindPoint 		= .GRAPHICS,
			colorAttachmentCount 	= 1,
			pColorAttachments 		= &color_attachment_ref,
			pResolveAttachments 	= &resolve_attachment_ref,
			pDepthStencilAttachment = &depth_attachment_ref,
		}

		render_pass_create_info := vk.RenderPassCreateInfo {
			sType 			= .RENDER_PASS_CREATE_INFO,
			attachmentCount = u32(len(attachments)),
			pAttachments 	= raw_data(attachments),
			subpassCount 	= 1,
			pSubpasses 		= &subpass
		}
		render_pass_create_result := vk.CreateRenderPass(
			g.device, 
			&render_pass_create_info, 
			nil, 
			&g.main_render_pass,
		)
		handle_result(render_pass_create_result)
	}

	// -------- SCREEN Render Pass ---------------
	{
		g := &graphics

		attachment := vk.AttachmentDescription {
			format 			= g.screen_image_format,
			samples 		= { ._1 },
			loadOp 			= .CLEAR,
			storeOp 		= .STORE,
			initialLayout 	= .UNDEFINED,
			finalLayout 	= .TRANSFER_SRC_OPTIMAL,
		}

		color_attachment_ref := vk.AttachmentReference{0, .COLOR_ATTACHMENT_OPTIMAL}

		subpass := vk.SubpassDescription {
			pipelineBindPoint 		= .GRAPHICS,
			colorAttachmentCount 	= 1,
			pColorAttachments 		= &color_attachment_ref,
			pDepthStencilAttachment = nil,
		}

		render_pass_create_info := vk.RenderPassCreateInfo {
			sType 			= .RENDER_PASS_CREATE_INFO,
			attachmentCount = 1,
			pAttachments 	= &attachment,
			subpassCount 	= 1,
			pSubpasses 		= &subpass
		}
		render_pass_create_result := vk.CreateRenderPass(
			g.device, 
			&render_pass_create_info, 
			nil, 
			&g.screen_render_pass,
		)
		handle_result(render_pass_create_result)
	}

	create_screeen()

	{
		g := &graphics

		attachment := vk.AttachmentDescription {
			format 			= g.screen_image_format,
			samples 		= { ._1 },
			loadOp 			= .LOAD,
			storeOp 		= .STORE,
			initialLayout 	= .TRANSFER_SRC_OPTIMAL,
			finalLayout 	= .TRANSFER_SRC_OPTIMAL,
		}

		color_attachment_ref := vk.AttachmentReference{0, .COLOR_ATTACHMENT_OPTIMAL}

		subpass := vk.SubpassDescription {
			pipelineBindPoint 		= .GRAPHICS,
			colorAttachmentCount 	= 1,
			pColorAttachments 		= &color_attachment_ref,
			pDepthStencilAttachment = nil,
		}

		render_pass_create_info := vk.RenderPassCreateInfo {
			sType 			= .RENDER_PASS_CREATE_INFO,
			attachmentCount = 1,
			pAttachments 	= &attachment,
			subpassCount 	= 1,
			pSubpasses 		= &subpass
		}
		render_pass_create_result := vk.CreateRenderPass(
			g.device, 
			&render_pass_create_info, 
			nil, 
			&g.imgui_render_pass,
		)
		handle_result(render_pass_create_result)
	}

	// MAIN Render target framebuffer
	{
		g := &graphics

		attachments := []vk.ImageView {
			g.color_image_view,
			g.depth_image_view,
			g.color_resolve_image_view,
		}

		framebuffer_create_info := vk.FramebufferCreateInfo {
			sType 			= .FRAMEBUFFER_CREATE_INFO,
			renderPass 		= g.main_render_pass,
			attachmentCount = u32(len(attachments)),
			pAttachments 	= raw_data(attachments),
			width 			= g.render_target_extent.width,
			height 			= g.render_target_extent.height,
			layers 			= 1,
		}

		framebuffer_create_result := vk.CreateFramebuffer(
			g.device, 
			&framebuffer_create_info, 
			nil,
			&g.render_target_framebuffer,
		)
		handle_result(framebuffer_create_result)
	}

	// -------- PIPELINES ------------
	create_pipelines()

	// Screen resizing
	glfw.SetFramebufferSizeCallback(
		window.get_glfw_window_handle(),
		// glfw_resize_framebuffer_proc
		proc "c" (window : glfw.WindowHandle, width, height : i32) {
			context = runtime.default_context()

			vk.DeviceWaitIdle(graphics.device)

			destroy_swapchain()
			destroy_screeen()

			create_swapchain()
			create_screeen()
		}
	)

	// Staging
	{
		g := &graphics

		g.SWAG_staging_capacity = 100 * 1024 * 1024
		g.staging_buffer, g.staging_memory = create_buffer_and_memory(
			g.SWAG_staging_capacity,
			{ .TRANSFER_SRC },
			{ .HOST_VISIBLE, .HOST_COHERENT }
		)
		vk.MapMemory(
			g.device, 
			g.staging_memory,
			0,
			g.SWAG_staging_capacity,
			{},
			&g.staging_mapped,
		) 
	}

	// -------- DONE ------------
	fmt.println("[VULKAN]: Vulkan graphics initialized propely!")
}

terminate :: proc() {
	g := &graphics
	vk.DeviceWaitIdle(g.device)

	// "Custom" ??
	destroy_pipelines()

	// Render targeet
	destroy_color()
	destroy_depth()
	vk.DestroyFramebuffer(g.device, g.render_target_framebuffer, nil)
	vk.DestroyDescriptorSetLayout(g.device, g.color_image_descriptor_layout, nil)

	destroy_screeen()
	vk.DestroyRenderPass(g.device, g.screen_render_pass, nil)
	vk.DestroyRenderPass(g.device, g.imgui_render_pass, nil)

	vk.DestroyBuffer(g.device, g.staging_buffer, nil)
	vk.FreeMemory(g.device, g.staging_memory, nil)

	vk.DestroySampler(g.device, g.linear_sampler, nil)

	// "Standard" ??
	vk.DestroyRenderPass(g.device, g.main_render_pass, nil)

	vk.DestroyDescriptorPool(g.device, g.descriptor_pool, nil)

	for i in 0..<VIRTUAL_FRAME_COUNT {
		vk.DestroyFence(g.device, g.virtual_frame_in_use_fences[i], nil)
		vk.DestroyFence(g.device, g.grass_placement_complete_fences[i], nil)
		vk.DestroySemaphore(g.device, g.rendering_complete_semaphores[i], nil)
		vk.DestroySemaphore(g.device, g.present_complete_semaphores[i], nil)
	}

	for cp in g.command_pools {
		vk.DestroyCommandPool(g.device, cp, nil)
	}

	destroy_swapchain()

	vk.DestroyDevice(g.device, nil)

	vk.DestroySurfaceKHR(g.instance, g.surface, nil)

	vk.DestroyDebugUtilsMessengerEXT(g.instance, g.debug_messenger, nil)

	vk.DestroyInstance(g.instance, nil)

	fmt.println("Vulkan graphics terminated propely!")
}

wait_idle :: proc() {
	vk.DeviceWaitIdle(graphics.device)
}

begin_frame :: proc() {
	g := &graphics

	// WAIT, so we can start to rewrite command buffer
	vk.WaitForFences(g.device, 1, &g.virtual_frame_in_use_fences[g.virtual_frame_index], true, max(u64))

	// RESET
	main_cmd 	:= g.main_command_buffers[g.virtual_frame_index]
	screen_cmd 	:= g.screen_command_buffers[g.virtual_frame_index]
	imgui_cmd 	:= g.imgui_command_buffers[g.virtual_frame_index]
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

	// Screen cmd buffer
	screen_viewport := vk.Viewport {
		x 		= 0,
		y 		= 0,
		width 	= f32(g.screen_image_extent.width),
		height 	= f32(g.screen_image_extent.height),
		minDepth = 0.0,
		maxDepth = 1.0,
	}

	screen_scissor := vk.Rect2D {
		offset = {0, 0},
		extent = g.screen_image_extent,
	}

	// Screen cmd buffer
	{
		inheritance := vk.CommandBufferInheritanceInfo {
			sType 		= .COMMAND_BUFFER_INHERITANCE_INFO,
			renderPass 	= g.screen_render_pass,
			subpass 	= 0,
			framebuffer = g.screen_framebuffer,
		}


		begin_info := vk.CommandBufferBeginInfo {
			sType 				= .COMMAND_BUFFER_BEGIN_INFO,
			flags 				= { .RENDER_PASS_CONTINUE },
			pInheritanceInfo 	= &inheritance,
		}

		// screen	
		screen_begin_result := vk.BeginCommandBuffer(screen_cmd, &begin_info)
		handle_result(screen_begin_result)

		vk.CmdSetViewport(screen_cmd, 0, 1, &screen_viewport)
		vk.CmdSetScissor(screen_cmd, 0, 1, &screen_scissor)
	}

	// Imgui cmd buffer
	{
		inheritance := vk.CommandBufferInheritanceInfo {
			sType 		= .COMMAND_BUFFER_INHERITANCE_INFO,
			renderPass 	= g.imgui_render_pass,
			subpass 	= 0,
			framebuffer = g.screen_framebuffer,
		}

		begin_info := vk.CommandBufferBeginInfo {
			sType 				= .COMMAND_BUFFER_BEGIN_INFO,
			flags 				= { .RENDER_PASS_CONTINUE },
			pInheritanceInfo 	= &inheritance,
		}

		// imgui
		imgui_begin_result := vk.BeginCommandBuffer(imgui_cmd, &begin_info)
		handle_result(imgui_begin_result)

		vk.CmdSetViewport(imgui_cmd, 0, 1, &screen_viewport)
		vk.CmdSetScissor(imgui_cmd, 0, 1, &screen_scissor)
	}


	// Todo(Leo): think again if present_complete_semaphores make sense with virtual frame stuff
	virtual_frame_in_use_fence 			:= g.virtual_frame_in_use_fences[g.virtual_frame_index]
	present_complete_semaphore 			:= g.present_complete_semaphores[g.virtual_frame_index]
	rendering_complete_semaphore 		:= g.rendering_complete_semaphores[g.virtual_frame_index]

	// ---- PROCESS THE SWAPCHAIN IMAGE -----
	acquire_result := vk.AcquireNextImageKHR(
		g.device,
		g.swapchain,
		max(u64),
		present_complete_semaphore,
		VK_NULL_HANDLE,
		&g.swapchain_image_index,
	)
	handle_result(acquire_result)

	// Testingfgjogisj	
	clear_values := []vk.ClearValue { 
		{ color = { float32 = {1, 0, 1, 1}}},
		{ depthStencil = { 1.0, 0 }},
	}

	render_pass_begin_info := vk.RenderPassBeginInfo {
		sType 				= .RENDER_PASS_BEGIN_INFO,
		renderPass 			= g.main_render_pass,
		framebuffer 		= g.render_target_framebuffer,	
		renderArea 			= {{0, 0}, g.render_target_extent},
		clearValueCount 	= u32(len(clear_values)),
		pClearValues 		= raw_data(clear_values),
	}
	vk.CmdBeginRenderPass(main_cmd, &render_pass_begin_info, .INLINE)

	{
		main_viewport := vk.Viewport {
			x 		= 0,
			y 		= 0,
			width 	= f32(g.render_target_extent.width),
			height 	= f32(g.render_target_extent.height),
			minDepth = 0.0,
			maxDepth = 1.0,
		}

		main_scissor := vk.Rect2D {
			offset = {0, 0},
			extent = g.render_target_extent,
		}

		vk.CmdSetViewport(main_cmd, 0, 1, &main_viewport)
		vk.CmdSetScissor(main_cmd, 0, 1, &main_scissor)
	}
}

render :: proc() {
	g := &graphics

	// Todo(Leo): think again if present_complete_semaphores make sense with virtual frame stuff
	virtual_frame_in_use_fence 			:= g.virtual_frame_in_use_fences[g.virtual_frame_index]
	present_complete_semaphore 			:= g.present_complete_semaphores[g.virtual_frame_index]
	rendering_complete_semaphore 		:= g.rendering_complete_semaphores[g.virtual_frame_index]

	main_cmd := g.main_command_buffers[g.virtual_frame_index]
	vk.CmdEndRenderPass(main_cmd)


	// Screen render pass
	{
		screen_cmd := g.screen_command_buffers[g.virtual_frame_index]
		vk.EndCommandBuffer(screen_cmd)

		// Testingfgjogisj	
		clear_values := []vk.ClearValue { 
			{ color = { float32 = {0.5, 0, 0.5, 1}}},
		}

		begin := vk.RenderPassBeginInfo {
			sType 				= .RENDER_PASS_BEGIN_INFO,
			renderPass 			= g.screen_render_pass,
			framebuffer 		= g.screen_framebuffer,		
			renderArea 			= {{0, 0}, g.screen_image_extent},
			clearValueCount 	= u32(len(clear_values)),
			pClearValues 		= raw_data(clear_values),
		}
		vk.CmdBeginRenderPass(main_cmd, &begin, .SECONDARY_COMMAND_BUFFERS)
		vk.CmdExecuteCommands(main_cmd, 1, &screen_cmd)
		vk.CmdEndRenderPass(main_cmd)

		cmd_transition_image_layout(
			main_cmd,
			g.screenshot_image,
			{{.COLOR}, 0, 1, 0, 1},
			{ }, { .TRANSFER_WRITE },
			.UNDEFINED, .TRANSFER_DST_OPTIMAL,
			{ .TRANSFER }, { .TRANSFER },
		)

		// blit image to screenshot image
		blit := vk.ImageBlit {
			srcSubresource = { {.COLOR}, 0, 0, 1},
			srcOffsets = { {0, 0, 0}, {i32(g.screen_image_extent.width), i32(g.screen_image_extent.height), 1} },

			dstSubresource = { {.COLOR}, 0, 0, 1},
			dstOffsets = { {0, 0, 0}, {i32(g.screen_image_extent.width), i32(g.screen_image_extent.height), 1} },
		}

		vk.CmdBlitImage(
			main_cmd,
			g.screen_image, .TRANSFER_SRC_OPTIMAL,
			g.screenshot_image, .TRANSFER_DST_OPTIMAL,
			1, &blit,
			.LINEAR,
		)

		// also copy it to copyable buffer, since there was no blit dst able format with
		// linear tiling
		cmd_transition_image_layout(
			main_cmd,
			g.screenshot_image,
			{{.COLOR}, 0, 1, 0, 1},
			{ .TRANSFER_WRITE }, { .TRANSFER_READ },
			.TRANSFER_DST_OPTIMAL, .TRANSFER_SRC_OPTIMAL,
			{ .TRANSFER }, { .TRANSFER },
		)
	
		copy_region := vk.BufferImageCopy {
			0, 0, 0,
			{{.COLOR}, 0, 0, 1},
			{0, 0, 0},
			{g.screen_image_extent.width, g.screen_image_extent.height, 1},
		}

		vk.CmdCopyImageToBuffer(
			main_cmd, 
			g.screenshot_image, 
			.TRANSFER_SRC_OPTIMAL,
			g.screenshot_copy_buffer,
			1,
			&copy_region
		)
	}

	// Imgui render pass
	{
		imgui_cmd := g.imgui_command_buffers[g.virtual_frame_index]
		vk.EndCommandBuffer(imgui_cmd)

		begin := vk.RenderPassBeginInfo {
			sType 				= .RENDER_PASS_BEGIN_INFO,
			renderPass 			= g.imgui_render_pass,

			// Todo(Leo): Luckily we can use same framebuffer. Maybe is since
			// attachments are equivalent?
			framebuffer 		= g.screen_framebuffer,		
			renderArea 			= {{0, 0}, g.screen_image_extent},
			clearValueCount 	= 0,
		}
		vk.CmdBeginRenderPass(main_cmd, &begin, .SECONDARY_COMMAND_BUFFERS)

		vk.CmdExecuteCommands(main_cmd, 1, &imgui_cmd)

		vk.CmdEndRenderPass(main_cmd)
	}

	// Pretend post process
	cmd_transition_image_layout(
		main_cmd,
		g.swapchain_images[g.swapchain_image_index],
		{{.COLOR}, 0, 1, 0, 1},
		{ /* no wait bc we acquired this alredy??? */ }, { .TRANSFER_WRITE },
		.UNDEFINED, .TRANSFER_DST_OPTIMAL,
		{ .TRANSFER }, { .TRANSFER },
	)

	blit := vk.ImageBlit {
		srcSubresource = { {.COLOR}, 0, 0, 1},
		srcOffsets = { {0, 0, 0}, {i32(g.screen_image_extent.width), i32(g.screen_image_extent.height), 1} },

		dstSubresource = { {.COLOR}, 0, 0, 1},
		dstOffsets = { {0, 0, 0}, {i32(g.swapchain_image_extent.width), i32(g.swapchain_image_extent.height), 1} },
	}

	vk.CmdBlitImage(
		main_cmd,
		g.screen_image, .TRANSFER_SRC_OPTIMAL,
		g.swapchain_images[g.swapchain_image_index], .TRANSFER_DST_OPTIMAL,
		1, &blit,
		.LINEAR,
	)

	cmd_transition_image_layout(
		main_cmd,
		g.swapchain_images[g.swapchain_image_index],
		{{.COLOR}, 0, 1, 0, 1},
		{ .TRANSFER_WRITE }, { },
		.TRANSFER_DST_OPTIMAL, .PRESENT_SRC_KHR,
		{ .TRANSFER }, { .TRANSFER },
	)

	// --- MAIN COMMAND BUFFER ------
	vk.EndCommandBuffer(main_cmd)

	// Note that fence is intentionally reset only after acquiring the next image,
	// Todo(Leo): but I cant remember why.
	vk.ResetFences(g.device, 1, &virtual_frame_in_use_fence)



	wait_semaphores := []vk.Semaphore {
		present_complete_semaphore,
	}
	wait_masks := []vk.PipelineStageFlags {
		{ .COLOR_ATTACHMENT_OUTPUT },
	}

	signal_semaphores := []vk.Semaphore {
		rendering_complete_semaphore,
	}

	main_cmd_submit_info := vk.SubmitInfo {
		sType 					= .SUBMIT_INFO,
		waitSemaphoreCount 		= u32(len(wait_semaphores)),
		pWaitSemaphores 		= raw_data(wait_semaphores),
		pWaitDstStageMask 		= raw_data(wait_masks),
		commandBufferCount 		= 1,
		pCommandBuffers 		= &main_cmd,
		signalSemaphoreCount 	= u32(len(signal_semaphores)), 
		pSignalSemaphores 		= raw_data(signal_semaphores),
	}
	main_cmd_submit_result := vk.QueueSubmit(g.graphics_queue, 1, &main_cmd_submit_info, virtual_frame_in_use_fence)
	handle_result(main_cmd_submit_result)

	// ------ PRESENT -------
	present_info := vk.PresentInfoKHR {
		sType 				= .PRESENT_INFO_KHR,
		waitSemaphoreCount 	= 1,
		pWaitSemaphores 	= &rendering_complete_semaphore,
		swapchainCount 		= 1,
		pSwapchains 		= &g.swapchain,
		pImageIndices 		= &g.swapchain_image_index,
		pResults 			= nil,
	}
	present_result := vk.QueuePresentKHR(g.present_queue, &present_info)
	handle_result(present_result)

	// NEXT VIRTUAL FRAME
	// We are done with this frame and next frame we use next frame, duh
	g.virtual_frame_index += 1
	g.virtual_frame_index %= VIRTUAL_FRAME_COUNT

}

allocate_and_begin_command_buffer :: proc() -> vk.CommandBuffer {
	g := &graphics

	allocate_info := vk.CommandBufferAllocateInfo {
		sType 				= .COMMAND_BUFFER_ALLOCATE_INFO,
		commandPool 		= g.command_pools[.Graphics],
		level 				= .PRIMARY,
		commandBufferCount 	= 1,
	}

	cmd : vk.CommandBuffer
	allocate_result := vk.AllocateCommandBuffers(g.device, &allocate_info, &cmd)
	handle_result(allocate_result)

	begin_info := vk.CommandBufferBeginInfo {
		sType = .COMMAND_BUFFER_BEGIN_INFO,
		flags = { .ONE_TIME_SUBMIT },
	}
	begin_result := vk.BeginCommandBuffer(cmd, &begin_info)
	handle_result(begin_result)

	return cmd
}

end_submit_wait_and_free_command_buffer :: proc(cmd : vk.CommandBuffer) {
	g := &graphics

	cmd := cmd

	vk.EndCommandBuffer(cmd)

	submit_info := vk.SubmitInfo {
		sType 					= .SUBMIT_INFO,
		waitSemaphoreCount 		= 0,
		commandBufferCount 		= 1,
		pCommandBuffers 		= &cmd,
		signalSemaphoreCount 	= 0,
	}

	fence_create_info := vk.FenceCreateInfo { sType = .FENCE_CREATE_INFO }
	fence : vk.Fence
	fence_create_result := vk.CreateFence(g.device, &fence_create_info, nil, &fence)
	handle_result(fence_create_result)

	vk.QueueSubmit(g.graphics_queue, 1, &submit_info, fence)

	vk.WaitForFences(g.device, 1, &fence, true, max(u64))
	vk.DestroyFence(g.device, fence, nil)

	vk.FreeCommandBuffers(g.device, g.command_pools[.Graphics], 1, &cmd)
}

copy_screenshot_buffer :: proc(allocator : runtime.Allocator) -> (width, height : int, pixels_u8_rgba : []u8) {
	g := &graphics

	width = int(g.screen_image_extent.width)
	height = int(g.screen_image_extent.height)

	size := 4 * width * height
	pixels_u8_rgba = make([]u8, size, allocator)
	copy(pixels_u8_rgba, g.screenshot_copy_mapped[0:size])

	return width, height, pixels_u8_rgba
}

@private
find_memory_type :: proc(
	requirements : vk.MemoryRequirements,
	properties : vk.MemoryPropertyFlags,
) -> u32 {
	g := &graphics

	memory_type_index := u32(0)
	memory_type_bits := requirements.memoryTypeBits

	memory_properties : vk.PhysicalDeviceMemoryProperties
	vk.GetPhysicalDeviceMemoryProperties (g.physical_device, &memory_properties)

	for i in 0..<memory_properties.memoryTypeCount {
		bits_ok 	:= (memory_type_bits & (1 << i)) != 0
		props_ok 	:= (memory_properties.memoryTypes[i].propertyFlags & properties) == properties
		
		if bits_ok && props_ok {
			memory_type_index = i
			break
		}
	}

	return memory_type_index
}

@private
create_swapchain :: proc() {	
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
	// g.swapchain_image_format = selected_format
	g.swapchain_image_extent = selected_extent

	// image_view_create_info := vk.ImageViewCreateInfo {
	// 	sType 				= .IMAGE_VIEW_CREATE_INFO,
	// 	viewType 			= .D2,
	// 	format 				= g.swapchain_image_format,
	// 	subresourceRange 	= {{ .COLOR }, 0, 1, 0, 1 }
	// }

	// g.swapchain_image_views = make([]vk.ImageView, swapchain_image_count, g.allocator)
	// for iv, i in &g.swapchain_image_views {
	// 	image_view_create_info.image = g.swapchain_images[i]
	// 	image_view_create_result := vk.CreateImageView(g.device, &image_view_create_info, nil, &iv)
	// 	handle_result(image_view_create_result)
	// }
}

@private
create_swapchain_framebuffers :: proc() {
	g := &graphics

	/*
	swapchain_image_count := len(g.swapchain_images)
	g.swapchain_framebuffers = make([]vk.Framebuffer, swapchain_image_count, g.allocator)

	for i in 0..<swapchain_image_count {
		attachments := []vk.ImageView {
			g.color_image_view,
			g.depth_image_view,
		}

		framebuffer_create_info := vk.FramebufferCreateInfo {
			sType 			= .FRAMEBUFFER_CREATE_INFO,
			renderPass 		= g.main_render_pass,
			attachmentCount = u32(len(attachments)),
			pAttachments 	= raw_data(attachments),
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
	*/
}

@private
destroy_swapchain :: proc() {
	g := &graphics

	vk.DestroySwapchainKHR(g.device, g.swapchain, nil)
	delete(g.swapchain_images)
}

@private
create_depth :: proc() {
	g := &graphics

	g.depth_image, g.depth_memory = create_image_and_memory(
		g.render_target_depth_format,
		g.render_target_extent,
		MULTI_SAMPLE_COUNT,
		.OPTIMAL,
		{
			/* render target: */		.DEPTH_STENCIL_ATTACHMENT,
		},
		{ .DEVICE_LOCAL },
	)

	image_view_create_info := vk.ImageViewCreateInfo {
		sType 				= .IMAGE_VIEW_CREATE_INFO,
		image 				= g.depth_image,
		viewType 			= .D2,
		format 				= g.render_target_depth_format,
		subresourceRange 	= {{ .DEPTH }, 0, 1, 0, 1 }
	}
	image_view_create_result := vk.CreateImageView(
		g.device,
		&image_view_create_info,
		nil,
		&g.depth_image_view
	)
	handle_result(image_view_create_result)
}

@private
destroy_depth :: proc() {
	g := &graphics

	vk.DestroyImageView(g.device, g.depth_image_view, nil)
	vk.DestroyImage(g.device, g.depth_image, nil)
	vk.FreeMemory(g.device, g.depth_memory, nil)
}

@private
create_image_view :: proc(image : vk.Image, format : vk.Format) -> vk.ImageView {
	g := &graphics

	info := vk.ImageViewCreateInfo {
		sType 				= .IMAGE_VIEW_CREATE_INFO,
		image 				= image,
		viewType 			= .D2,
		format 				= format,
		subresourceRange 	= {{ .COLOR }, 0, 1, 0, 1 }
	}

	view : vk.ImageView
	result := vk.CreateImageView(g.device, &info, nil, &view)
	handle_result(result)

	return view
}

@private
create_color :: proc() {
	g := &graphics

	g.color_image, g.color_memory = create_image_and_memory(
		g.render_target_color_format,
		g.render_target_extent,
		MULTI_SAMPLE_COUNT,
		.OPTIMAL,
		{
			/* render target: */		.COLOR_ATTACHMENT,
			/* read in post process: */	.SAMPLED,
			/* copy to screenshot: */	.TRANSFER_SRC, 
		},
		{ .DEVICE_LOCAL },
	)

	g.color_resolve_image, g.color_resolve_memory = create_image_and_memory(
		g.render_target_color_format,
		g.render_target_extent,
		{ ._1 },
		.OPTIMAL,
		{
			/* render target: */		.COLOR_ATTACHMENT,
			/* read in post process: */	.SAMPLED,
			/* copy to screenshot: */	.TRANSFER_SRC, 
		},
		{ .DEVICE_LOCAL },
	)

	g.color_image_view = create_image_view(g.color_image, g.render_target_color_format)
	g.color_resolve_image_view = create_image_view(g.color_resolve_image, g.render_target_color_format)

	// Samplable image for post processor
	{
		image_info := vk.DescriptorImageInfo{
			sampler 	= g.linear_sampler,
			imageView 	= g.color_resolve_image_view,
			imageLayout = .SHADER_READ_ONLY_OPTIMAL,
		}

		write := vk.WriteDescriptorSet {
			sType 			= .WRITE_DESCRIPTOR_SET,
			dstSet 			= g.color_image_descriptor_set,
			dstBinding 		= 0,
			dstArrayElement = 0,
			descriptorType 	= .COMBINED_IMAGE_SAMPLER,
			descriptorCount = 1,
			pImageInfo 		= &image_info,
		}
		vk.UpdateDescriptorSets(g.device, 1, &write, 0, nil)
	}
}

@private
destroy_color :: proc() {
	g := &graphics

	vk.DestroyImageView(g.device, g.color_image_view, nil)
	vk.DestroyImage(g.device, g.color_image, nil)
	vk.FreeMemory(g.device, g.color_memory, nil)

	vk.DestroyImageView(g.device, g.color_resolve_image_view, nil)
	vk.DestroyImage(g.device, g.color_resolve_image, nil)
	vk.FreeMemory(g.device, g.color_resolve_memory, nil)
}

@private
create_screeen :: proc() {
	g := &graphics

	fmt.println("[GRAPHICS]: screen created")

	// Screen render target image

	{
		width, height := window.get_window_size()
		g.screen_image_extent.width 	= u32(width)
		g.screen_image_extent.height 	= u32(height)

		g.screen_image, g.screen_memory = create_image_and_memory(
			g.screen_image_format,
			g.screen_image_extent,
			{ ._1 },
			.OPTIMAL,
			{
				/* render target: */		.COLOR_ATTACHMENT,
				/* copy to screenshot: */	.TRANSFER_SRC, 
			},
			{ .DEVICE_LOCAL },
		)
	}

	// Image view to use as an attachment
	{
		image_view_create_info := vk.ImageViewCreateInfo {
			sType 				= .IMAGE_VIEW_CREATE_INFO,
			image 				= g.screen_image,
			viewType 			= .D2,
			format 				= g.screen_image_format,
			subresourceRange 	= {{ .COLOR }, 0, 1, 0, 1 }
		}
		image_view_create_result := vk.CreateImageView(
			g.device,
			&image_view_create_info,
			nil,
			&g.screen_image_view
		)
		handle_result(image_view_create_result)
	}

	// Framebuffer
	{
		attachment := g.screen_image_view

		framebuffer_create_info := vk.FramebufferCreateInfo {
			sType 			= .FRAMEBUFFER_CREATE_INFO,
			renderPass 		= g.screen_render_pass,
			attachmentCount = 1,
			pAttachments 	= &attachment,
			width 			= g.screen_image_extent.width,
			height 			= g.screen_image_extent.height,
			layers 			= 1,
		}

		framebuffer_create_result := vk.CreateFramebuffer(
			g.device, 
			&framebuffer_create_info, 
			nil,
			&g.screen_framebuffer,
		)
		handle_result(framebuffer_create_result)
	}

	// Screenshot image
	{
		g.screenshot_format	= .R8G8B8A8_UNORM

		// {
		// 	props3 := vk.FormatProperties3 {
		// 		sType = .FORMAT_PROPERTIES_3,
		// 	}
		// 	props2 := vk.FormatProperties2 {
		// 		sType = .FORMAT_PROPERTIES_2,
		// 		pNext = &props3,
		// 	}
		// 	vk.GetPhysicalDeviceFormatProperties2(g.physical_device, g.screenshot_format, &props2)
		
		// 	fmt.println(props2)
		// }

		image_create_info := vk.ImageCreateInfo {
			sType 					= .IMAGE_CREATE_INFO,
			imageType 				= .D2,
			format 					= g.screenshot_format,
			extent 					= {g.screen_image_extent.width, g.screen_image_extent.height, 1},
			mipLevels 				= 1,
			arrayLayers 			= 1,
			samples 				= { ._1 },
			tiling 					= .OPTIMAL,
			usage 					= { .TRANSFER_DST, .TRANSFER_SRC },
			sharingMode 			= .EXCLUSIVE,
			queueFamilyIndexCount 	= 1,
			pQueueFamilyIndices 	= &g.graphics_queue_family,
			initialLayout 			= .UNDEFINED,
		}
		image_create_result := vk.CreateImage(
			g.device,
			&image_create_info,
			nil,
			&g.screenshot_image,
		)
		handle_result(image_create_result)

		memory_requirements := get_image_memory_requirements(g.screenshot_image)
		memory_type_index := find_memory_type(memory_requirements, { .DEVICE_LOCAL } )

		allocate_info := vk.MemoryAllocateInfo {
			sType 			= .MEMORY_ALLOCATE_INFO,
			allocationSize 	= memory_requirements.size,
			memoryTypeIndex = memory_type_index, 
		}
		allocate_result := vk.AllocateMemory(g.device, &allocate_info, nil, &g.screenshot_memory)
		handle_result(allocate_result)

		vk.BindImageMemory(g.device, g.screenshot_image, g.screenshot_memory, 0)
	}

	// Screenshot copy memory
	{
		memory_size := vk.DeviceSize (4 * g.screen_image_extent.width * g.screen_image_extent.height)
		g.screenshot_copy_buffer, g.screenshot_copy_memory = create_buffer_and_memory(
			memory_size,
			{ .TRANSFER_DST },
			{ .HOST_VISIBLE, .HOST_COHERENT },
		)
		g.screenshot_copy_mapped = cast([^]u8) map_memory(g.screenshot_copy_memory, 0, memory_size)
	}
}

@private
destroy_screeen :: proc() {
	g := &graphics

	vk.DestroyImageView(g.device, g.screen_image_view, nil)
	vk.DestroyImage(g.device, g.screen_image, nil)
	vk.FreeMemory(g.device, g.screen_memory, nil)

	vk.DestroyFramebuffer(g.device, g.screen_framebuffer, nil)

	vk.DestroyImage(g.device, g.screenshot_image, nil)
	vk.FreeMemory(g.device, g.screenshot_memory, nil)

	vk.DestroyBuffer(g.device, g.screenshot_copy_buffer, nil)
	vk.FreeMemory(g.device, g.screenshot_copy_memory, nil)
}

@private
create_buffer_and_memory :: proc(
	#any_int size 		: vk.DeviceSize,
	usage 				: vk.BufferUsageFlags,
	memory_properties 	: vk.MemoryPropertyFlags,
	loc := #caller_location,
) -> (vk.Buffer, vk.DeviceMemory) {
	g := &graphics

	buffer : vk.Buffer
	memory : vk.DeviceMemory

	create_info := vk.BufferCreateInfo {
		sType 		= .BUFFER_CREATE_INFO,
		pNext 		= nil,
		flags 		= {},
		size 		= size,
		usage 		= usage,
		sharingMode = .EXCLUSIVE,
	}
	create_result := vk.CreateBuffer(g.device, &create_info, nil, &buffer)
	handle_result(create_result)

	memory_requirements := get_buffer_memory_requirements(buffer)

	memory_type := find_memory_type(memory_requirements, memory_properties)

	allocate_info := vk.MemoryAllocateInfo {
		sType 			= .MEMORY_ALLOCATE_INFO,
		pNext 			= nil,
		allocationSize 	= memory_requirements.size,
		memoryTypeIndex = memory_type,
	}
	allocate_result := vk.AllocateMemory(g.device, &allocate_info, nil, &memory)
	handle_result(allocate_result)

	vk.BindBufferMemory(g.device, buffer, memory, 0)

	return buffer, memory
}

@private
get_buffer_memory_requirements :: proc(buffer : vk.Buffer) -> (res : vk.MemoryRequirements) {
	vk.GetBufferMemoryRequirements(graphics.device, buffer, &res)
	return
}

@private
create_image_and_memory :: proc(
	format 				: vk.Format,
	extent 				: vk.Extent2D,
	samples 			: vk.SampleCountFlags,
	tiling 				: vk.ImageTiling,
	usage 				: vk.ImageUsageFlags,
	memory_properties 	: vk.MemoryPropertyFlags,
) -> (vk.Image, vk.DeviceMemory) {
	g := &graphics

	image 	: vk.Image
	memory 	: vk.DeviceMemory

	image_create_info := vk.ImageCreateInfo {
		sType 					= .IMAGE_CREATE_INFO,
		imageType 				= .D2,
		format 					= format,
		extent 					= {extent.width, extent.height, 1},
		mipLevels 				= 1,
		arrayLayers 			= 1,
		samples 				= samples,
		tiling 					= tiling,
		usage 					= usage,
		sharingMode 			= .EXCLUSIVE,
		queueFamilyIndexCount 	= 1,
		pQueueFamilyIndices 	= &g.graphics_queue_family,
		initialLayout 			= .UNDEFINED,
	}
	image_create_result := vk.CreateImage(
		g.device,
		&image_create_info,
		nil,
		&image,
	)
	handle_result(image_create_result)

	memory_requirements := get_image_memory_requirements(image)
	memory_type_index := find_memory_type(memory_requirements, memory_properties )

	allocate_info := vk.MemoryAllocateInfo {
		sType 			= .MEMORY_ALLOCATE_INFO,
		allocationSize 	= memory_requirements.size,
		memoryTypeIndex = memory_type_index, 
	}
	allocate_result := vk.AllocateMemory(g.device, &allocate_info, nil, &memory)
	handle_result(allocate_result)

	vk.BindImageMemory(g.device, image, memory, 0)

	return image, memory
}

@private
get_image_memory_requirements :: proc(image : vk.Image) -> (res : vk.MemoryRequirements) {
	vk.GetImageMemoryRequirements(graphics.device, image, &res)
	return
}

@private
cmd_transition_image_layout :: proc(
	cmd 				: vk.CommandBuffer,
	image 				: vk.Image,
	subresource_range 	: vk.ImageSubresourceRange,
	src_access_mask 	: vk.AccessFlags,
	dst_access_mask 	: vk.AccessFlags,
	old_layout 			: vk.ImageLayout,
	new_layout 			: vk.ImageLayout,
	src_stage_mask 		: vk.PipelineStageFlags,
	dst_stage_mask 		: vk.PipelineStageFlags,
) {
	barrier := vk.ImageMemoryBarrier{
		sType 				= .IMAGE_MEMORY_BARRIER,
		srcAccessMask		= src_access_mask,
		dstAccessMask 		= dst_access_mask,
		oldLayout 			= old_layout,
		newLayout 			= new_layout,
		srcQueueFamilyIndex = vk.QUEUE_FAMILY_IGNORED,
		dstQueueFamilyIndex = vk.QUEUE_FAMILY_IGNORED,
		image 				= image,
		subresourceRange 	= subresource_range
	}

	vk.CmdPipelineBarrier(
		cmd,
		src_stage_mask, dst_stage_mask,
		{ /* no flags */ },
		0, nil,
		0, nil,
		1, &barrier,
	)
}