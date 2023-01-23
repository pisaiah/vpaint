module main

import iui as ui

fn (mut app App) show_size_modal() {
	mut modal := ui.modal(app.win, 'Set Brush Size')

	modal.in_width = 245
	modal.in_height = 210

	mut width_box := ui.numeric_field(app.brush_size)

	mut width_lbl := ui.label(app.win, 'Tool/Brush Size (px)')

	width_lbl.set_bounds(50, 34, 150, 22)
	width_box.set_bounds(20, 64, 200, 40)

	modal.add_child(width_lbl)
	modal.add_child(width_box)

	width_box.set_id(mut app.win, 'bs_size')

	modal.needs_init = false
	bs_create_close_btn(mut modal)

	app.win.add_child(modal)
	app.canvas.is_mouse_down = false
}

pub fn bs_create_close_btn(mut this ui.Modal) &ui.Button {
	mut close := ui.button(
		text: 'OK'
	)

	y := this.in_height - 50
	close.set_bounds(12, y, 120, 35)

	close.set_click(fn (mut win ui.Window, btn ui.Button) {
		win.components = win.components.filter(mut it !is ui.Modal)
		mut width_lbl := &ui.TextField(win.get_from_id('bs_size'))
		mut app := &App(win.id_map['app'])

		app.brush_size = width_lbl.text.int()
	})

	mut cancel := ui.button(
		text: 'Cancel'
		bounds: ui.Bounds{138, y, 90, 35}
	)

	cancel.set_click(fn (mut win ui.Window, btn ui.Button) {
		win.components = win.components.filter(mut it !is ui.Modal)
	})
	this.add_child(cancel)

	this.children << close
	this.close = close
	return close
}
