package graphics

import vk "vendor:vulkan"

PER_FRAME_BUFFER_BINDING 	:: 0
LIGHTING_BUFFER_BINDING 	:: 1
WIND_BUFFER_BINDING 		:: 2
WORLD_BUFFER_BINDING 		:: 3

DEBUG_BUFFER_BINDING 		:: 20

GRASS_TYPES_BUFFER_BINDING 		:: 10
GRASS_INSTANCE_BUFFER_BINDING 	:: 11

@private
LightingUniformBuffer :: struct #align(16) {
	camera_position : vec4,
	light_direction : vec4,
	light_color 	: vec4,
	ambient_color 	: vec4,
}
#assert(size_of(LightingUniformBuffer) == 64)

@private
PipelineShared :: struct {
	lighting_descriptor_set_layout 	: vk.DescriptorSetLayout,
	lighting_descriptor_set 		: vk.DescriptorSet,
	lighting_memory 				: vk.DeviceMemory,
	lighting_buffer 				: vk.Buffer,
	lighting_buffer_mapped 			: ^LightingUniformBuffer,

	pipeline_layout : vk.PipelineLayout,
}

@private
create_pipelines :: proc() {
	g := &graphics
	shared := &graphics.pipeline_shared

	// Lighting
	{
		// DESCRIPTOR SET LAYOUT
		binding := vk.DescriptorSetLayoutBinding {
			LIGHTING_BUFFER_BINDING, .UNIFORM_BUFFER, 1, { .FRAGMENT }, nil
		}

		layout_create_info := vk.DescriptorSetLayoutCreateInfo {
			sType 			= .DESCRIPTOR_SET_LAYOUT_CREATE_INFO,
			bindingCount 	= 1,
			pBindings 		= &binding
		}
		layout_create_result := vk.CreateDescriptorSetLayout(
			g.device,
			&layout_create_info,
			nil,
			&shared.lighting_descriptor_set_layout,
		)

		// BUFFER
		buffer_size := size_of(LightingUniformBuffer)
		buffer_create_info := vk.BufferCreateInfo {
			sType 		= .BUFFER_CREATE_INFO,
			size 		= vk.DeviceSize(buffer_size),
			usage 		= { .UNIFORM_BUFFER },
			sharingMode = .EXCLUSIVE,
		}
		buffer_create_result := vk.CreateBuffer(g.device, &buffer_create_info, nil, &shared.lighting_buffer)
		handle_result(buffer_create_result)

		buffer_memory_requirements : vk.MemoryRequirements
		vk.GetBufferMemoryRequirements(g.device, shared.lighting_buffer, &buffer_memory_requirements)

		requested_properties := vk.MemoryPropertyFlags {.HOST_VISIBLE | .HOST_COHERENT }

		memory_type_index := u32(0)
		{
			memory_type_bits := buffer_memory_requirements.memoryTypeBits

			memory_properties : vk.PhysicalDeviceMemoryProperties
			vk.GetPhysicalDeviceMemoryProperties (g.physical_device, &memory_properties)

			for i in 0..<memory_properties.memoryTypeCount {
				bits_ok 	:= (memory_type_bits & (1 << i)) != 0
				props_ok 	:= (memory_properties.memoryTypes[i].propertyFlags & requested_properties) == requested_properties
				
				if bits_ok && props_ok {
					memory_type_index = i
					break
				}
			}
		}

		allocate_info := vk.MemoryAllocateInfo {
			sType = .MEMORY_ALLOCATE_INFO,
			allocationSize = size_of(LightingUniformBuffer),
			memoryTypeIndex = memory_type_index, 
		}
		allocate_result := vk.AllocateMemory(g.device, &allocate_info, nil, &shared.lighting_memory)
		handle_result(allocate_result)

		vk.BindBufferMemory(g.device, shared.lighting_buffer, shared.lighting_memory, 0)

		vk.MapMemory(
			g.device, 
			shared.lighting_memory, 
			0, 
			size_of(LightingUniformBuffer), 
			{}, 
			cast(^rawptr)&shared.lighting_buffer_mapped,
		)

		// Descriptor Set
		descriptor_allocate_info := vk.DescriptorSetAllocateInfo {
			sType 				= .DESCRIPTOR_SET_ALLOCATE_INFO,
			descriptorPool 		= g.descriptor_pool,
			descriptorSetCount 	= 1,
			pSetLayouts 		= &shared.lighting_descriptor_set_layout,
		}
		descriptor_allocate_result := vk.AllocateDescriptorSets(
			g.device,
			&descriptor_allocate_info,
			&shared.lighting_descriptor_set,
		)
		handle_result(descriptor_allocate_result)

		buffer_info := vk.DescriptorBufferInfo {
			buffer 	= shared.lighting_buffer,
			offset 	= 0,
			range 	= vk.DeviceSize(buffer_size),
		}

		write := vk.WriteDescriptorSet {
			sType 			= .WRITE_DESCRIPTOR_SET,
			dstSet 			= shared.lighting_descriptor_set,
			dstBinding 		= 1,
			dstArrayElement = 0,
			descriptorType 	= .UNIFORM_BUFFER,
			descriptorCount = 1,
			pBufferInfo 	= &buffer_info,
		}
		vk.UpdateDescriptorSets(g.device, 1, &write, 0, nil)
	}

	// Layout
	{
		layout_create_info := vk.PipelineLayoutCreateInfo {
			sType 			= .PIPELINE_LAYOUT_CREATE_INFO,
			setLayoutCount 	= 1,
			pSetLayouts 	= &shared.lighting_descriptor_set_layout,
		}
		layout_create_result := vk.CreatePipelineLayout(
			g.device, 
			&layout_create_info, 
			nil, 
			&shared.pipeline_layout,
		)
		handle_result(layout_create_result)
	}

	create_sky_pipeline()
}

