module main

import iui as ui

fn (mut app App) show_settings() {
	mut page := ui.Page.new(title: 'Settings')
	app.win.add_child(page)
}
