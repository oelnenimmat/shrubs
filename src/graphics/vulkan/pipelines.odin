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

	// texture_descriptor_set_layout : vk.DescriptorSetLayout,
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
	push_constants : []vk.PushConstantRange,
	loc := #caller_location,
) -> vk.PipelineLayout {
	info := vk.PipelineLayoutCreateInfo {
		sType 					= .PIPELINE_LAYOUT_CREATE_INFO,
		pNext 					= nil,
		flags 					= {},
		setLayoutCount 			= u32(len(set_layouts)),
		pSetLayouts 			= raw_data(set_layouts),
		pushConstantRangeCount 	= u32(len(push_constants)),
		pPushConstantRanges 	= raw_data(push_constants),
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
	us.buffer, us.memory = create_buffer_and_memory(
		buffer_size,
		{ .UNIFORM_BUFFER },
		{ .HOST_VISIBLE, .HOST_COHERENT }
	)

	vk.MapMemory(
		g.device, 
		us.memory, 
		0, 
		buffer_size, 
		{}, 
		cast(^rawptr)&us.mapped,
	)

	// Descriptor Set
	us.descriptor_set = allocate_descriptor_set(us.descriptor_set_layout)
	descriptor_set_write_buffer(us.descriptor_set, 0, us.buffer, 0, buffer_size)

	return us
}

@private
allocate_descriptor_set :: proc(
	layout : vk.DescriptorSetLayout,
	loc := #caller_location,
) -> vk.DescriptorSet {
	g := &graphics

	layout := layout

	info := vk.DescriptorSetAllocateInfo {
		sType = .DESCRIPTOR_SET_ALLOCATE_INFO,
		descriptorPool = g.descriptor_pool,
		descriptorSetCount = 1,
		pSetLayouts = &layout,
	}

	set : vk.DescriptorSet
	result := vk.AllocateDescriptorSets(g.device, &info, &set)
	handle_result(result, loc)

	return set
}

@private
descriptor_set_write_buffer :: proc(
	set 			: vk.DescriptorSet, 
	binding 		: u32,
	buffer 			: vk.Buffer,
	#any_int offset : vk.DeviceSize,
	#any_int size 	: vk.DeviceSize,
) {
	g := &graphics

	buffer_info := vk.DescriptorBufferInfo {
		buffer 	= buffer,
		offset 	= offset,
		range 	= size,
	}			

	write := vk.WriteDescriptorSet {
		sType 			= .WRITE_DESCRIPTOR_SET,
		dstSet 			= set,
		dstBinding 		= binding,
		dstArrayElement = 0,
		descriptorType 	= .UNIFORM_BUFFER,
		descriptorCount = 1,
		pBufferInfo 	= &buffer_info,
	}
	vk.UpdateDescriptorSets(g.device, 1, &write, 0, nil)
}

@private
descriptor_set_write_texture :: proc(
	set 	: vk.DescriptorSet, 
	binding : u32,
	texture : ^Texture,
) {
	g := &graphics

	image_info := vk.DescriptorImageInfo {
		sampler 	= g.linear_sampler,
		imageView 	= texture.image_view,
		imageLayout = .SHADER_READ_ONLY_OPTIMAL,
	}			

	write := vk.WriteDescriptorSet {
		sType 			= .WRITE_DESCRIPTOR_SET,
		dstSet 			= set,
		dstBinding 		= binding,
		dstArrayElement = 0,
		descriptorType 	= .COMBINED_IMAGE_SAMPLER,
		descriptorCount = 1,
		pImageInfo 		= &image_info,
	}
	vk.UpdateDescriptorSets(g.device, 1, &write, 0, nil)
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
pipeline_vertex_input :: proc(
	bindings 	: []vk.VertexInputBindingDescription = nil,
	attributes 	: []vk.VertexInputAttributeDescription = nil,
) -> vk.PipelineVertexInputStateCreateInfo {
	return { 
		sType 							= .PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO,
		pNext 							= nil,
		flags 							= {},
		vertexBindingDescriptionCount 	= u32(len(bindings)),
		pVertexBindingDescriptions 		= raw_data(bindings),
		vertexAttributeDescriptionCount = u32(len(attributes)),
		pVertexAttributeDescriptions 	= raw_data(attributes)
	}
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