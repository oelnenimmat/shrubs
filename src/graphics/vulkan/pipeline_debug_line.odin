package graphics


import "core:fmt"

import vk "vendor:vulkan"

@private
LinePipeline :: struct {
	layout 			: vk.PipelineLayout,
	pipeline 		: vk.Pipeline,
}

@private
LinePushConstant :: struct #align(16) {
	points 	: [2]vec4,
	color 	: vec4,
}
#assert(size_of(LinePushConstant) == 48)

@private
create_line_pipeline :: proc() {
	g 		:= &graphics
	line 	:= &graphics.pipelines.line
	shared 	:= &graphics.pipelines.shared

	line.layout = create_pipeline_layout({
		shared.per_frame.layout,	
	}, {
		{ {.VERTEX, .FRAGMENT }, 0, size_of(LinePushConstant), },
	})

	// PIPELINE
	{
		shader_stages := []vk.PipelineShaderStageCreateInfo {
			pipeline_shader_stage(g.device, "spirv_shaders/line_vert.spv", {.VERTEX}),
			pipeline_shader_stage(g.device, "spirv_shaders/line_frag.spv", {.FRAGMENT}),
		}

		dynamic_states 	:= []vk.DynamicState{ .VIEWPORT, .SCISSOR }
		dynamic_state 	:= pipeline_dynamic(dynamic_states)

		vertex_input 	:= pipeline_vertex_input(nil, nil)
		input_assembly 	:= pipeline_input_assembly(.LINE_STRIP)
		viewport 		:= pipeline_viewport()
		rasterization 	:= pipeline_rasterization({}, .LINE)
		depth_stencil 	:= pipeline_depth_stencil()
		multisample 	:= pipeline_multisample(true)

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

			layout = line.layout,

			renderPass 	= g.main_render_pass,
			subpass 	= 0,
		}

		create_result := vk.CreateGraphicsPipelines(
			g.device,
			VK_NULL_HANDLE,
			1,
			&create_info,
			nil,
			&line.pipeline,
		)
		handle_result(create_result)

		// No more needed, destroy
		vk.DestroyShaderModule(g.device, shader_stages[0].module, nil)
		vk.DestroyShaderModule(g.device, shader_stages[1].module, nil)
	}
}

@private
destroy_line_pipeline :: proc() {
	g := &graphics

	vk.DestroyPipeline(g.device, g.pipelines.line.pipeline, nil)
	vk.DestroyPipelineLayout(g.device, g.pipelines.line.layout, nil)
}


setup_line_pipeline :: proc () {
	g 		:= &graphics
	line 	:= &graphics.pipelines.line
	shared 	:= graphics.pipelines.shared

	main_cmd := g.main_command_buffers[g.virtual_frame_index]

	vk.CmdBindPipeline(main_cmd, .GRAPHICS, line.pipeline)

	descriptor_sets := []vk.DescriptorSet {
		shared.per_frame.set,
	}

	vk.CmdBindDescriptorSets(
		main_cmd,
		.GRAPHICS, 
		line.layout, 
		0,
		u32(len(descriptor_sets)),
		raw_data(descriptor_sets),
		0,
		nil
	)
}

draw_line :: proc(points : [2]vec3, color : vec3) {
	g := &graphics

	main_cmd := g.main_command_buffers[g.virtual_frame_index]

	push_constant := LinePushConstant{
		{
			expand_to_vec4(points[0], 1),
			expand_to_vec4(points[1], 1),
		},
		expand_to_vec4(color, 1)
	}
	vk.CmdPushConstants(
		main_cmd,
		graphics.pipelines.line.layout,
		{ .VERTEX, .FRAGMENT },
		0,
		size_of(push_constant),
		&push_constant,
	)

	vk.CmdDraw(main_cmd, 2, 1, 0, 0)
}
