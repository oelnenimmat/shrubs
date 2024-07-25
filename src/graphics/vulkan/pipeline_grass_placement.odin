package graphics

import vk "vendor:vulkan"

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

	vk.CmdDispatch(cmd, 4, 4, 1)
}

end_grass_placement :: proc() {
	g 				:= graphics
	shared 			:= &graphics.pipelines.shared
	grass_placement := &graphics.pipelines.grass_placement

	cmd := grass_placement.command_buffers[g.virtual_frame_index]

	vk.EndCommandBuffer(cmd)

	wait_semaphores := []vk.Semaphore {
		// g.rendering_complete_semaphores[g.virtual_frame_index],
	}
	wait_masks := []vk.PipelineStageFlags {
		// { .COMPUTE_SHADER },
	}

	signal_semaphores := []vk.Semaphore {
		// g.grass_placement_complete_semaphores[g.virtual_frame_index],
	}

	// Todo(Leo): fence not good, but semaphores didn't work yet
	// at least move the fence waiting later
	// fence_create_info := vk.FenceCreateInfo { sType = .FENCE_CREATE_INFO }
	// fence : vk.Fence
	// fence_create_result := vk.CreateFence(g.device, &fence_create_info, nil, &fence)
	// handle_result(fence_create_result)

	fence := g.grass_placement_complete_fences[g.virtual_frame_index]
	vk.ResetFences(g.device, 1, &fence)

	submit := vk.SubmitInfo {
		sType 					= .SUBMIT_INFO,
		waitSemaphoreCount 		= u32(len(wait_semaphores)),
		pWaitSemaphores 		= raw_data(wait_semaphores),
		pWaitDstStageMask 		= raw_data(wait_masks),
		commandBufferCount 		= 1,
		pCommandBuffers 		= &cmd,
		signalSemaphoreCount 	= u32(len(signal_semaphores)),
		pSignalSemaphores 		= raw_data(signal_semaphores)
	}
	result := vk.QueueSubmit(g.compute_queue, 1, &submit, fence)
	handle_result(result)

	vk.WaitForFences(g.device, 1, &fence, true, max(u64))
	// vk.DestroyFence(g.device, fence, nil)

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
