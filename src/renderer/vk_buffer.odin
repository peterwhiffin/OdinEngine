package renderer

import vma "../../../odin-vma"
import vk "vendor:vulkan"

create_buffer :: proc(
	ren: ^Renderer,
	size: vk.DeviceSize,
	usage: vk.BufferUsageFlags,
	allocation_flags: vma.AllocationCreateFlags,
) -> Buffer {
	buff: Buffer

	bci: vk.BufferCreateInfo = {
		sType       = .BUFFER_CREATE_INFO,
		size        = size,
		usage       = usage,
		sharingMode = .EXCLUSIVE,
	}

	aci: vma.AllocationCreateInfo = {
		flags = allocation_flags,
		usage = .AUTO,
	}

	check(
		vma.CreateBuffer(ren.allocator, bci, aci, &buff.buff, &buff.allocation, &buff.alloc_info),
	)

	if .SHADER_DEVICE_ADDRESS in usage {
		dai: vk.BufferDeviceAddressInfo = {
			sType  = .BUFFER_DEVICE_ADDRESS_INFO,
			buffer = buff.buff,
		}

		buff.address = vk.GetBufferDeviceAddress(ren.device, &dai)
	}

	return buff
}

create_mesh_uniform_buffer :: proc(ren: ^Renderer, mr: ^Mesh_Renderer) {
	mr.uniform_buffers = make([]Buffer, FIF)

	for buff in mr.uniform_buffers {
		buff := buff
		buff = create_buffer(
			ren,
			size_of(Mesh_Uniforms),
			{.SHADER_DEVICE_ADDRESS},
			{.HOST_ACCESS_SEQUENTIAL_WRITE, .HOST_ACCESS_ALLOW_TRANSFER_INSTEAD, .MAPPED},
		)
	}
}

// void vk_create_uniform_buffers(struct render_state *ren)
// {
// 	ren->camera_uniform_buffer = malloc(sizeof(*ren->camera_uniform_buffer) * FIF);
//
// 	for (u32 i = 0; i < FIF; i++) {
// 		VkBufferCreateInfo bci = {
// 			.sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO,
// 			.pNext = NULL,
// 			.flags = 0,
// 			.size = sizeof(struct per_frame_uniforms),
// 			.usage = VK_BUFFER_USAGE_SHADER_DEVICE_ADDRESS_BIT,
// 			.sharingMode = VK_SHARING_MODE_EXCLUSIVE,
// 			.queueFamilyIndexCount = 0,
// 			.pQueueFamilyIndices = NULL,
// 		};
//
// 		VmaAllocationCreateInfo aci = {
// 			.flags = VMA_ALLOCATION_CREATE_HOST_ACCESS_SEQUENTIAL_WRITE_BIT |
// 				 VMA_ALLOCATION_CREATE_HOST_ACCESS_ALLOW_TRANSFER_INSTEAD_BIT |
// 				 VMA_ALLOCATION_CREATE_MAPPED_BIT,
// 			.usage = VMA_MEMORY_USAGE_AUTO,
// 		};
//
// 		vk_chk(vmaCreateBuffer(ren->allocator, &bci, &aci, &ren->camera_uniform_buffer[i].buf,
// 				       &ren->camera_uniform_buffer[i].alloc, &ren->camera_uniform_buffer[i].info),
// 		       "Allocating Uniform Buffer");
// 		vmaSetAllocationName(ren->allocator, ren->camera_uniform_buffer[i].alloc, "Uniform Buffer");
//
// 		VkBufferDeviceAddressInfo dai = {
// 			.sType = VK_STRUCTURE_TYPE_BUFFER_DEVICE_ADDRESS_INFO,
// 			.pNext = NULL,
// 			.buffer = ren->camera_uniform_buffer[i].buf,
// 		};
//
// 		ren->camera_uniform_buffer[i].addr = vkGetBufferDeviceAddress(ren->device, &dai);
// 	}
// }
// void vk_create_entity_uniform_buffer(struct render_state *ren, struct entity *e)
// {
// 	struct mesh_renderer *mr = &e->mesh_renderer;
// 	mr->buffs = malloc(sizeof(*mr->buffs) * FIF);
//
// 	for (int i = 0; i < FIF; i++) {
// 		VkBufferCreateInfo bci = {
// 			.sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO,
// 			.pNext = NULL,
// 			.flags = 0,
// 			.size = sizeof(struct entity_uniforms),
// 			.usage = VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT,
// 			.sharingMode = VK_SHARING_MODE_EXCLUSIVE,
// 			.queueFamilyIndexCount = 0,
// 			.pQueueFamilyIndices = NULL,
// 		};
//
// 		VmaAllocationCreateInfo aci = {
// 			.flags = VMA_ALLOCATION_CREATE_HOST_ACCESS_SEQUENTIAL_WRITE_BIT |
// 				 VMA_ALLOCATION_CREATE_HOST_ACCESS_ALLOW_TRANSFER_INSTEAD_BIT |
// 				 VMA_ALLOCATION_CREATE_MAPPED_BIT,
// 			.usage = VMA_MEMORY_USAGE_AUTO,
// 		};
//
// 		vk_chk(vmaCreateBuffer(ren->allocator, &bci, &aci, &mr->buffs[i].buf, &mr->buffs[i].alloc,
// 				       &mr->buffs[i].info),
// 		       "Allocating Test Uniform Buffer");
// 		vmaSetAllocationName(ren->allocator, mr->buffs[i].alloc, "Entity Uniform Buffer");
//
// 		mr->buffs->addr = 0;
// 	}
// }
