package graphics

import vk "vendor:vulkan"

@private
BasicPipeline :: struct {
	layout : vk.PipelineLayout,
	pipeline : vk.Pipeline,

	material_layout : vk.DescriptorSetLayout,

	DEBUG_material_buffer 	: vk.Buffer,
	DEBUG_material_memory 	: vk.DeviceMemory,
	DEBUG_material_mapped 	: ^BasicMaterial,
	DEBUG_material_set 		: vk.DescriptorSet,
}

BasicMaterial :: struct #align(16) {
	surface_color : vec4,
}
#assert(size_of(BasicMaterial) == 16)
#assert(align_of(BasicMaterial) == 16)

@private
create_basic_pipeline :: proc() {
	g 		:= &graphics
	basic 	:= &graphics.basic_pipeline
	shared 	:= &graphics.pipeline_shared

	// Material descriptor layout
	{
		bindings := []vk.DescriptorSetLayoutBinding {
			{ 0, .UNIFORM_BUFFER, 1, { .FRAGMENT }, nil },
		}
		layout_create_info := vk.DescriptorSetLayoutCreateInfo {
			sType 			= .DESCRIPTOR_SET_LAYOUT_CREATE_INFO,
			bindingCount 	= u32(len(bindings)),
			pBindings 		= raw_data(bindings),
		}
		layout_create_result := vk.CreateDescriptorSetLayout(
			g.device,
			&layout_create_info,
			nil,
			&basic.material_layout,
		)
		handle_result(layout_create_result)

		// Debug buffer
		basic.DEBUG_material_buffer, basic.DEBUG_material_memory = create_buffer_and_memory(
			size_of(BasicMaterial),
			{ .UNIFORM_BUFFER },
			{ .HOST_VISIBLE, .HOST_COHERENT },
		)
		vk.MapMemory(
			g.device, 
			basic.DEBUG_material_memory, 
			0, 
			size_of(BasicMaterial), 
			{}, 
			cast(^rawptr)&basic.DEBUG_material_mapped,
		)

		allocate_descriptor_set :: proc(
			layout : vk.DescriptorSetLayout,
			loc := #caller_location,
		) -> vk.DescriptorSet {
			g := &graphics

			layout := layout

			info := vk.DescriptorSetAllocateInfo {
				sType = .DESCRIPTOR_SET_ALLOCATE_INFO,
				descriptorPool = g.descriptor_pool,
				descriptorSetCount = 1,
				pSetLayouts = &layout,
			}

			set : vk.DescriptorSet
			result := vk.AllocateDescriptorSets(g.device, &info, &set)
			handle_result(result, loc)

			return set

		}
		basic.DEBUG_material_set = allocate_descriptor_set(basic.material_layout)

		buffer_info := vk.DescriptorBufferInfo {
			buffer 	= basic.DEBUG_material_buffer,
			offset 	= 0,
			range 	= vk.DeviceSize(size_of(BasicMaterial)),
		}

		write := vk.WriteDescriptorSet {
			sType 			= .WRITE_DESCRIPTOR_SET,
			dstSet 			= basic.DEBUG_material_set,
			dstBinding 		= 0,
			dstArrayElement = 0,
			descriptorType 	= .UNIFORM_BUFFER,
			descriptorCount = 1,
			pBufferInfo 	= &buffer_info,
		}
		vk.UpdateDescriptorSets(g.device, 1, &write, 0, nil)
	}

	basic.layout = create_pipeline_layout({
		shared.per_frame.descriptor_set_layout,
		shared.lighting.descriptor_set_layout,
		basic.material_layout,
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
			{ 1, size_of(vec3), .VERTEX },
			{ 2, size_of(vec2), .VERTEX },
		}

		attributes := []vk.VertexInputAttributeDescription {
			{ 0, 0, .R32G32B32_SFLOAT, 0 },
			{ 1, 1, .R32G32B32_SFLOAT, 0 },
			{ 2, 2, .R32G32_SFLOAT, 0 },
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

	vk.DestroyBuffer(g.device, g.basic_pipeline.DEBUG_material_buffer, nil)
	vk.FreeMemory(g.device, g.basic_pipeline.DEBUG_material_memory, nil)

	vk.DestroyDescriptorSetLayout(g.device, g.basic_pipeline.material_layout, nil)

	vk.DestroyPipeline(g.device, g.basic_pipeline.pipeline, nil)
	vk.DestroyPipelineLayout(g.device, g.basic_pipeline.layout, nil)
}

setup_basic_pipeline :: proc () {
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
}

set_basic_material :: proc(color : vec3, texture : ^Texture) {
	g 		:= &graphics
	basic 	:= &graphics.basic_pipeline

	basic.DEBUG_material_mapped.surface_color.rgb = color

	main_cmd := g.main_command_buffers[g.virtual_frame_index]

	descriptor_sets := []vk.DescriptorSet {
		basic.DEBUG_material_set,
	}

	vk.CmdBindDescriptorSets(
		main_cmd,
		.GRAPHICS, 
		basic.layout, 
		2,
		u32(len(descriptor_sets)),
		raw_data(descriptor_sets),
		0,
		nil
	)
}


draw_basic_mesh :: proc(mesh : ^Mesh, model : mat4) {
	g 		:= &graphics
	basic 	:= &graphics.basic_pipeline
	shared 	:= graphics.pipeline_shared

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