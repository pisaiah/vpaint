module main

import iui as ui

fn (mut app App) show_resize_modal(cw int, ch int) {
	mut modal := ui.modal(app.win, 'Resize Canvas')

	modal.in_width = 300
	modal.in_height = 200

	mut width_box := ui.textfield(app.win, '$cw')
	mut heigh_box := ui.textfield(app.win, '$ch')

	mut width_lbl := ui.label(app.win, 'Width')
	mut heigh_lbl := ui.label(app.win, 'Height')

	width_lbl.set_bounds(25, 25, 100, 22)
	heigh_lbl.set_bounds(165, 25, 100, 22)

	width_box.set_bounds(25, 50, 100, 30)
	heigh_box.set_bounds(165, 50, 100, 30)

	modal.add_child(width_lbl)
	modal.add_child(heigh_lbl)

	modal.add_child(width_box)
	modal.add_child(heigh_box)

	width_box.set_id(mut app.win, 'resize_width')
	heigh_box.set_id(mut app.win, 'resize_heigh')

	modal.needs_init = false
	create_close_btn(mut modal, app.win)

	app.win.add_child(modal)
}

pub fn create_close_btn(mut this ui.Modal, app &ui.Window) &ui.Button {
	mut close := ui.button(app, 'OK')

	y := this.in_height - 50
	close.set_bounds(24, y, 130, 25)

	close.set_click(fn (mut win ui.Window, btn ui.Button) {
		win.components = win.components.filter(mut it !is ui.Modal)
		mut width_lbl := &ui.TextField(win.get_from_id('resize_width'))
		mut heigh_lbl := &ui.TextField(win.get_from_id('resize_heigh'))
		mut app := &App(win.id_map['app'])

		dump(width_lbl.text.int())
		app.canvas.resize(width_lbl.text.int(), heigh_lbl.text.int())
	})

	mut cancel := ui.button(app, 'Cancel')
	cancel.set_bounds(165, y, 105, 25)

	cancel.set_click(fn (mut win ui.Window, btn ui.Button) {
		win.components = win.components.filter(mut it !is ui.Modal)
	})
	this.add_child(cancel)

	ref := &close
	this.children << ref
	this.close = ref
	return ref
}
