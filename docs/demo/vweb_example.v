module main

import vweb
import rand
import os

const (
	port = 8080
)

struct App {
	vweb.Context
mut:
	state shared State
}

struct State {
mut:
	cnt int
}

fn main() {
	mut app := &App{}
	app.mount_static_folder_at(os.resource_abs_path('.'), '/')
	vweb.run_at(app, vweb.RunParams{ host: '192.168.2.23' port: 8080 family: .ip }) or {
		panic(err)
	}
}

pub fn (mut app App) index() vweb.Result {
	lock app.state {
		app.state.cnt++
	}
	
	app.handle_static('assets', true)

	return app.file(os.resource_abs_path('index.html'))
}

['/app.wasm']
pub fn (mut app App) was() vweb.Result {
	return app.file(os.resource_abs_path('app.wasm'))
}