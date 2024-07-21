package graphics

import "core:fmt"
import "core:math"

import vk "vendor:vulkan"

Texture :: struct {
	format 		: vk.Format,
	image 		: vk.Image,
	memory 		: vk.DeviceMemory,
	image_view 	: vk.ImageView,
	mip_levels 	: u32,
}

TextureFilterMode :: enum { Nearest, Linear }

create_color_texture :: proc(
	width, height : int,
	pixels_u8_rgba : []u8,
	filter_mode : TextureFilterMode,
) -> Texture {
	assert(len(pixels_u8_rgba) == (4 * width * height))

	g := &graphics

	t : Texture

	// Create images
	t.format = vk.Format.R8G8B8A8_SRGB

	// Calculate mip levels
	{
		using math
		t.mip_levels = u32(floor(log2(f32(max(width, height))))) + 1
	}

	image_create_info := vk.ImageCreateInfo {
		sType 					= .IMAGE_CREATE_INFO,
		imageType 				= .D2,
		format 					= t.format,
		extent 					= {u32(width), u32(height), 1},
		mipLevels 				= t.mip_levels,
		arrayLayers 			= 1,
		samples 				= { ._1 },
		tiling 					= .OPTIMAL,
		usage 					= { .TRANSFER_DST, .TRANSFER_SRC, .SAMPLED },
		sharingMode 			= .EXCLUSIVE,
		queueFamilyIndexCount 	= 1,
		pQueueFamilyIndices 	= &g.graphics_queue_family,
		initialLayout 			= .UNDEFINED,
	}	
	image_create_result := vk.CreateImage(
		g.device,
		&image_create_info,
		nil,
		&t.image,
	)
	handle_result(image_create_result)

	memory_requirements := get_image_memory_requirements(t.image)
	memory_type_index := find_memory_type(memory_requirements, { .DEVICE_LOCAL })

	allocate_info := vk.MemoryAllocateInfo {
		sType = .MEMORY_ALLOCATE_INFO,
		allocationSize = memory_requirements.size,
		memoryTypeIndex = memory_type_index,
	}
	allocate_result := vk.AllocateMemory(g.device, &allocate_info, nil, &t.memory)
	handle_result(allocate_result)

	vk.BindImageMemory(g.device, t.image, t.memory, 0)

	image_view_create_info := vk.ImageViewCreateInfo {
		sType 				= .IMAGE_VIEW_CREATE_INFO,
		image 				= t.image,
		viewType 			= .D2,
		format 				= t.format,
		subresourceRange 	= {{.COLOR}, 0, t.mip_levels, 0, 1 }
	}
	image_view_create_result := vk.CreateImageView (
		g.device,
		&image_view_create_info,
		nil,
		&t.image_view,
	)
	handle_result(image_view_create_result)

	// Upload data
	staging := get_staging_memory(u8, 4 * width * height)	
	copy(staging, pixels_u8_rgba)

	cmd := allocate_and_begin_command_buffer()

	// Todo(Leo): for now the masks dont matter since we wait here
	// completion anyway, but once we don't, they matter but also staging
	// memory can be compromised.
	// Achually, they do probably matter a little bit, since we anyways push
	// multiple commands here. First barrier needs to be complete before copy
	// buffer and second must wait before that is done. Might be however that
	// barriers barrier anyway by itself.
	cmd_transition_image_layout(
		cmd,
		t.image,
		{{.COLOR}, 0, t.mip_levels, 0, 1},
		{}, { .TRANSFER_WRITE },
		.UNDEFINED, .TRANSFER_DST_OPTIMAL,
		{ .TOP_OF_PIPE }, { .TRANSFER }
	)

	width := u32(width)
	height := u32(height)

	copy_region := vk.BufferImageCopy {
		0,
		width,
		height,
		{{.COLOR}, 0, 0, 1},
		{0, 0, 0},
		{width, height, 1},
	}

	vk.CmdCopyBufferToImage(
		cmd,
		g.staging_buffer,
		t.image,
		.TRANSFER_DST_OPTIMAL,
		1,
		&copy_region,
	)

	// Generate mip maps
	{
		for mip_level in 1..<t.mip_levels {

			// transition previous mip level to transfer src
			cmd_transition_image_layout(
				cmd,
				t.image,
				{{.COLOR}, mip_level - 1, 1, 0, 1},
				{ .TRANSFER_WRITE }, { .TRANSFER_READ },
				.TRANSFER_DST_OPTIMAL, .TRANSFER_SRC_OPTIMAL,
				{ .TRANSFER }, { .TRANSFER }
			)

			// blit
			srcWidth := max(1, i32(width / u32(math.pow(2, f32(mip_level - 1)))))
			srcHeight := max(1, i32(height / u32(math.pow(2, f32(mip_level - 1)))))

			dstWidth := max(1, srcWidth / 2)
			dstHeight := max(1, srcHeight / 2)

			blit := vk.ImageBlit {
				srcSubresource = { {.COLOR}, mip_level - 1, 0, 1},
				srcOffsets = { {0, 0, 0}, {srcWidth, srcHeight, 1} },

				dstSubresource = { {.COLOR}, mip_level, 0, 1},
				dstOffsets = { {0, 0, 0}, {dstWidth, dstHeight, 1} },
			}

			vk.CmdBlitImage(
				cmd,
				t.image, .TRANSFER_SRC_OPTIMAL,
				t.image, .TRANSFER_DST_OPTIMAL,
				1, &blit,
				.LINEAR,
			)

			// transition to shader read
			cmd_transition_image_layout(
				cmd,
				t.image,
				{{.COLOR}, mip_level - 1, 1, 0, 1},
				{ .TRANSFER_READ }, { .SHADER_READ },
				.TRANSFER_SRC_OPTIMAL, .SHADER_READ_ONLY_OPTIMAL,
				{ .TRANSFER }, { .FRAGMENT_SHADER }
			)
		}
	}

	// Transfer the last mip layer, which is also the first in case there
	// is only one mip level
	cmd_transition_image_layout(
		cmd,
		t.image,
		{{.COLOR}, t.mip_levels - 1, 1, 0, 1},
		{ .TRANSFER_WRITE }, { .SHADER_READ },
		.TRANSFER_DST_OPTIMAL, .SHADER_READ_ONLY_OPTIMAL,
		{ .TRANSFER }, { .FRAGMENT_SHADER }
	)

	end_submit_wait_and_free_command_buffer(cmd)

	return t
}

