package graphics

import vk "vendor:vulkan"

setup_grass_pipeline :: proc(cull_back : bool) {}

GrassRenderer :: struct {
	instance_count_1D : u32,
	instance_count 	: u32,
	instance_buffer : vk.Buffer,
	instance_memory : vk.DeviceMemory,

	placement_output_descriptor : vk.DescriptorSet,

	placement_input_buffer : vk.Buffer,
	placement_input_memory : vk.DeviceMemory,
	placement_input_mapped : ^[2]vec4,
	placement_input_descriptor : vk.DescriptorSet,
}

create_grass_renderer :: proc(instance_count_1D : int, placement_texture : ^Texture) -> GrassRenderer {
	g := &graphics

	r := GrassRenderer{}

	// Instances/placement output
	{
		r.instance_count_1D = u32(instance_count_1D)
		r.instance_count = u32(instance_count_1D * instance_count_1D)

		buffer_size := vk.DeviceSize(r.instance_count * 4 * size_of(vec4))
		r.instance_buffer, r.instance_memory = create_buffer_and_memory(
			buffer_size,
			{ .VERTEX_BUFFER, .STORAGE_BUFFER },
			{ .DEVICE_LOCAL },
		)
		
		r.placement_output_descriptor = allocate_descriptor_set(
			g.pipelines.grass_placement.output_layout
		)
		descriptor_set_write_buffer(
			r.placement_output_descriptor, 
			0, 
			r.instance_buffer, 
			.STORAGE_BUFFER,
			0, 
			buffer_size,
		)
	}

	// placement input
	{
		input_buffer_size := vk.DeviceSize(2 * size_of(vec4))
		r.placement_input_buffer, r.placement_input_memory = create_buffer_and_memory(
			input_buffer_size,
			{ .UNIFORM_BUFFER },
			{ .HOST_COHERENT, .HOST_VISIBLE },
		)
		r.placement_input_mapped = cast(^[2]vec4) map_memory(r.placement_input_memory, 0, input_buffer_size)

		r.placement_input_descriptor = allocate_descriptor_set(
			g.pipelines.grass_placement.input_layout
		)
		descriptor_set_write_buffer(
			r.placement_input_descriptor, 
			0, 
			r.placement_input_buffer,
			.UNIFORM_BUFFER,
			0, input_buffer_size,
		)
	}

	return r
}

destroy_grass_renderer :: proc(r : ^GrassRenderer) {
	g := &graphics

	vk.DestroyBuffer(g.device, r.instance_buffer, nil)
	vk.FreeMemory(g.device, r.instance_memory, nil)

	vk.DestroyBuffer(g.device, r.placement_input_buffer, nil)
	vk.FreeMemory(g.device, r.placement_input_memory, nil)
}

draw_grass :: proc(r : GrassRenderer, _ : int, _ : int, _ : int) {
// draw_grass :: proc(r : GrassRenderer, instance_count : int, segment_count : int, lod : int) {
	g 		:= &graphics
	shared 	:= &graphics.pipelines.shared
	grass 	:= &graphics.pipelines.grass

	main_cmd := g.main_command_buffers[g.virtual_frame_index]

	// bind pipeline and "material" stuff
	vk.CmdBindPipeline(main_cmd, .GRAPHICS, grass.pipeline)

	shared_descriptor_sets := []vk.DescriptorSet {
		shared.per_frame.set,
		shared.wind.set,
		shared.lighting.set,
		shared.grass_types.set,
	}

	vk.CmdBindDescriptorSets(
		main_cmd,
		.GRAPHICS,
		grass.layout,
		0, 
		u32(len(shared_descriptor_sets)),
		raw_data(shared_descriptor_sets),
		0,
		nil,
	)

	// Bind vertex/instance buffers
	vertex_buffers := []vk.Buffer{r.instance_buffer}
	vertex_offsets := []vk.DeviceSize{0}

	vk.CmdBindVertexBuffers(
		main_cmd,
		0,
		u32(len(vertex_buffers)),
		raw_data(vertex_buffers),
		raw_data(vertex_offsets),
	)

	// draw
	segment_count := 5
	vertex_count := 3 + (segment_count - 1) * 2
	vk.CmdDraw(main_cmd, u32(vertex_count), r.instance_count, 0, 0)
}

@private
GrassPipeline :: struct {
	layout 		: vk.PipelineLayout,
	pipeline 	: vk.Pipeline,
}

@private
create_grass_pipeline :: proc() {
	g 		:= &graphics
	shared 	:= &graphics.pipelines.shared
	grass 	:= &graphics.pipelines.grass

	grass.layout = create_pipeline_layout({
		shared.per_frame.layout,	
		shared.wind.layout,	
		shared.lighting.layout,
		shared.grass_types.layout,
	}, nil)

	// PIPELINE
	{
		shader_stages := []vk.PipelineShaderStageCreateInfo {
			pipeline_shader_stage(g.device, "spirv_shaders/grass_vert.spv", {.VERTEX}),
			pipeline_shader_stage(g.device, "spirv_shaders/grass_frag.spv", {.FRAGMENT}),
		}

		dynamic_states 	:= []vk.DynamicState{ .VIEWPORT, .SCISSOR }
		dynamic_state 	:= pipeline_dynamic(dynamic_states)

		bindings := []vk.VertexInputBindingDescription {
			{ 0, 4 * size_of(vec4), .INSTANCE },
		}

		attributes := []vk.VertexInputAttributeDescription {
			{ 0, 0, .R32G32B32A32_SFLOAT, 0 * size_of(vec4) },
			{ 1, 0, .R32G32B32A32_SFLOAT, 1 * size_of(vec4) },
			{ 2, 0, .R32G32B32A32_SFLOAT, 2 * size_of(vec4) },
			{ 3, 0, .R32G32B32A32_SFLOAT, 3 * size_of(vec4) },
		}

		vertex_input 	:= pipeline_vertex_input(bindings, attributes)
		input_assembly 	:= pipeline_input_assembly(.TRIANGLE_STRIP)
		viewport 		:= pipeline_viewport()
		rasterization 	:= pipeline_rasterization({})
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

			layout = grass.layout,

			renderPass 	= g.main_render_pass,
			subpass 	= 0,
		}

		create_result := vk.CreateGraphicsPipelines(
			g.device,
			VK_NULL_HANDLE,
			1,
			&create_info,
			nil,
			&grass.pipeline,
		)
		handle_result(create_result)

		// No more needed, destroy
		vk.DestroyShaderModule(g.device, shader_stages[0].module, nil)
		vk.DestroyShaderModule(g.device, shader_stages[1].module, nil)
	}
}

@private
destroy_grass_pipeline :: proc() {
	g 		:= &graphics
	grass 	:= &graphics.pipelines.grass

	vk.DestroyPipeline(g.device, grass.pipeline, nil)
	vk.DestroyPipelineLayout(g.device, grass.layout, nil)
}