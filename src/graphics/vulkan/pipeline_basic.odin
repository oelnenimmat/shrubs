package graphics

import "core:fmt"

import vk "vendor:vulkan"

BasicMaterial :: struct {
	descriptor_set 	: vk.DescriptorSet,
	buffer 			: vk.Buffer,
	memory 			: vk.DeviceMemory,
	using mapped 	: ^BasicMaterialBuffer,
}

@private
BasicPipeline :: struct {
	layout 			: vk.PipelineLayout,
	pipeline 		: vk.Pipeline,
	material_layout : vk.DescriptorSetLayout,
}

@private
BasicMaterialBuffer :: struct #align(16) {
	surface_color : vec4,
}
#assert(size_of(BasicMaterialBuffer) == 16)

create_basic_material :: proc(texture : ^Texture) -> BasicMaterial {
	g 		:= &graphics
	basic 	:= &graphics.basic_pipeline

	m : BasicMaterial

	// Debug buffer
	size := vk.DeviceSize(size_of(BasicMaterialBuffer))
	m.buffer, m.memory = create_buffer_and_memory(
		size,
		{ .UNIFORM_BUFFER },
		{ .HOST_VISIBLE, .HOST_COHERENT },
	)
	vk.MapMemory(g.device, m.memory, 0, size, {}, cast(^rawptr)&m.mapped)

	m.descriptor_set = allocate_descriptor_set(basic.material_layout)
	descriptor_set_write_buffer(m.descriptor_set, 0, m.buffer, 0, size)
	descriptor_set_write_texture(m.descriptor_set, 1, texture)

	return m
}

destroy_basic_material :: proc(m : ^BasicMaterial) {
	g := &graphics

	vk.DestroyBuffer(g.device, m.buffer, nil)
	vk.FreeMemory(g.device, m.memory, nil)
	vk.FreeDescriptorSets(g.device, g.descriptor_pool, 1, &m.descriptor_set)
}

@private
create_basic_pipeline :: proc() {
	g 		:= &graphics
	basic 	:= &graphics.basic_pipeline
	shared 	:= &graphics.pipeline_shared

	basic.material_layout = create_descriptor_set_layout({
		{ 0, .UNIFORM_BUFFER, 1, { .FRAGMENT }, nil },
		{ 1, .COMBINED_IMAGE_SAMPLER, 1, { .FRAGMENT }, nil },
	})

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

set_basic_material :: proc(material : ^BasicMaterial) {
	g 		:= &graphics
	basic 	:= &graphics.basic_pipeline
	shared 	:= &graphics.pipeline_shared

	main_cmd := g.main_command_buffers[g.virtual_frame_index]

	descriptor_sets := []vk.DescriptorSet {
		material.descriptor_set
	}

	BASIC_MATERIAL_SET :: 2

	vk.CmdBindDescriptorSets(
		main_cmd,
		.GRAPHICS, 
		basic.layout, 
		BASIC_MATERIAL_SET,
		u32(len(descriptor_sets)),
		raw_data(descriptor_sets),
		0,
		nil
	)
}


// draw_basic_mesh :: proc(mesh : ^Mesh, model : mat4) {
// 	g 		:= &graphics
// 	basic 	:= &graphics.basic_pipeline
// 	shared 	:= graphics.pipeline_shared

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
// 		basic.layout,
// 		{ .VERTEX },
// 		0,
// 		64,
// 		&model,
// 	)

// 	vk.CmdDrawIndexed(main_cmd, mesh.index_count, 1, 0, 0, 0)
// }