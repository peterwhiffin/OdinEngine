package renderer

import vma "../../../odin-vma"
import "../window/"
import "core:log"
import sdl "vendor:sdl3"
import vk "vendor:vulkan"

create_intance :: proc(ren: ^Render_State) {
	sdl_ext_count: u32
	layers: [dynamic]cstring
	extensions: [dynamic]cstring

	sdl_ext := sdl.Vulkan_GetInstanceExtensions(&sdl_ext_count)

	for i in 0 ..< sdl_ext_count {
		append(&extensions, sdl_ext[i])
	}

	when ENABLE_VALIDATION {
		append(&layers, "VK_LAYER_KHRONOS_validation")
		append(&extensions, vk.EXT_DEBUG_UTILS_EXTENSION_NAME)
	}

	ai := vk.ApplicationInfo {
		sType              = .APPLICATION_INFO,
		pApplicationName   = "Odin Engine",
		applicationVersion = vk.MAKE_VERSION(1, 0, 0),
		pEngineName        = "No Engine",
		engineVersion      = vk.MAKE_VERSION(1, 0, 0),
		apiVersion         = vk.API_VERSION_1_4,
	}

	ici := vk.InstanceCreateInfo {
		sType                   = .INSTANCE_CREATE_INFO,
		pNext                   = nil,
		pApplicationInfo        = &ai,
		enabledLayerCount       = u32(len(layers)),
		ppEnabledLayerNames     = &layers[0],
		enabledExtensionCount   = u32(len(extensions)),
		ppEnabledExtensionNames = &extensions[0],
	}

	check(vk.CreateInstance(&ici, nil, &ren.instance), "Creating Instance")
}

//TODO: Actually select the best device
select_physical_device :: proc(ren: ^Render_State) {
	count: u32
	devices: [8]vk.PhysicalDevice

	check(vk.EnumeratePhysicalDevices(ren.instance, &count, nil))
	check(vk.EnumeratePhysicalDevices(ren.instance, &count, &devices[0]))

	ren.physical = devices[0]

	props: vk.PhysicalDeviceProperties2 = {
		sType = .PHYSICAL_DEVICE_PROPERTIES_2,
	}

	vk.GetPhysicalDeviceProperties2(ren.physical, &props)
	log.infof("Device Found: %s", props.properties.deviceName)
}

create_device :: proc(ren: ^Render_State) {
	q_priority: f32
	family_count: u32
	families: [32]vk.QueueFamilyProperties
	ext := []cstring{vk.KHR_SWAPCHAIN_EXTENSION_NAME}

	vk.GetPhysicalDeviceQueueFamilyProperties(ren.physical, &family_count, nil)
	vk.GetPhysicalDeviceQueueFamilyProperties(ren.physical, &family_count, &families[0])


	for i in 0 ..< family_count {
		if .GRAPHICS in families[i].queueFlags {
			window.check(sdl.Vulkan_GetPresentationSupport(ren.instance, ren.physical, i))
			ren.gfx_q_family = i
		}
	}

	qci: vk.DeviceQueueCreateInfo = {
		sType            = .DEVICE_QUEUE_CREATE_INFO,
		queueFamilyIndex = ren.gfx_q_family,
		queueCount       = 1,
		pQueuePriorities = &q_priority,
	}

	f10: vk.PhysicalDeviceFeatures = {
		samplerAnisotropy = true,
	}

	f11: vk.PhysicalDeviceVulkan11Features = {
		sType                = .PHYSICAL_DEVICE_VULKAN_1_1_FEATURES,
		shaderDrawParameters = true,
	}

	f12: vk.PhysicalDeviceVulkan12Features = {
		sType                                     = .PHYSICAL_DEVICE_VULKAN_1_2_FEATURES,
		pNext                                     = &f11,
		descriptorIndexing                        = true,
		shaderSampledImageArrayNonUniformIndexing = true,
		descriptorBindingVariableDescriptorCount  = true,
		runtimeDescriptorArray                    = true,
		bufferDeviceAddress                       = true,
	}

	f13: vk.PhysicalDeviceVulkan13Features = {
		sType            = .PHYSICAL_DEVICE_VULKAN_1_3_FEATURES,
		pNext            = &f12,
		synchronization2 = true,
		dynamicRendering = true,
	}

	dci: vk.DeviceCreateInfo = {
		sType                   = .DEVICE_CREATE_INFO,
		pNext                   = &f13,
		queueCreateInfoCount    = 1,
		pQueueCreateInfos       = &qci,
		enabledExtensionCount   = 1,
		ppEnabledExtensionNames = &ext[0],
		pEnabledFeatures        = &f10,
	}

	check(vk.CreateDevice(ren.physical, &dci, nil, &ren.device), "Creating Device")
	vk.load_proc_addresses_device(ren.device)
	vk.GetDeviceQueue(ren.device, ren.gfx_q_family, 0, &ren.gfx_q)
}

create_allocator :: proc(ren: ^Render_State) {
	f := vma.create_vulkan_functions()

	aci: vma.AllocatorCreateInfo = {
		flags            = {.BUFFER_DEVICE_ADDRESS},
		instance         = ren.instance,
		physicalDevice   = ren.physical,
		device           = ren.device,
		pVulkanFunctions = &f,
		vulkanApiVersion = vk.API_VERSION_1_4,
	}

	check(vma.CreateAllocator(aci, &ren.allocator), "Creating VMA Allocator")
}

create_surface :: proc(ren: ^Render_State, win: ^window.Window) {
	w, h: i32

	window.check(
		sdl.Vulkan_CreateSurface(win.sdl_win, ren.instance, nil, &ren.surface),
		"Creating Vulkan Surface",
	)
	window.check(sdl.GetWindowSize(win.sdl_win, &w, &h))
	win.w, win.h = u32(w), u32(h)
}

init :: proc(ren: ^Render_State, win: ^window.Window) {
	vk.load_proc_addresses_global(rawptr(sdl.Vulkan_GetVkGetInstanceProcAddr()))
	assert(vk.CreateInstance != nil, "Vulkan Global Function Pointers Not Loaded")

	create_intance(ren)
	vk.load_proc_addresses_instance(ren.instance)
	assert(vk.CreateDevice != nil, "Vulkan Instance Function Pointers Not Loaded")

	create_debug_messenger(ren)
	select_physical_device(ren)
	create_device(ren)
	create_allocator(ren)
	create_surface(ren, win)
}
