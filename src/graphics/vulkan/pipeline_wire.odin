package graphics

import "core:fmt"

import vk "vendor:vulkan"

@private
WirePipeline :: struct {
	layout 			: vk.PipelineLayout,
	pipeline 		: vk.Pipeline,
}

@private
WirePushConstant :: struct #align(16) {
	model : mat4,
	color : vec4,
}
#assert(size_of(WirePushConstant) == 80)

@private
create_wire_pipeline :: proc() {
	g 		:= &graphics
	wire 	:= &graphics.pipelines.wire
	shared 	:= &graphics.pipelines.shared

	wire.layout = create_pipeline_layout({
		shared.per_frame.layout,	
		shared.lighting.layout,
	}, {
		{ {.VERTEX, .FRAGMENT }, 0, size_of(WirePushConstant), },
	})

	// PIPELINE
	{
		shader_stages := []vk.PipelineShaderStageCreateInfo {
			pipeline_shader_stage(g.device, "spirv_shaders/wire_vert.spv", {.VERTEX}),
			pipeline_shader_stage(g.device, "spirv_shaders/wire_frag.spv", {.FRAGMENT}),
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
		rasterization 	:= pipeline_rasterization({.BACK}, .LINE)
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

			layout = wire.layout,

			renderPass 	= g.main_render_pass,
			subpass 	= 0,
		}

		create_result := vk.CreateGraphicsPipelines(
			g.device,
			VK_NULL_HANDLE,
			1,
			&create_info,
			nil,
			&wire.pipeline,
		)
		handle_result(create_result)

		// No more needed, destroy
		vk.DestroyShaderModule(g.device, shader_stages[0].module, nil)
		vk.DestroyShaderModule(g.device, shader_stages[1].module, nil)
	}
}

destroy_wire_pipeline :: proc() {
	g := &graphics

	vk.DestroyPipeline(g.device, g.pipelines.wire.pipeline, nil)
	vk.DestroyPipelineLayout(g.device, g.pipelines.wire.layout, nil)
}

setup_wire_pipeline :: proc () {
	g 		:= &graphics
	wire 	:= &graphics.pipelines.wire
	shared 	:= graphics.pipelines.shared

	main_cmd := g.main_command_buffers[g.virtual_frame_index]

	vk.CmdBindPipeline(main_cmd, .GRAPHICS, wire.pipeline)

	descriptor_sets := []vk.DescriptorSet {
		shared.per_frame.set,
		shared.lighting.set,
	}

	vk.CmdBindDescriptorSets(
		main_cmd,
		.GRAPHICS, 
		wire.layout, 
		0,
		u32(len(descriptor_sets)),
		raw_data(descriptor_sets),
		0,
		nil
	)
}

draw_wire_mesh :: proc(mesh : ^Mesh, model : mat4, color : vec3) {
	g := &graphics

	main_cmd := g.main_command_buffers[g.virtual_frame_index]

	vk.CmdBindVertexBuffers(
		main_cmd,
		0,
		u32(len(mesh.vertex_buffers)),
		raw_data(mesh.vertex_buffers),
		raw_data(mesh.offsets),
	)

	vk.CmdBindIndexBuffer(
		main_cmd,
		mesh.index_buffer,
		0,
		.UINT16,
	)

	push_constant := WirePushConstant{
		model,
		vec4{color.r, color.g, color.b, 1}
	}
	vk.CmdPushConstants(
		main_cmd,
		graphics.pipelines.wire.layout,
		{ .VERTEX, .FRAGMENT },
		0,
		size_of(push_constant),
		&push_constant,
	)

	vk.CmdDrawIndexed(main_cmd, mesh.index_count, 1, 0, 0, 0)
}


// draw_wire_mesh :: proc(mesh : ^Mesh, model : mat4) {
// 	g 		:= &graphics
// 	wire 	:= &graphics.pipelines.wire
// 	shared 	:= graphics.pipelines.shared

// 	main_cmd := g.main_command_buffers[g.virtual_frame_index]

// 	vk.CmdBindVertexBuffers(
// 		main_cmd,
// 		0,
// 		u32(len(mesh.vertex_buffers)),
// 		raw_data(mesh.vertex_buffers),
// 		raw_data(mesh.offsets),
// 	)

// 	vk.CmdBindIndexBuffer(
// 		main_cmd,
// 		mesh.index_buffer,
// 		0,
// 		.UINT16,
// 	)

// 	model := model
// 	vk.CmdPushConstants(
// 		main_cmd,
// 		wire.layout,
// 		{ .VERTEX },
// 		0,
// 		64,
// 		&model,
// 	)

// 	vk.CmdDrawIndexed(main_cmd, mesh.index_count, 1, 0, 0, 0)
// }