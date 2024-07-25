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

// Shared
set_per_frame_data :: proc(view, projection : mat4) {
	graphics.pipelines.shared.per_frame.mapped^ = {
		projection 	= projection,
		view 		= view,
	}
}

set_lighting_data :: proc(camera_position, directional_direction, directional_color, ambient_color : vec3) {
	graphics.pipelines.shared.lighting.mapped^ = {
		camera_position 	= expand_to_vec4(camera_position, 1),
		light_direction 	= expand_to_vec4(directional_direction, 0),
		light_color 		= expand_to_vec4(directional_color, 1),
		ambient_color 		= expand_to_vec4(ambient_color, 1),
	}
}

get_grass_types_mapped :: proc() -> []GrassTypeUniformData {
	return graphics.pipelines.shared.grass_types.mapped[:]
}

set_wind_data :: proc(offset : vec2, scale : f32, texture : ^Texture) {
	wind := &graphics.pipelines.shared.wind

	wind.mapped^ = { offset, scale, 0 }

	if texture != nil {
		descriptor_set_write_textures(wind.set, 1, {texture})
	} 
}

set_world_data :: proc(scale, offset : vec2, noise_params : vec4, placement_texture : ^Texture) {
	world := &graphics.pipelines.shared.world

	world.mapped^ = {
		placement_scale = scale,
		placement_offset = offset,

		world_seed 			= noise_params.x,
		world_to_grid_scale = noise_params.y,
		terrain_z_scale 	= noise_params.z,
		terrain_z_offset 	= noise_params.w,
	}

	if placement_texture != nil {
		descriptor_set_write_textures(world.set, 1, {placement_texture})
	}
}
set_debug_data :: proc(draw_normals, draw_backfacing, draw_lod : bool) {}

// Others
setup_debug_pipeline :: proc () {}
draw_debug_mesh :: proc(mesh : ^Mesh, model : mat4, color : vec3) {}

setup_emissive_pipeline :: proc() {}
set_emissive_material :: proc(texture : ^Texture) {}

dispatch_post_process_pipeline :: proc(render_target : ^RenderTarget, exposure : f32) {}

///////////////////////////////////////////////////////////////////////////////
// Private (as in "graphics only")

///////////////////////////////////////////////////////////////////////////////
// Shared

@private
PerFrameUniformData :: struct #align(16) {
	projection 	: mat4,
	view 		: mat4,
}
#assert(size_of(PerFrameUniformData) == 128)

@private
LightingUniformData :: struct #align(16) {
	camera_position : vec4,
	light_direction : vec4,
	light_color 	: vec4,
	ambient_color 	: vec4,
}
#assert(size_of(LightingUniformData) == 64)

@private
WorldUniformData :: struct #align(16) {
	placement_scale : vec2,
	placement_offset : vec2,

	world_seed 			: f32,
	world_to_grid_scale : f32,
	terrain_z_scale 	: f32,
	terrain_z_offset 	: f32,
}
#assert(size_of(WorldUniformData) == 32)

@private
WindUniformData :: struct #align(16) {
	turbulence_offset 	: vec2,
	turbulence_scale 	: f32,
	_ : f32,
}
#assert(size_of(WindUniformData) == 16)

@private
GrassTypeUniformData :: struct #align(16) {
	height 					: f32,
	height_variation 		: f32,
	width 					: f32,
	bend 					: f32,

	clump_size 				: f32,
	clump_height_variation 	: f32,
	clump_squeeze_in		: f32,
	more_data 				: f32,

	top_color 				: vec4,

	bottom_color 			: vec4,

	roughness 				: f32,
	more_data_2 			: f32,
	more_data_3 			: vec2,
}
#assert(size_of(GrassTypeUniformData) == 80)

@private
UniformSet :: struct($Data : typeid) {
	layout 	: vk.DescriptorSetLayout,
	set 	: vk.DescriptorSet,

	buffer 	: vk.Buffer,
	memory 	: vk.DeviceMemory,
	mapped 	: ^Data,
}

/*
Create a (shared) uniform buffer layoyt, set and the actual buffer (and memory etc.).

If has a uniform buffer (as opposed to only textures) then this must currently be
the first binding. No reason fundamentally why not, but this is set up this way for
now.
*/
@private
create_uniform_set :: proc($Data : typeid, bindings : []vk.DescriptorSetLayoutBinding) -> UniformSet(Data) {
	g := &graphics

	has_uniform_buffer := bindings[0].descriptorType == .UNIFORM_BUFFER
	
	// For now we only support first binding
	for i in 1..<len(bindings) {
		assert(bindings[i].descriptorType != .UNIFORM_BUFFER)
	}

	set : UniformSet(Data)

	set.layout = create_descriptor_set_layout(bindings)
	set.set = allocate_descriptor_set(set.layout)

	if has_uniform_buffer {
		buffer_size := vk.DeviceSize(size_of(Data))
		set.buffer, set.memory = create_buffer_and_memory(
			buffer_size,
			{ .UNIFORM_BUFFER },
			{ .HOST_VISIBLE, .HOST_COHERENT },
		)
		set.mapped = cast(^Data) map_memory(set.memory, 0, buffer_size)
		descriptor_set_write_buffer(set.set, 0, set.buffer, .UNIFORM_BUFFER, 0, buffer_size)
	}

	return set
}

@private
destroy_uniform_set :: proc(set : ^UniformSet($Data)) {
	g := &graphics

	vk.DestroyDescriptorSetLayout(g.device, set.layout, nil)

	vk.DestroyBuffer(g.device, set.buffer, nil)
	vk.FreeMemory(g.device, set.memory, nil)
}

