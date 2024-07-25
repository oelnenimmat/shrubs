package graphics

import vk "vendor:vulkan"

@private
PostProcessData :: struct #align(16) {
	exposure : f32,
	_ : f32,
	_ : vec2,
}
#assert(size_of(PostProcessData) == 16)

@private
PostProcessPipeline :: struct {
	layout 		: vk.PipelineLayout,
	pipeline 	: vk.Pipeline,

	uniform : UniformSet(PostProcessData)
}

@private
create_post_process_pipeline :: proc() {
	g 				:= &graphics
	post_process 	:= &graphics.pipelines.post_process
	shared 			:= &graphics.pipelines.shared

	post_process.uniform = create_uniform_set(PostProcessData, {
		{ 0, .UNIFORM_BUFFER, 1, { .FRAGMENT }, nil },
	})

	// Layout
	post_process.layout = create_pipeline_layout({
		g.color_image_descriptor_layout,
		post_process.uniform.layout,
	}, nil)

	// PIPELINE
	{
		shader_stages := []vk.PipelineShaderStageCreateInfo {
			pipeline_shader_stage(g.device, "spirv_shaders/post_process_vert.spv", {.VERTEX}),
			pipeline_shader_stage(g.device, "spirv_shaders/post_process_frag.spv", {.FRAGMENT}),
		}

		dynamic_states 	:= []vk.DynamicState{ .VIEWPORT, .SCISSOR }
		dynamic_state 	:= pipeline_dynamic(dynamic_states)

		vertex_input 	:= pipeline_vertex_input()
		input_assembly 	:= pipeline_input_assembly(.TRIANGLE_LIST)
		viewport 		:= pipeline_viewport()
		rasterization 	:= pipeline_rasterization({})
		// depth_stencil 	:= pipeline_depth_stencil()
		multisample 	:= pipeline_multisample()

		color_blend_attachments := []vk.PipelineColorBlendAttachmentState {
			pipeline_color_blend_attachment()
		}
		color_blend := pipeline_color_blend(color_blend_attachments)

		create_info := vk.GraphicsPipelineCreateInfo {
			sType = .GRAPHICS_PIPELINE_CREATE_INFO,
			
			stageCount 	= 2,
			pStages 	= raw_data(shader_stages),

			pVertexInputState 	= &vertex_input,
			pInputAssemblyState = &input_assembly,
			pViewportState 		= &viewport,
			pRasterizationState = &rasterization,
			pMultisampleState 	= &multisample,
			pDepthStencilState 	= nil,
			pColorBlendState 	= &color_blend,
			pDynamicState 		= &dynamic_state,

			layout = post_process.layout,

			renderPass 	= g.screen_render_pass,
			subpass 	= 0,
		}

		create_result := vk.CreateGraphicsPipelines(
			g.device,
			VK_NULL_HANDLE,
			1,
			&create_info,
			nil,
			&post_process.pipeline,
		)
		handle_result(create_result)

		// No more needed, destroy
		vk.DestroyShaderModule(g.device, shader_stages[0].module, nil)
		vk.DestroyShaderModule(g.device, shader_stages[1].module, nil)
	}
}

@private
destroy_post_process_pipeline :: proc() {
	g 				:= &graphics
	post_process 	:= &graphics.pipelines.post_process

	vk.DestroyPipeline(g.device, post_process.pipeline, nil)
	vk.DestroyPipelineLayout(g.device, post_process.layout, nil)

	destroy_uniform_set(&post_process.uniform)
}

draw_post_process :: proc(exposure : f32) {
	g 				:= &graphics
	post_process 	:= &graphics.pipelines.post_process
	shared 			:= &graphics.pipelines.shared

	post_process.uniform.mapped.exposure = exposure

	cmd := g.screen_command_buffers[g.virtual_frame_index]
	
	vk.CmdBindPipeline(cmd, .GRAPHICS, post_process.pipeline)
	
	descriptors := []vk.DescriptorSet {
		g.color_image_descriptor_set,
		post_process.uniform.set,
	}

	vk.CmdBindDescriptorSets(
		cmd,
		.GRAPHICS, 
		post_process.layout, 
		0,
		u32(len(descriptors)),
		raw_data(descriptors),
		0,
		nil
	)
	vk.CmdDraw(cmd, 3, 1, 0, 0)
}