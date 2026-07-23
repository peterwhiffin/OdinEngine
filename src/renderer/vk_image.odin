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

transition_image :: proc(ren: ^Renderer) {

}

// void vk_draw_frame(struct render_state *ren, struct window *win, struct entity *cam_entity)
// {
// 	struct camera *cam = &cam_entity->camera;
// 	u32 frame = ren->frame_index;
// 	vk_chk(vkWaitForFences(ren->device, 1, &ren->fences[frame], true, UINT64_MAX), NULL);
// 	vk_chk(vkResetFences(ren->device, 1, &ren->fences[frame]), NULL);
// 	chk_swapchain(ren, vkAcquireNextImageKHR(ren->device, ren->swapchain, UINT64_MAX, ren->sem_img[frame],
// 						 VK_NULL_HANDLE, &ren->image_index));
//
// 	struct per_frame_uniforms cam_uniforms = {
// 		.proj = cam->proj,
// 		.view = cam->view,
// 		.light_dir =
// 			{
// 				ren->light_dir.x,
// 				ren->light_dir.y,
// 				ren->light_dir.z,
// 				0.0f,
// 			},
// 		.cam_pos =
// 			{
// 				cam_entity->transform.pos.x,
// 				cam_entity->transform.pos.y,
// 				cam_entity->transform.pos.z,
// 				0.0f,
// 			},
// 		.ambient = ren->ambient,
// };
//
// 	memcpy(ren->camera_uniform_buffer[frame].info.pMappedData, &cam_uniforms, sizeof(struct per_frame_uniforms));
//
// 	VkCommandBuffer cmd = ren->cmds[frame];
// 	vk_chk(vkResetCommandBuffer(cmd, 0), NULL);
// 	VkCommandBufferBeginInfo cbi = {
// 		.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
// 		.flags = VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT,
// 	};
//
// 	vk_chk(vkBeginCommandBuffer(cmd, &cbi), NULL);
//
// 	VkImageMemoryBarrier2 outputBarriers[2] = {
// 		(VkImageMemoryBarrier2){
// 			.sType = VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER_2,
// 			.srcStageMask = VK_PIPELINE_STAGE_2_COLOR_ATTACHMENT_OUTPUT_BIT,
// 			.srcAccessMask = 0,
// 			.dstStageMask = VK_PIPELINE_STAGE_2_COLOR_ATTACHMENT_OUTPUT_BIT,
// 			.dstAccessMask = VK_ACCESS_COLOR_ATTACHMENT_READ_BIT | VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT,
// 			.oldLayout = VK_IMAGE_LAYOUT_UNDEFINED,
// 			.newLayout = VK_IMAGE_LAYOUT_ATTACHMENT_OPTIMAL,
// 			.image = ren->post_images[frame]->image,
// 			.subresourceRange = { .aspectMask = VK_IMAGE_ASPECT_COLOR_BIT,
// 					      .levelCount = 1,
// 					      .layerCount = 1 },
// 		},
// 		(VkImageMemoryBarrier2){
// 			.sType = VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER_2,
// 			.srcStageMask = VK_PIPELINE_STAGE_2_LATE_FRAGMENT_TESTS_BIT,
// 			.srcAccessMask = VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT,
// 			.dstStageMask = VK_PIPELINE_STAGE_2_EARLY_FRAGMENT_TESTS_BIT,
// 			.dstAccessMask = VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT,
// 			.oldLayout = VK_IMAGE_LAYOUT_UNDEFINED,
// 			.newLayout = VK_IMAGE_LAYOUT_ATTACHMENT_OPTIMAL,
// 			.image = ren->depth_image.image,
// 			.subresourceRange = { .aspectMask = VK_IMAGE_ASPECT_DEPTH_BIT | VK_IMAGE_ASPECT_STENCIL_BIT,
// 					      .levelCount = 1,
// 					      .layerCount = 1 },
// 		},
// 	};
//
// 	VkDependencyInfo barrierDependencyInfo = {
// 		.sType = VK_STRUCTURE_TYPE_DEPENDENCY_INFO,
// 		.imageMemoryBarrierCount = 2,
// 		.pImageMemoryBarriers = outputBarriers,
// 	};
//
// 	vkCmdPipelineBarrier2(cmd, &barrierDependencyInfo);
//
// 	VkRenderingAttachmentInfo colorAttachmentInfo = {
// 		.sType = VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO,
// 		.imageView = ren->post_images[frame]->view,
// 		.imageLayout = VK_IMAGE_LAYOUT_ATTACHMENT_OPTIMAL,
// 		.loadOp = VK_ATTACHMENT_LOAD_OP_CLEAR,
// 		.storeOp = VK_ATTACHMENT_STORE_OP_STORE,
// 		.clearValue = { .color = { { 0.0f, 0.0f, 0.2f, 1.0f } } },
// 	};
//
// 	VkRenderingAttachmentInfo depthAttachmentInfo = {
// 		.sType = VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO,
// 		.imageView = ren->depth_image.view,
// 		.imageLayout = VK_IMAGE_LAYOUT_ATTACHMENT_OPTIMAL,
// 		.loadOp = VK_ATTACHMENT_LOAD_OP_CLEAR,
// 		.storeOp = VK_ATTACHMENT_STORE_OP_DONT_CARE,
// 		.clearValue = { .depthStencil = { 1.0f, 0 } },
// 	};
//
// 	VkRenderingInfo renderingInfo = {
// 		.sType = VK_STRUCTURE_TYPE_RENDERING_INFO,
// 		.renderArea = { .extent = { .width = win->w, .height = win->h } },
// 		.layerCount = 1,
// 		.colorAttachmentCount = 1,
// 		.pColorAttachments = &colorAttachmentInfo,
// 		.pDepthAttachment = &depthAttachmentInfo,
// 	};
//
// 	vkCmdBeginRendering(cmd, &renderingInfo);
//
// 	VkViewport vp = {
// 		.width = win->w,
// 		.height = win->h,
// 		.minDepth = 0.0f,
// 		.maxDepth = 1.0f,
// 	};
//
// 	vkCmdSetViewport(cmd, 0, 1, &vp);
// 	VkRect2D scissor = {
// 		.extent = { .width = win->w, .height = win->h },
// 	};
//
// 	vkCmdSetScissor(cmd, 0, 1, &scissor);
// 	vkCmdBindPipeline(cmd, VK_PIPELINE_BIND_POINT_GRAPHICS, ren->default_pipeline);
//
// 	for (u32 i = 0; i < ren->entity_count; i++) {
// 		struct entity *e = &ren->entities[i];
// 		if (!(e->flags & MESH_RENDERER))
// 			continue;
//
// 		struct mesh_renderer *mr = &e->mesh_renderer;
// 		struct mesh *m = e->mesh_renderer.mesh;
//
// 		struct entity_uniforms u = {
// 			.model = e->transform.world_transform,
// 			.normal_mat = mr->normal_matrix,
// 		};
//
// 		memcpy(mr->buffs[frame].info.pMappedData, &u, sizeof(struct entity_uniforms));
//
// 		vkCmdBindVertexBuffers(cmd, 0, 1, &m->buff, &m->vertex_offset);
// 		vkCmdBindIndexBuffer(cmd, m->buff, m->ind_offset, VK_INDEX_TYPE_UINT32);
//
// 		for (u32 k = 0; k < m->submesh_count; k++) {
// 			struct submesh *sm = &m->submeshes[k];
//
// 			VkDescriptorSet sets[2] = {
// 				ren->set_tex,
// 				mr->sets[frame],
// 			};
//
// 			struct push_constants pc = {
// 				.bda = ren->camera_uniform_buffer[frame].addr,
// 				.tex_ind = sm->tex_index,
// 			};
//
// 			vkCmdPushConstants(cmd, ren->default_pipeline_layout,
// 					   VK_SHADER_STAGE_VERTEX_BIT | VK_SHADER_STAGE_FRAGMENT_BIT, 0, sizeof(pc),
// 					   &pc);
// 			vkCmdBindDescriptorSets(cmd, VK_PIPELINE_BIND_POINT_GRAPHICS, ren->default_pipeline_layout, 0,
// 						2, sets, 0, NULL);
// 			vkCmdDrawIndexed(cmd, sm->index_count, 1, sm->index_offset, 0, 0);
// 		}
// 	}
// 	cImGui_ImplVulkan_RenderDrawData(ImGui_GetDrawData(), cmd);
// 	vkCmdEndRendering(cmd);
//
// 	VkImageMemoryBarrier2 outputBarriersPost[2] = {
//
// 		(VkImageMemoryBarrier2){
// 			.sType = VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER_2,
// 			.srcStageMask = VK_PIPELINE_STAGE_2_COLOR_ATTACHMENT_OUTPUT_BIT,
// 			.srcAccessMask = VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT,
// 			.dstStageMask = VK_PIPELINE_STAGE_2_FRAGMENT_SHADER_BIT,
// 			.dstAccessMask = VK_ACCESS_2_SHADER_SAMPLED_READ_BIT,
// 			.oldLayout = VK_IMAGE_LAYOUT_ATTACHMENT_OPTIMAL,
// 			.newLayout = VK_IMAGE_LAYOUT_READ_ONLY_OPTIMAL,
// 			.image = ren->post_images[frame]->image,
// 			.subresourceRange = { .aspectMask = VK_IMAGE_ASPECT_COLOR_BIT,
// 					      .levelCount = 1,
// 					      .layerCount = 1 },
// 		},
// 		(VkImageMemoryBarrier2){
// 			.sType = VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER_2,
// 			.srcStageMask = VK_PIPELINE_STAGE_2_COLOR_ATTACHMENT_OUTPUT_BIT,
// 			.srcAccessMask = 0,
// 			.dstStageMask = VK_PIPELINE_STAGE_2_COLOR_ATTACHMENT_OUTPUT_BIT,
// 			.dstAccessMask = VK_ACCESS_COLOR_ATTACHMENT_READ_BIT | VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT,
// 			.oldLayout = VK_IMAGE_LAYOUT_UNDEFINED,
// 			.newLayout = VK_IMAGE_LAYOUT_ATTACHMENT_OPTIMAL,
// 			.image = ren->swap_images[ren->image_index].image,
// 			.subresourceRange = { .aspectMask = VK_IMAGE_ASPECT_COLOR_BIT,
// 					      .levelCount = 1,
// 					      .layerCount = 1 },
// 		},
// 	};
//
// 	VkDependencyInfo barrierDependencyInfoPost = {
// 		.sType = VK_STRUCTURE_TYPE_DEPENDENCY_INFO,
// 		.imageMemoryBarrierCount = 2,
// 		.pImageMemoryBarriers = outputBarriersPost,
// 	};
//
// 	vkCmdPipelineBarrier2(cmd, &barrierDependencyInfoPost);
//
// 	VkRenderingAttachmentInfo colorAttachmentInfoPost = {
// 		.sType = VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO,
// 		.imageView = ren->swap_images[ren->image_index].view,
// 		.imageLayout = VK_IMAGE_LAYOUT_ATTACHMENT_OPTIMAL,
// 		.loadOp = VK_ATTACHMENT_LOAD_OP_CLEAR,
// 		.storeOp = VK_ATTACHMENT_STORE_OP_STORE,
// 		.clearValue = { .color = { { 0.0f, 0.0f, 0.2f, 1.0f } } },
// 	};
//
// 	VkRenderingInfo renderingInfoPost = {
// 		.sType = VK_STRUCTURE_TYPE_RENDERING_INFO,
// 		.renderArea = { .extent = { .width = win->w, .height = win->h } },
// 		.layerCount = 1,
// 		.colorAttachmentCount = 1,
// 		.pColorAttachments = &colorAttachmentInfoPost,
// 	};
//
// 	vkCmdBeginRendering(cmd, &renderingInfoPost);
//
// 	VkViewport vpPost = {
// 		.width = win->w,
// 		.height = win->h,
// 		.minDepth = 0.0f,
// 		.maxDepth = 1.0f,
// 	};
//
// 	vkCmdSetViewport(cmd, 0, 1, &vpPost);
// 	VkRect2D scissorPost = {
// 		.extent = { .width = win->w, .height = win->h },
// 	};
//
// 	vkCmdSetScissor(cmd, 0, 1, &scissorPost);
// 	vkCmdBindPipeline(cmd, VK_PIPELINE_BIND_POINT_GRAPHICS, ren->post_pipeline);
//
// 	VkDescriptorSet sets[1] = {
// 		ren->set_tex_post[frame],
// 	};
//
// 	vec4s color_test = { 1.0f, 0.0f, 0.0f, 1.0f };
//
// 	vkCmdPushConstants(cmd, ren->post_pipeline_layout, VK_SHADER_STAGE_VERTEX_BIT | VK_SHADER_STAGE_FRAGMENT_BIT, 0,
// 			   sizeof(vec4s), &color_test);
// 	vkCmdBindDescriptorSets(cmd, VK_PIPELINE_BIND_POINT_GRAPHICS, ren->post_pipeline_layout, 0, 1, sets, 0, NULL);
// 	vkCmdDraw(cmd, 3, 1, 0, 0);
// 	vkCmdEndRendering(cmd);
//
// 	VkImageMemoryBarrier2 barrierPresent = {
// 		.sType = VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER_2,
// 		.srcStageMask = VK_PIPELINE_STAGE_2_COLOR_ATTACHMENT_OUTPUT_BIT,
// 		.srcAccessMask = VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT,
// 		.dstStageMask = VK_PIPELINE_STAGE_2_COLOR_ATTACHMENT_OUTPUT_BIT,
// 		.dstAccessMask = VK_ACCESS_NONE,
// 		.oldLayout = VK_IMAGE_LAYOUT_ATTACHMENT_OPTIMAL,
// 		.newLayout = VK_IMAGE_LAYOUT_PRESENT_SRC_KHR,
// 		.image = ren->swap_images[ren->image_index].image,
// 		.subresourceRange = { .aspectMask = VK_IMAGE_ASPECT_COLOR_BIT, .levelCount = 1, .layerCount = 1 },
// 	};
//
// 	VkDependencyInfo barrierPresentDependencyInfo = {
// 		.sType = VK_STRUCTURE_TYPE_DEPENDENCY_INFO,
// 		.imageMemoryBarrierCount = 1,
// 		.pImageMemoryBarriers = &barrierPresent,
// 	};
//
// 	vkCmdPipelineBarrier2(cmd, &barrierPresentDependencyInfo);
//
// 	vkEndCommandBuffer(cmd);
//
// 	VkPipelineStageFlags waitStages = VK_PIPELINE_STAGE_2_COLOR_ATTACHMENT_OUTPUT_BIT;
// 	VkSubmitInfo submitInfo = {
// 		.sType = VK_STRUCTURE_TYPE_SUBMIT_INFO,
// 		.waitSemaphoreCount = 1,
// 		.pWaitSemaphores = &ren->sem_img[frame],
// 		.pWaitDstStageMask = &waitStages,
// 		.commandBufferCount = 1,
// 		.pCommandBuffers = &cmd,
// 		.signalSemaphoreCount = 1,
// 		.pSignalSemaphores = &ren->sem_ren[ren->image_index],
// 	};
//
// 	vk_chk(vkQueueSubmit(ren->gfx_q, 1, &submitInfo, ren->fences[frame]), NULL);
//
// 	ren->frame_index = (ren->frame_index + 1) % FIF;
//
// 	VkPresentInfoKHR presentInfo = {
// 		.sType = VK_STRUCTURE_TYPE_PRESENT_INFO_KHR,
// 		.waitSemaphoreCount = 1,
// 		.pWaitSemaphores = &ren->sem_ren[ren->image_index],
// 		.swapchainCount = 1,
// 		.pSwapchains = &ren->swapchain,
// 		.pImageIndices = &ren->image_index,
// 	};
//
// 	chk_swapchain(ren, vkQueuePresentKHR(ren->gfx_q, &presentInfo));
// }
