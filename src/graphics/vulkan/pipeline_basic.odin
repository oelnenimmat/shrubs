package graphics

import vk "vendor:vulkan"

@private
BasicPipeline :: struct {
	layout : vk.PipelineLayout,
	pipeline : vk.Pipeline,
}

@private
create_basic_pipeline :: proc() {
	g 		:= &graphics
	basic 	:= &graphics.basic_pipeline
	shared 	:= &graphics.pipeline_shared

	basic.layout = create_pipeline_layout({
		shared.per_frame.descriptor_set_layout,
		shared.lighting.descriptor_set_layout,
	}, {
		{ {.VERTEX}, 0, 64,},
	})

	// PIPELINE
	{
		shader_stages := []vk.PipelineShaderStageCreateInfo {
			pipeline_shader_stage(g.device, "spirv_shaders/basic_vert.spv", {.VERTEX}),
			pipeline_shader_stage(g.device, "spirv_shaders/basic_frag.spv", {.FRAGMENT}),
		}

		dynamic_states 	:= []vk.DynamicState{ .VIEWPORT, .SCISSOR }
		dynamic_state 	:= pipeline_dynamic(dynamic_states)

		bindings := []vk.VertexInputBindingDescription {
			{ 0, size_of(vec3), .VERTEX },
		}

		attributes := []vk.VertexInputAttributeDescription {
			{ 0, 0, .R32G32B32_SFLOAT, 0 },
		}

		vertex_input 	:= pipeline_vertex_input(bindings, attributes)
		input_assembly 	:= pipeline_input_assembly(.TRIANGLE_LIST)
		viewport 		:= pipeline_viewport()
		rasterization 	:= pipeline_rasterization({.BACK})
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

			layout = basic.layout,

			renderPass 	= g.test_render_pass,
			subpass 	= 0,
		}

		create_result := vk.CreateGraphicsPipelines(
			g.device,
			VK_NULL_HANDLE,
			1,
			&create_info,
			nil,
			&basic.pipeline,
		)
		handle_result(create_result)

		// No more needed, destroy
		vk.DestroyShaderModule(g.device, shader_stages[0].module, nil)
		vk.DestroyShaderModule(g.device, shader_stages[1].module, nil)
	}
}

destroy_basic_pipeline :: proc() {
	g := &graphics

	vk.DestroyPipeline(g.device, g.basic_pipeline.pipeline, nil)
	vk.DestroyPipelineLayout(g.device, g.basic_pipeline.layout, nil)
}

draw_basic_mesh :: proc(mesh : ^Mesh, model : mat4) {
	g 		:= &graphics
	basic 	:= &graphics.basic_pipeline
	shared 	:= graphics.pipeline_shared

	main_cmd := g.main_command_buffers[g.virtual_frame_index]

	vk.CmdBindPipeline(main_cmd, .GRAPHICS, basic.pipeline)

	descriptor_sets := []vk.DescriptorSet {
		shared.per_frame.descriptor_set,
		shared.lighting.descriptor_set,
	}

	vk.CmdBindDescriptorSets(
		main_cmd,
		.GRAPHICS, 
		basic.layout, 
		0,
		u32(len(descriptor_sets)),
		raw_data(descriptor_sets),
		0,
		nil
	)

	offset := vk.DeviceSize(0)
	vk.CmdBindVertexBuffers(
		main_cmd,
		0,
		1, //len(mesh.vertex_buffers),
		&mesh.vertex_buffer,
		&offset,
	)

	vk.CmdBindIndexBuffer(
		main_cmd,
		mesh.index_buffer,
		0,
		.UINT16,
	)

	model := model
	vk.CmdPushConstants(
		main_cmd,
		basic.layout,
		{ .VERTEX },
		0,
		64,
		&model,
	)

	vk.CmdDrawIndexed(main_cmd, mesh.index_count, 1, 0, 0, 0)
}