package graphics

// For reading the shader spirv files
import "core:os"

import vk "vendor:vulkan"

// These are no longer gloabally same
// PER_FRAME_BUFFER_BINDING 	:: 0
// LIGHTING_BUFFER_BINDING 	:: 1
// WIND_BUFFER_BINDING 		:: 2
// WORLD_BUFFER_BINDING 		:: 3

// DEBUG_BUFFER_BINDING 		:: 20

// GRASS_TYPES_BUFFER_BINDING 		:: 10
// GRASS_INSTANCE_BUFFER_BINDING 	:: 11

@private
PerFrameUniformBuffer :: struct #align(16) {
	projection 	: mat4,
	view 		: mat4,
}
#assert(size_of(PerFrameUniformBuffer) == 128)

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
	per_frame : UniformStuff(PerFrameUniformBuffer),
	lighting : UniformStuff(LightingUniformBuffer),
}

@private
create_pipelines :: proc() {
	g := &graphics
	shared := &graphics.pipeline_shared

	shared.per_frame = create_uniform_stuff(PerFrameUniformBuffer, { .VERTEX })
	shared.lighting = create_uniform_stuff(LightingUniformBuffer, { .FRAGMENT })

	create_sky_pipeline()
	create_basic_pipeline()
}

@private
destroy_pipelines :: proc() {
	g := &graphics
	shared := &graphics.pipeline_shared

	destroy_uniform_stuff(&shared.per_frame)
	destroy_uniform_stuff(&shared.lighting)

	destroy_sky_pipeline()
	destroy_basic_pipeline()
}

// Shared
set_per_frame_data :: proc(view, projection : mat4) {
	graphics.pipeline_shared.per_frame.mapped^ = {
		projection 	= projection,
		view 		= view,
	}
}

