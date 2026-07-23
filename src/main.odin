package main

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

	init_logger(&app)
	context.logger = app.console_logger

	renderer.g_ctx = context

	window.init(&win, &input)
	renderer.init(&ren, &win)

	for !win.should_close {
		window.poll_events(&win)
		renderer.draw_frame(&ren, &win)
	}
}