///////////////////////////////////////////////////////////////////////////////
// Managing
@private
PipelineShared :: struct {
	per_frame 	: UniformSet(PerFrameUniformData),
	lighting 	: UniformSet(LightingUniformData),
	world 		: UniformSet(WorldUniformData),
	wind 		: UniformSet(WindUniformData),
	grass_types : UniformSet([3]GrassTypeUniformData),

	// texture_descriptor_set_layout : vk.DescriptorSetLayout,
}

@private
Pipelines :: struct {
	shared 			: PipelineShared,
	sky 			: SkyPipeline,
	basic 			: BasicPipeline,
	terrain 		: TerrainPipeline,
	grass 			: GrassPipeline,
	grass_placement : GrassPlacementPipeline,
}

@private
create_pipelines :: proc() {
	g 		:= &graphics
	shared 	:= &graphics.pipelines.shared

	shared.per_frame = create_uniform_set(PerFrameUniformData, {
		{ 0, .UNIFORM_BUFFER, 1, { .VERTEX }, nil }, 
	})

	shared.lighting = create_uniform_set(LightingUniformData, {
		{ 0, .UNIFORM_BUFFER, 1, { .FRAGMENT }, nil },
	})
	
	shared.world = create_uniform_set(WorldUniformData, {
		{ 0, .UNIFORM_BUFFER, 1, { .VERTEX, .COMPUTE }, nil },
		{ 1, .COMBINED_IMAGE_SAMPLER, 1, { .FRAGMENT, .COMPUTE }, nil },
	})
	
	shared.wind = create_uniform_set(WindUniformData, {
		{ 0, .UNIFORM_BUFFER, 1, { .VERTEX }, nil },
		{ 1, .COMBINED_IMAGE_SAMPLER, 1, { .VERTEX }, nil },
	})

	shared.grass_types = create_uniform_set([3]GrassTypeUniformData, {
		{ 0, .UNIFORM_BUFFER, 1, { .FRAGMENT, .COMPUTE }, nil },
	})

	create_sky_pipeline()
	create_basic_pipeline()
	create_terrain_pipeline()
	create_grass_pipeline()
	create_grass_placement_pipeline()
}

@private
destroy_pipelines :: proc() {
	g := &graphics
	shared := &graphics.pipelines.shared

	destroy_uniform_set(&shared.per_frame)
	destroy_uniform_set(&shared.lighting)
	destroy_uniform_set(&shared.world)
	destroy_uniform_set(&shared.wind)
	destroy_uniform_set(&shared.grass_types)

	destroy_sky_pipeline()
	destroy_basic_pipeline()
	destroy_terrain_pipeline()
	destroy_grass_pipeline()
	destroy_grass_placement_pipeline()
}

///////////////////////////////////////////////////////////////////////////////

@private
create_descriptor_set_layout :: proc(bindings : []vk.DescriptorSetLayoutBinding) -> vk.DescriptorSetLayout {
	g := &graphics

	info := vk.DescriptorSetLayoutCreateInfo {
		sType 			= .DESCRIPTOR_SET_LAYOUT_CREATE_INFO,
		bindingCount 	= u32(len(bindings)),
		pBindings 		= raw_data(bindings),
	}

	layout : vk.DescriptorSetLayout
	result := vk.CreateDescriptorSetLayout(g.device, &info, nil, &layout)
	handle_result(result)

	return layout
}

@private
allocate_descriptor_set :: proc(
	layout : vk.DescriptorSetLayout,
	loc := #caller_location,
) -> vk.DescriptorSet {
	g := &graphics

	layout := layout

	info := vk.DescriptorSetAllocateInfo {
		sType 				= .DESCRIPTOR_SET_ALLOCATE_INFO,
		pNext 				= nil,
		descriptorPool 		= g.descriptor_pool,
		descriptorSetCount 	= 1,
		pSetLayouts 		= &layout,
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
	type 			: vk.DescriptorType,
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
		descriptorType 	= type,
		descriptorCount = 1,
		pBufferInfo 	= &buffer_info,
	}
	vk.UpdateDescriptorSets(g.device, 1, &write, 0, nil)
}

@private
descriptor_set_write_textures :: proc(
	set 		: vk.DescriptorSet, 
	binding 	: u32,
	textures 	: []^Texture,
) {
	g := &graphics

	// Todo(Leo): just to not need to hasszle with memory now,
	// Todo(Leo): use scracth allocator
	assert(len(textures) < 10)
	image_infos : [10]vk.DescriptorImageInfo

	for t, i in textures {
		image_infos[i] = {
			sampler 	= g.linear_sampler,
			imageView 	= t.image_view,
			imageLayout = .SHADER_READ_ONLY_OPTIMAL,
		}
	}

	write := vk.WriteDescriptorSet {
		sType 			= .WRITE_DESCRIPTOR_SET,
		dstSet 			= set,
		dstBinding 		= binding,
		dstArrayElement = 0,
		descriptorType 	= .COMBINED_IMAGE_SAMPLER,
		descriptorCount = u32(len(textures)),
		pImageInfo 		= raw_data(&image_infos),
	}
	vk.UpdateDescriptorSets(g.device, 1, &write, 0, nil)
}

@private
map_memory :: proc(memory : vk.DeviceMemory, offset, range : vk.DeviceSize) -> rawptr {
	g := &graphics

	out : rawptr
	vk.MapMemory(g.device, memory, offset, range, {}, &out)
	return out
}


///////////////////////////////////////////////////////////////////////////////
// pipeline creation helpers

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

///////////////////////////////////////////////////////////////////////////////
// Rare(shiny?) helpers??? Or move to somewhere else?
expand_to_vec4 :: proc(v : vec3, w : f32) -> vec4 {
	return {v.x, v.y, v.z, w}
}