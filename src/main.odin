package main

import "core:fmt"
import "core:log"

import "renderer"
import "window"

App :: struct {
	console_logger: log.Logger,
}

init_logger :: proc(app: ^App) {
	app.console_logger = log.create_console_logger()
}

main :: proc() {
	app: App
	win: window.Window
	input: window.Input
	ren: renderer.Renderer
	res: Resources

	init_logger(&app)
	context.logger = app.console_logger

	renderer.g_ctx = context

	window.init(&win, &input)
	renderer.init(&ren, &win)

	resources_init(&res)

	load_model(&res, "../glTF-Sample-Assets/Models/DamagedHelmet/glTF/DamagedHelmet.gltf")

	for !win.should_close {
		window.poll_events(&win)
		window.update(&input)
		ren.test_uni.pos = {input.relative_mouse_pos.x, input.relative_mouse_pos.y, 0.0, 0.0}
		renderer.draw_frame(&ren, &win)
	}
}
