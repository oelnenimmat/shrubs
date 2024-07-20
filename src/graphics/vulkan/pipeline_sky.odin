package graphics

import vk "vendor:vulkan"

@private
SkyPipeline :: struct {
	layout : vk.PipelineLayout,
	pipeline : vk.Pipeline,
}

@private
create_sky_pipeline :: proc() {
	g 		:= &graphics
	sky 	:= &graphics.sky_pipeline
	shared 	:= &graphics.pipeline_shared

	// Layout
	sky.layout = create_pipeline_layout({shared.lighting.descriptor_set_layout}, nil)

	// PIPELINE
	{
		shader_stages := []vk.PipelineShaderStageCreateInfo {
			pipeline_shader_stage(g.device, "spirv_shaders/sky_vert.spv", {.VERTEX}),
			pipeline_shader_stage(g.device, "spirv_shaders/sky_frag.spv", {.FRAGMENT}),
		}

		dynamic_states 	:= []vk.DynamicState{ .VIEWPORT, .SCISSOR }
		dynamic_state 	:= pipeline_dynamic(dynamic_states)

		vertex_input 	:= pipeline_vertex_input()
		input_assembly 	:= pipeline_input_assembly(.TRIANGLE_LIST)
		viewport 		:= pipeline_viewport()
		rasterization 	:= pipeline_rasterization({ .BACK })
		depth_stencil 	:= pipeline_depth_stencil()
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
			pDepthStencilState 	= &depth_stencil,
			pColorBlendState 	= &color_blend,
			pDynamicState 		= &dynamic_state,

			layout = sky.layout,

			renderPass 	= g.test_render_pass,
			subpass 	= 0,
		}

		create_result := vk.CreateGraphicsPipelines(
			g.device,
			VK_NULL_HANDLE,
			1,
			&create_info,
			nil,
			&sky.pipeline,
		)
		handle_result(create_result)

		// No more needed, destroy
		vk.DestroyShaderModule(g.device, shader_stages[0].module, nil)
		vk.DestroyShaderModule(g.device, shader_stages[1].module, nil)
	}
}

@private
destroy_sky_pipeline :: proc() {
	g := &graphics
	sky := &graphics.sky_pipeline

	vk.DestroyPipeline(g.device, sky.pipeline, nil)
	vk.DestroyPipelineLayout(g.device, sky.layout, nil)
}

draw_sky :: proc() {
	g 		:= &graphics
	sky 	:= &graphics.sky_pipeline
	shared 	:= &graphics.pipeline_shared

	main_cmd := g.main_command_buffers[g.virtual_frame_index]
	
	vk.CmdBindPipeline(main_cmd, .GRAPHICS, sky.pipeline)
	
	descriptor_sets := []vk.DescriptorSet {
		shared.lighting.descriptor_set,
	}

	vk.CmdBindDescriptorSets(
		main_cmd,
		.GRAPHICS, 
		sky.layout, 
		0,
		u32(len(descriptor_sets)),
		raw_data(descriptor_sets),
		0,
		nil
	)
	vk.CmdDraw(main_cmd, 3, 1, 0, 0)
}