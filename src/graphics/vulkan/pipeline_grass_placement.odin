package graphics

import vk "vendor:vulkan"

begin_grass_placement :: proc() {
	g 				:= graphics
	shared 			:= &graphics.pipeline_shared
	grass_placement := &graphics.grass_placement_pipeline

	cmd := grass_placement.command_buffers[g.virtual_frame_index]
	// Implicit reset with begin

	// begin := vk.CommandBufferBeginInfo {}
}	

dispatch_grass_placement_chunk :: proc() {
	g 				:= graphics
	shared 			:= &graphics.pipeline_shared
	grass_placement := &graphics.grass_placement_pipeline

	cmd := grass_placement.command_buffers[g.virtual_frame_index]
}

end_grass_placement :: proc() {
	g 				:= graphics
	shared 			:= &graphics.pipeline_shared
	grass_placement := &graphics.grass_placement_pipeline

	cmd := grass_placement.command_buffers[g.virtual_frame_index]
}

dispatch_grass_placement_pipeline :: proc (
	instances 				: ^Buffer,
	placement_texture 		: ^Texture,
	blade_count 			: int,
	chunk_position 			: vec2,
	chunk_size 				: f32,
	type_index				: int,
	noise_params 			: vec4,
) {}

///////////////////////////////////////////////////////////////////////////////
// Private

@private
GrassPlacementPipeline :: struct {
	layout 		: vk.PipelineLayout,
	pipeline 	: vk.Pipeline,

	placement_texture_layout 	: vk.DescriptorSetLayout,
	STUFF_layout 				: vk.DescriptorSetLayout,
	output_buffer_layout 		: vk.DescriptorSetLayout,

	command_buffers : [VIRTUAL_FRAME_COUNT]vk.CommandBuffer,
}

@private
create_grass_placement_pipeline :: proc() {
	g 				:= &graphics
	shared 			:= &graphics.pipeline_shared
	grass_placement := &graphics.grass_placement_pipeline
	
	grass_placement.placement_texture_layout = create_descriptor_set_layout({
		{ 0, .COMBINED_IMAGE_SAMPLER, 1, { .COMPUTE }, nil },
	})

	grass_placement.STUFF_layout = create_descriptor_set_layout({
		{ 0, .UNIFORM_BUFFER, 1, { .COMPUTE }, nil },
	})

	grass_placement.output_buffer_layout = create_descriptor_set_layout({
		{ 0, .STORAGE_BUFFER, 1, { .COMPUTE }, nil },
	})

	grass_placement.layout = create_pipeline_layout({
		shared.world.descriptor_set_layout,
		grass_placement.placement_texture_layout,
		shared.grass_types.descriptor_set_layout,
		grass_placement.STUFF_layout,
		grass_placement.output_buffer_layout,
	}, nil)

	// PIPELINE
	{
		info := vk.ComputePipelineCreateInfo {
			sType 	= .COMPUTE_PIPELINE_CREATE_INFO,
			pNext 	= nil,
			flags 	= {},
			stage 	= pipeline_shader_stage(g.device, "spirv_shaders/grass_placement.spv", { .COMPUTE }),
			layout 	= grass_placement.layout,
		}
		result := vk.CreateComputePipelines(
			g.device,
			VK_NULL_HANDLE,
			1,
			&info,
			nil,
			&grass_placement.pipeline
		)
		handle_result(result)

		vk.DestroyShaderModule(g.device, info.stage.module, nil)
	}

	// Command buffers
	{
		g := &graphics

		allocate_info := vk.CommandBufferAllocateInfo {
			sType 				= .COMMAND_BUFFER_ALLOCATE_INFO,
			commandPool 		= g.command_pools[.Compute],
			level 				= .PRIMARY,
			commandBufferCount 	= VIRTUAL_FRAME_COUNT,
		}

		allocate_result := vk.AllocateCommandBuffers(
			g.device,
			&allocate_info,
			raw_data(&grass_placement.command_buffers),
		)
	}
}

@private
destroy_grass_placement_pipeline :: proc() {
	g 				:= &graphics
	grass_placement := &graphics.grass_placement_pipeline

	vk.DestroyDescriptorSetLayout(g.device, grass_placement.placement_texture_layout, nil)
	vk.DestroyDescriptorSetLayout(g.device, grass_placement.STUFF_layout, nil)
	vk.DestroyDescriptorSetLayout(g.device, grass_placement.output_buffer_layout, nil)

	vk.DestroyPipelineLayout(g.device, grass_placement.layout, nil)
	vk.DestroyPipeline(g.device, grass_placement.pipeline, nil)
}


// @private
// @private
// @private
// @private