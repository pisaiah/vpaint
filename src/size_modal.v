module main

import iui as ui

fn (mut app App) show_size_modal() {
	mut modal := ui.Modal.new(title: 'Set Brush Size')

	modal.in_width = 245
	modal.in_height = 210

	mut width_box := ui.numeric_field(app.brush_size)

	mut width_lbl := ui.Label.new(text: 'Tool/Brush Size (px)')

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

	close.subscribe_event('mouse_up', close_modal)

	mut cancel := ui.button(
		text:   'Cancel'
		bounds: ui.Bounds{138, y, 90, 35}
	)

	cancel.subscribe_event('mouse_up', end_modal)

	this.add_child(cancel)

	this.children << close
	this.close = close
	return close
}

fn close_modal(mut e ui.MouseEvent) {
	mut win := e.ctx.win
	win.components = win.components.filter(mut it !is ui.Modal)
	mut width_lbl := win.get[&ui.TextField]('bs_size')
	mut app := win.get[&App]('app')

	app.brush_size = width_lbl.text.int()
}

fn end_modal(mut e ui.MouseEvent) {
	mut win := e.ctx.win
	win.components = win.components.filter(mut it !is ui.Modal)
}
