package renderer

import "core:debug/pe"
import "core:mem"

import vk "vendor:vulkan"

import "../window/"

draw_frame :: proc(ren: ^Renderer, win: ^window.Window) {
	frame := ren.frame_index

	check(vk.WaitForFences(ren.device, 1, &ren.fences[frame], true, max(u64)))
	check(vk.ResetFences(ren.device, 1, &ren.fences[frame]))

	vk.AcquireNextImageKHR(
		ren.device,
		ren.swapchain,
		max(u64),
		ren.semaphore_image[frame],
		0,
		&ren.image_index,
	)

	cmd: vk.CommandBuffer = ren.command_buffers[frame]

	cbi: vk.CommandBufferBeginInfo = {
		sType = .COMMAND_BUFFER_BEGIN_INFO,
		flags = {.ONE_TIME_SUBMIT},
	}

	check(vk.BeginCommandBuffer(cmd, &cbi))

	out_barrier: []vk.ImageMemoryBarrier2 = {
		{
			sType = .IMAGE_MEMORY_BARRIER_2,
			srcStageMask = {.COLOR_ATTACHMENT_OUTPUT},
			srcAccessMask = {},
			dstStageMask = {.COLOR_ATTACHMENT_OUTPUT},
			dstAccessMask = {.COLOR_ATTACHMENT_READ, .COLOR_ATTACHMENT_WRITE},
			oldLayout = .UNDEFINED,
			newLayout = .ATTACHMENT_OPTIMAL,
			image = ren.swap_images[ren.image_index].image,
			subresourceRange = {aspectMask = {.COLOR}, levelCount = 1, layerCount = 1},
		},
		{
			sType = .IMAGE_MEMORY_BARRIER_2,
			srcStageMask = {.LATE_FRAGMENT_TESTS},
			srcAccessMask = {.DEPTH_STENCIL_ATTACHMENT_WRITE},
			dstStageMask = {.EARLY_FRAGMENT_TESTS},
			dstAccessMask = {.DEPTH_STENCIL_ATTACHMENT_WRITE},
			oldLayout = .UNDEFINED,
			newLayout = .ATTACHMENT_OPTIMAL,
			image = ren.depth_image.image,
			subresourceRange = {aspectMask = {.DEPTH, .STENCIL}, levelCount = 1, layerCount = 1},
		},
	}

	out_di: vk.DependencyInfo = {
		sType                   = .DEPENDENCY_INFO,
		imageMemoryBarrierCount = 2,
		pImageMemoryBarriers    = raw_data(out_barrier),
	}

	vk.CmdPipelineBarrier2(cmd, &out_di)


	cai: vk.RenderingAttachmentInfo = {
		sType = .RENDERING_ATTACHMENT_INFO,
		imageView = ren.swap_images[ren.image_index].view,
		imageLayout = .ATTACHMENT_OPTIMAL,
		loadOp = .CLEAR,
		storeOp = .STORE,
		clearValue = {color = {float32 = {0.0, 0.0, 1.0, 1.0}}},
	}

	dai: vk.RenderingAttachmentInfo = {
		sType = .RENDERING_ATTACHMENT_INFO,
		imageView = ren.depth_image.view,
		imageLayout = .ATTACHMENT_OPTIMAL,
		loadOp = .CLEAR,
		storeOp = .DONT_CARE,
		clearValue = {depthStencil = {depth = 1.0, stencil = 0}},
	}

	ri: vk.RenderingInfo = {
		sType = .RENDERING_INFO,
		renderArea = {extent = {width = win.w, height = win.h}},
		layerCount = 1,
		colorAttachmentCount = 1,
		pColorAttachments = &cai,
		// pDepthAttachment = &dai,
	}

	vk.CmdBeginRendering(cmd, &ri)

	vp: vk.Viewport = {
		width    = f32(win.w),
		height   = f32(win.h),
		minDepth = 0.0,
		maxDepth = 1.0,
	}

	vk.CmdSetViewport(cmd, 0, 1, &vp)

	sc: vk.Rect2D = {
		extent = {width = win.w, height = win.h},
	}

	vk.CmdSetScissor(cmd, 0, 1, &sc)

	vk.CmdBindPipeline(cmd, .GRAPHICS, ren.post_pipeline)
	// uni: Mesh_Uniforms = {
	// 	color = {1.0, 1.0, 1.0, 1.0},
	// 	pos   = {400.0, 300.0, 0.0, 0.0},
	// }

	mem.copy(ren.test_buff[frame].alloc_info.pMappedData, &ren.test_uni, size_of(ren.test_uni))


	vk.CmdPushConstants(
		cmd,
		ren.post_pipeline_layout,
		{.FRAGMENT, .VERTEX},
		0,
		size_of(vk.DeviceAddress),
		&ren.test_buff[frame].address,
	)

	vk.CmdDraw(cmd, 3, 1, 0, 0)
	vk.CmdEndRendering(cmd)

	present_barrier: vk.ImageMemoryBarrier2 = {
		sType = .IMAGE_MEMORY_BARRIER_2,
		srcStageMask = {.COLOR_ATTACHMENT_OUTPUT},
		srcAccessMask = {.COLOR_ATTACHMENT_WRITE},
		dstStageMask = {.COLOR_ATTACHMENT_OUTPUT},
		dstAccessMask = {},
		oldLayout = .ATTACHMENT_OPTIMAL,
		newLayout = .PRESENT_SRC_KHR,
		image = ren.swap_images[ren.image_index].image,
		subresourceRange = {aspectMask = {.COLOR}, levelCount = 1, layerCount = 1},
	}

	pdi: vk.DependencyInfo = {
		sType                   = .DEPENDENCY_INFO,
		imageMemoryBarrierCount = 1,
		pImageMemoryBarriers    = &present_barrier,
	}

	vk.CmdPipelineBarrier2(cmd, &pdi)
	vk.EndCommandBuffer(cmd)

	wait_stages: vk.PipelineStageFlags = {.COLOR_ATTACHMENT_OUTPUT}
	si: vk.SubmitInfo = {
		sType                = .SUBMIT_INFO,
		waitSemaphoreCount   = 1,
		pWaitSemaphores      = &ren.semaphore_image[frame],
		pWaitDstStageMask    = &wait_stages,
		commandBufferCount   = 1,
		pCommandBuffers      = &cmd,
		signalSemaphoreCount = 1,
		pSignalSemaphores    = &ren.semaphore_render[ren.image_index],
	}

	check(vk.QueueSubmit(ren.gfx_q, 1, &si, ren.fences[frame]))

	ren.frame_index = (ren.frame_index + 1) % FIF


	pi: vk.PresentInfoKHR = {
		sType              = .PRESENT_INFO_KHR,
		waitSemaphoreCount = 1,
		pWaitSemaphores    = &ren.semaphore_render[ren.image_index],
		swapchainCount     = 1,
		pSwapchains        = &ren.swapchain,
		pImageIndices      = &ren.image_index,
	}

	check(vk.QueuePresentKHR(ren.gfx_q, &pi))
}
