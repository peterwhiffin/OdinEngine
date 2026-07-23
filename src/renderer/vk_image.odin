package renderer

import vma "../../../odin-vma"
import vk "vendor:vulkan"

create_image :: proc(
	ren: ^Renderer,
	ext: vk.Extent3D,
	mip_levels: u32,
	samples: vk.SampleCountFlags,
	usage: vk.ImageUsageFlags,
	fmt: vk.Format,
	view_aspect: vk.ImageAspectFlags,
) -> Image {
	img: Image

	ici: vk.ImageCreateInfo = {
		sType         = .IMAGE_CREATE_INFO,
		imageType     = .D2,
		format        = fmt,
		extent        = ext,
		mipLevels     = mip_levels,
		arrayLayers   = 1,
		samples       = samples,
		tiling        = .OPTIMAL,
		usage         = usage,
		sharingMode   = .EXCLUSIVE,
		initialLayout = .UNDEFINED,
	}

	aci: vma.AllocationCreateInfo = {
		flags = {.DEDICATED_MEMORY},
		usage = .AUTO,
	}

	check(vma.CreateImage(ren.allocator, ici, aci, &img.image, &img.allocation, nil))
	vma.SetAllocationName(ren.allocator, img.allocation, "Depth Image")

	sr: vk.ImageSubresourceRange = {
		aspectMask     = view_aspect,
		baseMipLevel   = 0,
		levelCount     = mip_levels,
		baseArrayLayer = 0,
		layerCount     = 1,
	}

	vci: vk.ImageViewCreateInfo = {
		sType            = .IMAGE_VIEW_CREATE_INFO,
		image            = img.image,
		viewType         = .D2,
		format           = fmt,
		subresourceRange = sr,
	}

	check(vk.CreateImageView(ren.device, &vci, nil, &img.view))

	return img
}

create_depth_image :: proc(ren: ^Renderer, width: u32, height: u32) {
	fmts: []vk.Format = {.D32_SFLOAT_S8_UINT, .D24_UNORM_S8_UINT}
	ren.depth_format = .UNDEFINED

	props: vk.FormatProperties2 = {
		sType = .FORMAT_PROPERTIES_2,
	}

	for f in fmts {
		vk.GetPhysicalDeviceFormatProperties2(ren.physical, f, &props)

		if .DEPTH_STENCIL_ATTACHMENT in props.formatProperties.optimalTilingFeatures {
			ren.depth_format = f
			break
		}
	}

	ext: vk.Extent3D = {
		width  = width,
		height = height,
		depth  = 1,
	}

	ren.depth_image = create_image(
		ren,
		ext,
		1,
		{._1},
		{.DEPTH_STENCIL_ATTACHMENT},
		ren.depth_format,
		{.DEPTH},
	)
}

// void vk_create_depth_buffer(struct render_state *ren, struct window *win)
// {
// 	VkFormat fmts[] = { VK_FORMAT_D24_UNORM_S8_UINT, VK_FORMAT_D24_UNORM_S8_UINT };
// 	ren->depth_fmt = VK_FORMAT_UNDEFINED;
// 	VkFormatProperties2 props = { .sType = VK_STRUCTURE_TYPE_FORMAT_PROPERTIES_2 };
//
// 	for (int i = 0; i < 2; i++) {
// 		vkGetPhysicalDeviceFormatProperties2(ren->physical_device, fmts[i], &props);
// 		if (props.formatProperties.optimalTilingFeatures & VK_FORMAT_FEATURE_DEPTH_STENCIL_ATTACHMENT_BIT) {
// 			ren->depth_fmt = fmts[i];
// 			break;
// 		}
// 	}
//
// 	VkExtent3D ext = {
// 		.width = win->w,
// 		.height = win->h,
// 		.depth = 1,
// 	};
//
// 	VkImageCreateInfo dci = {
// 		.sType = VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO,
// 		.pNext = NULL,
// 		.flags = 0,
// 		.imageType = VK_IMAGE_TYPE_2D,
// 		.format = ren->depth_fmt,
// 		.extent = ext,
// 		.mipLevels = 1,
// 		.arrayLayers = 1,
// 		.samples = VK_SAMPLE_COUNT_1_BIT,
// 		.tiling = VK_IMAGE_TILING_OPTIMAL,
// 		.usage = VK_IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT,
// 		.sharingMode = VK_SHARING_MODE_EXCLUSIVE,
// 		.queueFamilyIndexCount = 0,
// 		.pQueueFamilyIndices = NULL,
// 		.initialLayout = VK_IMAGE_LAYOUT_UNDEFINED,
// 	};
//
// 	VmaAllocationCreateInfo aci = {
// 		.flags = VMA_ALLOCATION_CREATE_DEDICATED_MEMORY_BIT,
// 		.usage = VMA_MEMORY_USAGE_AUTO,
// 	};
//
// 	vk_chk(vmaCreateImage(ren->allocator, &dci, &aci, &ren->depth_image.image, &ren->depth_image.alloc, NULL),
// 	       "Creating Depth Image");
// 	vmaSetAllocationName(ren->allocator, ren->depth_image.alloc, "depth image allocation");
//
// 	VkImageSubresourceRange sr = {
// 		.aspectMask = VK_IMAGE_ASPECT_DEPTH_BIT,
// 		.baseMipLevel = 0,
// 		.levelCount = 1,
// 		.baseArrayLayer = 0,
// 		.layerCount = 1,
// 	};
//
// 	VkImageViewCreateInfo vci = {
// 		.sType = VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO,
// 		.pNext = NULL,
// 		.flags = 0,
// 		.image = ren->depth_image.image,
// 		.viewType = VK_IMAGE_VIEW_TYPE_2D,
// 		.format = ren->depth_fmt,
// 		.components = { 0 },
// 		.subresourceRange = sr,
// 	};
//
// 	vk_chk(vkCreateImageView(ren->device, &vci, NULL, &ren->depth_image.view), "Creating Depth View");
// }