@private
destroy_pipelines :: proc() {
	g := &graphics
	shared := &graphics.pipeline_shared

	vk.DestroyDescriptorSetLayout(g.device, shared.lighting_descriptor_set_layout, nil)
	vk.FreeMemory(g.device, shared.lighting_memory, nil)
	vk.DestroyBuffer(g.device, shared.lighting_buffer, nil)
	vk.DestroyPipelineLayout(g.device, shared.pipeline_layout, nil)

	destroy_sky_pipeline()
}

// Shared
set_per_frame_data :: proc(view, projection : mat4) {}

set_lighting_data :: proc(camera_position, directional_direction, directional_color, ambient_color : vec3) {
	g := &graphics
	shared := &graphics.pipeline_shared

	shared.lighting_buffer_mapped.camera_position.xyz 	= camera_position
	shared.lighting_buffer_mapped.light_direction.xyz 	= directional_direction
	shared.lighting_buffer_mapped.light_color.rgb 		= directional_color
	shared.lighting_buffer_mapped.ambient_color.rgb 	= ambient_color

	main_cmd := g.main_command_buffers[g.virtual_frame_index]

	vk.CmdBindDescriptorSets(main_cmd, .GRAPHICS, shared.pipeline_layout, 0, 1, &shared.lighting_descriptor_set, 0, nil)
}

set_wind_data :: proc(texture_offset : vec2, texture_scale : f32, texture : ^Texture) {}
set_world_data :: proc(scale, offset : vec2) {}
set_debug_data :: proc(draw_normals, draw_backfacing, draw_lod : bool) {}

// Others
setup_basic_pipeline :: proc () {}
set_basic_material :: proc(color : vec3, texture : ^Texture) {}

setup_debug_pipeline :: proc () {}
draw_debug_mesh :: proc(mesh : ^Mesh, model : mat4, color : vec3) {}

setup_emissive_pipeline :: proc() {}
set_emissive_material :: proc(texture : ^Texture) {}

