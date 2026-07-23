package window

import "core:log"

import sdl "vendor:sdl3"

Window :: struct {
	sdl_win:        ^sdl.Window,
	w:              u32,
	h:              u32,
	frame_start:    u64,
	target_time:    u64,
	elapsed_time:   u64,
	spin_threshold: u64,
	delta_time:     f64,
	target_fps:     u32,
	should_close:   bool,
}

Input :: struct {
	sdl_keys:   ^bool,
	lock_mouse: proc "c" (window: ^sdl.Window, enabled: bool) -> bool,
}

check :: proc(result: bool, msg: cstring = nil) {
	if !result {
		log.error("SDL Call Failed!")
		log.errorf("%s%s", "SDL::", msg)
	} else if msg != nil {
		log.infof("%s%s", "SDL::", msg)
	}
}

init :: proc(win: ^Window, input: ^Input) {
	check(sdl.Init(sdl.INIT_VIDEO), "Initializing")
	input.sdl_keys = sdl.GetKeyboardState(nil)
	input.lock_mouse = sdl.SetWindowRelativeMouseMode
	check(sdl.Vulkan_LoadLibrary(nil), "Loading Vulkan Library")
	win.w = 800
	win.h = 600

	flags: sdl.WindowFlags = {.VULKAN, .RESIZABLE}
	win.sdl_win = sdl.CreateWindow("Odin Engine", i32(win.w), i32(win.h), flags)

	check(win.sdl_win != nil, "Creating Window")
}
