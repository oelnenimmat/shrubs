package graphics

import "core:os"
import vk "vendor:vulkan"


@private
SkyPipeline :: struct {
	layout : vk.PipelineLayout,
	pipeline : vk.Pipeline,
}

@private
create_sky_pipeline :: proc() {
	g := &graphics
	sky := &graphics.sky_pipeline
	shared := &graphics.pipeline_shared

	// Layout
	{
		layout_create_info := vk.PipelineLayoutCreateInfo {
			sType 			= .PIPELINE_LAYOUT_CREATE_INFO,
			setLayoutCount 	= 1,
			pSetLayouts 	= &shared.lighting_descriptor_set_layout,
		}
		layout_create_result := vk.CreatePipelineLayout(g.device, &layout_create_info, nil, &sky.layout)
		handle_result(layout_create_result)
	}

	// PIPELINE
	{
		vert_shader_code, vert_ok := os.read_entire_file("spirv_shaders/sky_vert.spv")
		frag_shader_code, frag_ok := os.read_entire_file("spirv_shaders/sky_frag.spv")
		defer { 
			delete(vert_shader_code)
			delete(frag_shader_code)
		}
		assert(vert_ok && frag_ok)

		vert_module, frag_module : vk.ShaderModule

		create_shader_module :: proc(device : vk.Device, code : []u8, loc := #caller_location) -> vk.ShaderModule {
			info := vk.ShaderModuleCreateInfo {
				sType 		= .SHADER_MODULE_CREATE_INFO, 
				codeSize 	= len(code),
				pCode 		= cast(^u32) raw_data(code)
			}
			module : vk.ShaderModule
			result := vk.CreateShaderModule(device, &info, nil, &module)
			handle_result(result, loc)
		
			return module
		}

		vert_module = create_shader_module(g.device, vert_shader_code)
		frag_module = create_shader_module(g.device, frag_shader_code)
		defer vk.DestroyShaderModule(g.device, vert_module, nil)
		defer vk.DestroyShaderModule(g.device, frag_module, nil)


		shader_stages := []vk.PipelineShaderStageCreateInfo {
			{
				sType = .PIPELINE_SHADER_STAGE_CREATE_INFO,
				stage = { .VERTEX },
				module = vert_module,
				pName = "main"
			},
			{
				sType = .PIPELINE_SHADER_STAGE_CREATE_INFO,
				stage = { .FRAGMENT },
				module = frag_module,
				pName = "main"
			},
		}

		dynamic_states 	:= []vk.DynamicState{ .VIEWPORT, .SCISSOR }
		dynamic_state 	:= pipeline_dynamic(dynamic_states)

		vertex_input 	:= pipeline_vertex_input()
		input_assembly 	:= pipeline_input_assembly(.TRIANGLE_LIST)
		viewport 		:= pipeline_viewport()
		rasterization 	:= pipeline_rasterization()
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

	main_cmd := g.main_command_buffers[g.virtual_frame_index]
	
	vk.CmdBindPipeline(main_cmd, .GRAPHICS, sky.pipeline)

	vk.CmdDraw(main_cmd, 3, 1, 0, 0)
}