setup_grass_pipeline :: proc(cull_back : bool) {}
GrassRenderer :: struct {}
create_grass_renderer :: proc(instance_buffer : ^Buffer) -> GrassRenderer {
	return {}
}
destroy_grass_renderer :: proc(gr : ^GrassRenderer) {}
draw_grass :: proc(gr : GrassRenderer, instance_count : int, segment_count : int, lod : int) {}

dispatch_grass_placement_pipeline :: proc (
	instances 				: ^Buffer,
	placement_texture 		: ^Texture,
	blade_count 			: int,
	chunk_position 			: vec2,
	chunk_size 				: f32,
	type_index				: int,
	noise_params 			: vec4,
) {}

dispatch_post_process_pipeline :: proc(render_target : ^RenderTarget, exposure : f32) {}

setup_terrain_pipeline :: proc () {}
set_terrain_material :: proc(
	splatter_texture : ^Texture,
	grass_texture : ^Texture,
	road_texture : ^Texture,
) {}

// HElpers?
@private
pipeline_dynamic :: proc(states : []vk.DynamicState) -> vk.PipelineDynamicStateCreateInfo 
{
	return {
		sType 				= .PIPELINE_DYNAMIC_STATE_CREATE_INFO,
		pNext 				= nil,
		flags 				= {},
		dynamicStateCount 	= u32(len(states)),
		pDynamicStates 		= raw_data(states),
	}
}

@private
pipeline_vertex_input :: proc() -> vk.PipelineVertexInputStateCreateInfo {
	return { sType = .PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO }
}

@private
pipeline_input_assembly :: proc(topology : vk.PrimitiveTopology) -> vk.PipelineInputAssemblyStateCreateInfo
{
	return {
		sType 					= .PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO,
		pNext 					= nil,
		flags 					= {},
		topology 				= topology,
		primitiveRestartEnable 	= false,
	}
}

@private
pipeline_viewport :: proc() -> vk.PipelineViewportStateCreateInfo {
	return {
		sType = .PIPELINE_VIEWPORT_STATE_CREATE_INFO,
		pNext 			= nil,
		flags 			= {},
		viewportCount 	= 1,
		pViewports 		= nil,
		scissorCount 	= 1,
		pScissors 		= nil
	}
}

@private
pipeline_rasterization :: proc()-> vk.PipelineRasterizationStateCreateInfo {
	return {
		sType 					= .PIPELINE_RASTERIZATION_STATE_CREATE_INFO,
		depthClampEnable 		= VK_FALSE,
		rasterizerDiscardEnable = VK_FALSE,
		polygonMode 			= .FILL,
		lineWidth 				= 1.0,
		cullMode	 			= { .BACK },
		frontFace 				= .CLOCKWISE,
		depthBiasEnable			= VK_FALSE,
	}
}

@private
pipeline_multisample :: proc() -> vk.PipelineMultisampleStateCreateInfo {
	return {
		sType 					= .PIPELINE_MULTISAMPLE_STATE_CREATE_INFO,
		sampleShadingEnable 	= VK_FALSE,
		rasterizationSamples 	= { ._1 },
		minSampleShading 		= 1.0,
		pSampleMask 			= nil,
		alphaToCoverageEnable 	= VK_FALSE,
		alphaToOneEnable 		= VK_FALSE,
	}
}

@private
pipeline_color_blend_attachment :: proc() -> vk.PipelineColorBlendAttachmentState {
	return {
		colorWriteMask 	= { .R, .G, .B },
		blendEnable 	= VK_FALSE,
	}
}

@private
pipeline_color_blend :: proc(
	attachments : []vk.PipelineColorBlendAttachmentState
) -> vk.PipelineColorBlendStateCreateInfo {
	return {
		sType 			= .PIPELINE_COLOR_BLEND_STATE_CREATE_INFO,
		logicOpEnable 	= VK_FALSE,
		attachmentCount = u32(len(attachments)),
		pAttachments 	= raw_data(attachments),
	}
}