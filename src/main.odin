package main

import "core:fmt"
import "core:log"
import "core:mem"

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
	ren: renderer.Render_State

	init_logger(&app)
	context.logger = app.console_logger

	window.init(&win, &input)
	renderer.init(&ren, &win)
}
