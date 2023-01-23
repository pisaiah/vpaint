module main

import iui as ui

fn (mut app App) show_settings() {
	mut page := ui.page(app.win, 'Settings')
	app.win.add_child(page)
}
