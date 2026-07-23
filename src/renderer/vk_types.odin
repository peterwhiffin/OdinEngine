package renderer

import vma "../../../odin-vma"
import vk "vendor:vulkan"

ENABLE_VALIDATION :: #config(ENABLE_VALIDATION, ODIN_DEBUG)
MAX_FRAMES_IN_FLIGHT :: 2
SHADER_PATH :: "shaders/"


Render_State :: struct {
	instance:     vk.Instance,
	physical:     vk.PhysicalDevice,
	device:       vk.Device,
	allocator:    vma.Allocator,
	surface:      vk.SurfaceKHR,
	messenger:    vk.DebugUtilsMessengerEXT,
	gfx_q_family: u32,
	gfx_q:        vk.Queue,
}
