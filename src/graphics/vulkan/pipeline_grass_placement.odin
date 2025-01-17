package graphics

import vk "vendor:vulkan"

COMPUTE_SHADER_WORK_GROUP_SIZE_XY :: 16

begin_grass_placement :: proc() {
	g 				:= graphics
	shared 			:= &graphics.pipelines.shared
	grass_placement := &graphics.pipelines.grass_placement

	cmd := grass_placement.command_buffers[g.virtual_frame_index]
	// Implicit reset with begin

	begin := vk.CommandBufferBeginInfo {
		sType = .COMMAND_BUFFER_BEGIN_INFO,
		// flags = { .ONE_TIME_SUBMIT },
	}
	result := vk.BeginCommandBuffer(cmd, &begin)
	handle_result(result)

	vk.CmdBindPipeline(cmd, .COMPUTE, grass_placement.pipeline)

	WORLD_SET :: 0
	// GRASS_TYPES_SET :: 1

	shared_descriptors := []vk.DescriptorSet {
		shared.world.set,
		shared.grass_types.set,
	}

	vk.CmdBindDescriptorSets(
		cmd,
		.COMPUTE,
		grass_placement.layout,
		WORLD_SET,
		u32(len(shared_descriptors)),
		raw_data(shared_descriptors),
		0,
		nil,
	)
}	

dispatch_grass_placement_chunk :: proc(r : ^GrassRenderer) {
	g 				:= graphics
	shared 			:= &graphics.pipelines.shared
	grass_placement := &graphics.pipelines.grass_placement

	cmd := grass_placement.command_buffers[g.virtual_frame_index]

	INPUT_SET :: 2
	// OUTPUT_SET :: 3

	descriptors := []vk.DescriptorSet {
		r.placement_input_descriptor,
		r.placement_output_descriptor,
	}

	vk.CmdBindDescriptorSets(
		cmd,
		.COMPUTE,
		grass_placement.layout,
		INPUT_SET,
		u32(len(descriptors)),
		raw_data(descriptors),
		0,
		nil,
	)

	work_group_count := r.instance_count_1D / COMPUTE_SHADER_WORK_GROUP_SIZE_XY
	vk.CmdDispatch(cmd, work_group_count, work_group_count, 1)
}

end_grass_placement :: proc() {
	g 				:= graphics
	shared 			:= &graphics.pipelines.shared
	grass_placement := &graphics.pipelines.grass_placement

	cmd := grass_placement.command_buffers[g.virtual_frame_index]

	vk.EndCommandBuffer(cmd)

	// Todo(Leo): fence not best, but semaphores didn't work yet
	fence := g.grass_placement_complete_fences[g.virtual_frame_index]
	vk.ResetFences(g.device, 1, &fence)

	submit := vk.SubmitInfo {
		sType 					= .SUBMIT_INFO,
		waitSemaphoreCount 		= 0,
		commandBufferCount 		= 1,
		pCommandBuffers 		= &cmd,
		signalSemaphoreCount 	= 0,
	}
	result := vk.QueueSubmit(g.compute_queue, 1, &submit, fence)
	handle_result(result)
}

wait_for_grass :: proc() {
	// Also test waiting grass here, essentially just before submitting
	g := &graphics
	vk.WaitForFences(g.device, 1, &g.grass_placement_complete_fences[g.virtual_frame_index], true, max(u64))
}

///////////////////////////////////////////////////////////////////////////////
// Private

@private
GrassPlacementPipeline :: struct {
	layout 		: vk.PipelineLayout,
	pipeline 	: vk.Pipeline,

	input_layout 				: vk.DescriptorSetLayout,
	output_layout 				: vk.DescriptorSetLayout,

	command_buffers : [VIRTUAL_FRAME_COUNT]vk.CommandBuffer,
}

@private
create_grass_placement_pipeline :: proc() {
	g 				:= &graphics
	shared 			:= &graphics.pipelines.shared
	grass_placement := &graphics.pipelines.grass_placement
	
	grass_placement.input_layout = create_descriptor_set_layout({
		{ 0, .UNIFORM_BUFFER, 1, { .COMPUTE }, nil },
	})

	grass_placement.output_layout = create_descriptor_set_layout({
		{ 0, .STORAGE_BUFFER, 1, { .COMPUTE }, nil },
	})

	grass_placement.layout = create_pipeline_layout({
		shared.world.layout,
		shared.grass_types.layout,
		grass_placement.input_layout,
		grass_placement.output_layout,
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
	grass_placement := &graphics.pipelines.grass_placement

	vk.DestroyDescriptorSetLayout(g.device, grass_placement.input_layout, nil)
	vk.DestroyDescriptorSetLayout(g.device, grass_placement.output_layout, nil)

	vk.DestroyPipelineLayout(g.device, grass_placement.layout, nil)
	vk.DestroyPipeline(g.device, grass_placement.pipeline, nil)
}