set_lighting_data :: proc(camera_position, directional_direction, directional_color, ambient_color : vec3) {
	graphics.pipeline_shared.lighting.mapped^ = {
		camera_position 	= expand_to_vec4(camera_position, 1),
		light_direction 	= expand_to_vec4(directional_direction, 0),
		light_color 		= expand_to_vec4(directional_color, 1),
		ambient_color 		= expand_to_vec4(ambient_color, 1),
	}
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
create_pipeline_layout :: proc (
	set_layouts : []vk.DescriptorSetLayout,
	loc := #caller_location,
) -> vk.PipelineLayout {
	info := vk.PipelineLayoutCreateInfo {
		sType 					= .PIPELINE_LAYOUT_CREATE_INFO,
		pNext 					= nil,
		flags 					= {},
		setLayoutCount 			= u32(len(set_layouts)),
		pSetLayouts 			= raw_data(set_layouts),
		pushConstantRangeCount 	= 0,
		pPushConstantRanges 	= nil
	}

	layout : vk.PipelineLayout
	result := vk.CreatePipelineLayout(graphics.device, &info, nil, &layout)
	handle_result(result)

	return layout
}

@private
UniformStuff :: struct($Data : typeid) {
	descriptor_set_layout 	: vk.DescriptorSetLayout,
	descriptor_set 			: vk.DescriptorSet,

	buffer : vk.Buffer,
	memory : vk.DeviceMemory,
	mapped : ^Data,
}

@private
create_uniform_stuff :: proc($Data : typeid, stages : vk.ShaderStageFlags) -> UniformStuff(Data) {
	g := &graphics

	us := UniformStuff(Data) {}

	// DESCRIPTOR SET LAYOUT
	binding := vk.DescriptorSetLayoutBinding {
		0, .UNIFORM_BUFFER, 1, stages, nil
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
		&us.descriptor_set_layout,
	)

	// BUFFER
	buffer_size := vk.DeviceSize(size_of(Data))
	buffer_create_info := vk.BufferCreateInfo {
		sType 		= .BUFFER_CREATE_INFO,
		size 		= buffer_size,
		usage 		= { .UNIFORM_BUFFER },
		sharingMode = .EXCLUSIVE,
	}
	buffer_create_result := vk.CreateBuffer(g.device, &buffer_create_info, nil, &us.buffer)
	handle_result(buffer_create_result)

	buffer_memory_requirements : vk.MemoryRequirements
	vk.GetBufferMemoryRequirements(g.device, us.buffer, &buffer_memory_requirements)

	memory_type_index := find_memory_type(buffer_memory_requirements, {.HOST_VISIBLE, .HOST_COHERENT})

	allocate_info := vk.MemoryAllocateInfo {
		sType 			= .MEMORY_ALLOCATE_INFO,
		allocationSize 	= buffer_memory_requirements.size,
		memoryTypeIndex = memory_type_index, 
	}
	allocate_result := vk.AllocateMemory(g.device, &allocate_info, nil, &us.memory)
	handle_result(allocate_result)

	vk.BindBufferMemory(g.device, us.buffer, us.memory, 0)

	vk.MapMemory(
		g.device, 
		us.memory, 
		0, 
		buffer_size, 
		{}, 
		cast(^rawptr)&us.mapped,
	)

	// Descriptor Set
	descriptor_allocate_info := vk.DescriptorSetAllocateInfo {
		sType 				= .DESCRIPTOR_SET_ALLOCATE_INFO,
		descriptorPool 		= g.descriptor_pool,
		descriptorSetCount 	= 1,
		pSetLayouts 		= &us.descriptor_set_layout,
	}
	descriptor_allocate_result := vk.AllocateDescriptorSets(
		g.device,
		&descriptor_allocate_info,
		&us.descriptor_set,
	)
	handle_result(descriptor_allocate_result)

	buffer_info := vk.DescriptorBufferInfo {
		buffer 	= us.buffer,
		offset 	= 0,
		range 	= vk.DeviceSize(buffer_size),
	}

	write := vk.WriteDescriptorSet {
		sType 			= .WRITE_DESCRIPTOR_SET,
		dstSet 			= us.descriptor_set,
		dstBinding 		= 0,
		dstArrayElement = 0,
		descriptorType 	= .UNIFORM_BUFFER,
		descriptorCount = 1,
		pBufferInfo 	= &buffer_info,
	}
	vk.UpdateDescriptorSets(g.device, 1, &write, 0, nil)

	return us
}

@private
destroy_uniform_stuff :: proc(us : ^UniformStuff($Data)) {
	g := &graphics

	vk.DestroyDescriptorSetLayout(g.device, us.descriptor_set_layout, nil)
	vk.FreeMemory(g.device, us.memory, nil)
	vk.DestroyBuffer(g.device, us.buffer, nil)
}

@private
pipeline_shader_stage :: proc(
	device 			: vk.Device, 
	spirv_file_name : string, 
	stage 			: vk.ShaderStageFlags, 
	loc := #caller_location
) -> vk.PipelineShaderStageCreateInfo {
	code, ok := os.read_entire_file(spirv_file_name)
	defer delete(code)
	assert(ok)

	info := vk.ShaderModuleCreateInfo {
		sType 		= .SHADER_MODULE_CREATE_INFO, 
		codeSize 	= len(code),
		pCode 		= cast(^u32) raw_data(code)
	}
	module : vk.ShaderModule
	result := vk.CreateShaderModule(device, &info, nil, &module)
	handle_result(result, loc)

	return {
		sType = .PIPELINE_SHADER_STAGE_CREATE_INFO,
		pNext = nil,
		flags = {},
		stage = stage,
		module = module,
		pName = "main",
	}
}


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
pipeline_rasterization :: proc(cull_mode : vk.CullModeFlags)-> vk.PipelineRasterizationStateCreateInfo {
	return {
		sType 					= .PIPELINE_RASTERIZATION_STATE_CREATE_INFO,
		depthClampEnable 		= VK_FALSE,
		rasterizerDiscardEnable = VK_FALSE,
		polygonMode 			= .FILL,
		lineWidth 				= 1.0,
		cullMode	 			= cull_mode,
		frontFace 				= .COUNTER_CLOCKWISE,
		depthBiasEnable			= VK_FALSE,
	}
}

@private
pipeline_depth_stencil :: proc() -> vk.PipelineDepthStencilStateCreateInfo {
	return {
		sType 					= .PIPELINE_DEPTH_STENCIL_STATE_CREATE_INFO,
		pNext 					= nil,
		flags 					= {},
		depthTestEnable 		= VK_TRUE,
		depthWriteEnable 		= VK_TRUE,
		depthCompareOp 			= .LESS_OR_EQUAL,
		depthBoundsTestEnable 	= VK_FALSE,
		stencilTestEnable 		= VK_FALSE,
		front 					= {},
		back 					= {},
		minDepthBounds 			= 0.0,
		maxDepthBounds 			= 1.0,
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

// Rare(shiny?) helpers??? Or move to somewhere else?
expand_to_vec4 :: proc(v : vec3, w : f32) -> vec4 {
	return {v.x, v.y, v.z, w}
}