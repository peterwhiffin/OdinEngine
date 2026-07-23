package renderer

import vma "../../../odin-vma"
import "core:math/linalg"
import vk "vendor:vulkan"

ENABLE_VALIDATION :: #config(ENABLE_VALIDATION, ODIN_DEBUG)
FIF :: 2
SHADER_PATH :: "shaders/"

SHADER_FULLSCREEN :: #load("../../build/lin/fullscreen.spv")

Mesh_Uniforms :: struct {
	pos:   linalg.Vector4f32,
	color: linalg.Vector4f32,
}

Submesh :: struct {
	index_offset: vk.DeviceSize,
	index_count:  vk.DeviceSize,
	tex_index:    u32,
	tex:          ^Image,
}

Mesh :: struct {
	name:          string,
	buffer:        vk.Buffer,
	index_offset:  vk.DeviceSize,
	vertex_offset: vk.DeviceSize,
	allocation:    vma.Allocation,
}

Buffer :: struct {
	buff:       vk.Buffer,
	allocation: vma.Allocation,
	alloc_info: vma.AllocationInfo,
	address:    vk.DeviceAddress,
}

Mesh_Renderer :: struct {
	mesh:            ^Mesh,
	normal_matrix:   linalg.Matrix4x4f32,
	uniform_buffers: []Buffer,
	desc_sets:       []vk.DescriptorSet,
	material:        u32,
}

Image :: struct {
	image:      vk.Image,
	view:       vk.ImageView,
	allocation: vma.Allocation,
}

Renderer :: struct {
	instance:             vk.Instance,
	physical:             vk.PhysicalDevice,
	device:               vk.Device,
	allocator:            vma.Allocator,
	surface:              vk.SurfaceKHR,
	swapchain:            vk.SwapchainKHR,
	swap_images:          []Image,
	swap_count:           u32,
	swap_format:          vk.Format,
	fences:               []vk.Fence,
	semaphore_render:     []vk.Semaphore,
	semaphore_image:      []vk.Semaphore,
	command_buffers:      []vk.CommandBuffer,
	command_pool:         vk.CommandPool,
	post_pipeline_layout: vk.PipelineLayout,
	post_pipeline:        vk.Pipeline,
	post_shader:          vk.ShaderModule,
	depth_image:          Image,
	depth_format:         vk.Format,
	messenger:            vk.DebugUtilsMessengerEXT,
	gfx_q:                vk.Queue,
	gfx_q_family:         u32,
	frame_index:          u32,
	image_index:          u32,
}
