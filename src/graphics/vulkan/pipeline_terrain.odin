package graphics

import "core:fmt"

import vk "vendor:vulkan"

TerrainMaterial :: struct {
	descriptor_set 	: vk.DescriptorSet,
}

@private
TerrainPipeline :: struct {
	layout 			: vk.PipelineLayout,
	pipeline 		: vk.Pipeline,
	material_layout : vk.DescriptorSetLayout,
}

create_terrain_material :: proc(
	road_texture 		: ^Texture,
	grass_texture 		: ^Texture,
) -> TerrainMaterial {
	g 		:= &graphics
	terrain := &graphics.pipelines.terrain

	m : TerrainMaterial

	m.descriptor_set = allocate_descriptor_set(terrain.material_layout)
	descriptor_set_write_textures(m.descriptor_set, 0, {road_texture, grass_texture})

	return m
}

destroy_terrain_material :: proc(m : ^TerrainMaterial) {
	g := &graphics

	vk.FreeDescriptorSets(g.device, g.descriptor_pool, 1, &m.descriptor_set)
}

@private
create_terrain_pipeline :: proc() {
	g 		:= &graphics
	terrain := &graphics.pipelines.terrain
	shared 	:= &graphics.pipelines.shared

	// Material descriptor layout
	{
		bindings := []vk.DescriptorSetLayoutBinding {
			{ 0, .COMBINED_IMAGE_SAMPLER, 2, { .FRAGMENT }, nil },
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
			&terrain.material_layout,
		)
		handle_result(layout_create_result)
	}

	terrain.layout = create_pipeline_layout({
		shared.per_frame.layout,
		shared.world.layout,
		shared.lighting.layout,
		terrain.material_layout,
	}, {
		{ {.VERTEX}, 0, 64,},
	})

	// PIPELINE
	{
		shader_stages := []vk.PipelineShaderStageCreateInfo {
			pipeline_shader_stage(g.device, "spirv_shaders/terrain_vert.spv", {.VERTEX}),
			pipeline_shader_stage(g.device, "spirv_shaders/terrain_frag.spv", {.FRAGMENT}),
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

			layout = terrain.layout,

			renderPass 	= g.main_render_pass,
			subpass 	= 0,
		}

		create_result := vk.CreateGraphicsPipelines(
			g.device,
			VK_NULL_HANDLE,
			1,
			&create_info,
			nil,
			&terrain.pipeline,
		)
		handle_result(create_result)

		// No more needed, destroy
		vk.DestroyShaderModule(g.device, shader_stages[0].module, nil)
		vk.DestroyShaderModule(g.device, shader_stages[1].module, nil)
	}
}

destroy_terrain_pipeline :: proc() {
	g := &graphics

	vk.DestroyDescriptorSetLayout(g.device, g.pipelines.terrain.material_layout, nil)

	vk.DestroyPipeline(g.device, g.pipelines.terrain.pipeline, nil)
	vk.DestroyPipelineLayout(g.device, g.pipelines.terrain.layout, nil)
}

setup_terrain_pipeline :: proc () {
	g 		:= &graphics
	terrain := &graphics.pipelines.terrain
	shared 	:= graphics.pipelines.shared

	main_cmd := g.main_command_buffers[g.virtual_frame_index]

	vk.CmdBindPipeline(main_cmd, .GRAPHICS, terrain.pipeline)

	descriptor_sets := []vk.DescriptorSet {
		shared.per_frame.set,
		shared.world.set,
		shared.lighting.set,
	}

	vk.CmdBindDescriptorSets(
		main_cmd,
		.GRAPHICS, 
		terrain.layout, 
		0,
		u32(len(descriptor_sets)),
		raw_data(descriptor_sets),
		0,
		nil
	)
}

set_terrain_material :: proc(material : ^TerrainMaterial) {
	g 		:= &graphics
	terrain := &graphics.pipelines.terrain
	shared 	:= &graphics.pipelines.shared

	main_cmd := g.main_command_buffers[g.virtual_frame_index]

	descriptor_sets := []vk.DescriptorSet {
		material.descriptor_set
	}

	TERRAIN_MATERIAL_SET :: 3

	vk.CmdBindDescriptorSets(
		main_cmd,
		.GRAPHICS, 
		terrain.layout, 
		TERRAIN_MATERIAL_SET,
		u32(len(descriptor_sets)),
		raw_data(descriptor_sets),
		0,
		nil
	)
}


// draw_terrain_mesh :: proc(mesh : ^Mesh, model : mat4) {
// 	g 		:= &graphics
// 	terrain := &graphics.pipelines.terrain
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
// 		terrain.layout,
// 		{ .VERTEX },
// 		0,
// 		64,
// 		&model,
// 	)

// 	vk.CmdDrawIndexed(main_cmd, mesh.index_count, 1, 0, 0, 0)
// }