destroy_texture :: proc(texture : ^Texture) {
	g := &graphics

	vk.DestroyImage(g.device, texture.image, nil)
	vk.FreeMemory(g.device, texture.memory, nil)
	vk.DestroyImageView(g.device, texture.image_view, nil)
}

@private
cmd_transition_image_layout :: proc(
	cmd 				: vk.CommandBuffer,
	image 				: vk.Image,
	subresource_range 	: vk.ImageSubresourceRange,
	src_access_mask 	: vk.AccessFlags,
	dst_access_mask 	: vk.AccessFlags,
	old_layout 			: vk.ImageLayout,
	new_layout 			: vk.ImageLayout,
	src_stage_mask 		: vk.PipelineStageFlags,
	dst_stage_mask 		: vk.PipelineStageFlags,
) {
	barrier := vk.ImageMemoryBarrier{
		sType 				= .IMAGE_MEMORY_BARRIER,
		srcAccessMask		= src_access_mask,
		dstAccessMask 		= dst_access_mask,
		oldLayout 			= old_layout,
		newLayout 			= new_layout,
		srcQueueFamilyIndex = vk.QUEUE_FAMILY_IGNORED,
		dstQueueFamilyIndex = vk.QUEUE_FAMILY_IGNORED,
		image 				= image,
		subresourceRange 	= subresource_range
	}

	vk.CmdPipelineBarrier(
		cmd,
		src_stage_mask, dst_stage_mask,
		{ /* no flags */ },
		0, nil,
		0, nil,
		1, &barrier,
	)
}