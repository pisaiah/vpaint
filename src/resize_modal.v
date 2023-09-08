module main

import iui as ui

fn (mut app App) show_resize_modal(cw int, ch int) {
	mut modal := ui.Modal.new(title: 'Resize Canvas')

	modal.in_width = 300
	modal.in_height = 200

	mut width_box := ui.text_field(text: '${cw}')
	mut heigh_box := ui.text_field(text: '${ch}')

	mut width_lbl := ui.Label.new(text: 'Width')
	mut heigh_lbl := ui.Label.new(text: 'Height')

	mut p := ui.Panel.new(
		layout: ui.GridLayout.new(rows: 2)
	)
	p.set_bounds(25, 25, 250, 80)

	p.add_child(width_lbl)
	p.add_child(heigh_lbl)
	p.add_child(width_box)
	p.add_child(heigh_box)
	modal.add_child(p)

	width_box.set_id(mut app.win, 'resize_width')
	heigh_box.set_id(mut app.win, 'resize_heigh')

	modal.needs_init = false
	create_close_btn(mut modal, app.win)

	app.win.add_child(modal)
}

pub fn create_close_btn(mut this ui.Modal, app &ui.Window) &ui.Button {
	mut close := ui.button(text: 'OK')
	mut cancel := ui.button(text: 'Cancel')

	y := this.in_height - 45
	close.set_bounds(24, y, 130, 30)
	cancel.set_bounds(165, y, 105, 30)

	close.subscribe_event('mouse_up', resize_close_click)
	cancel.subscribe_event('mouse_up', end_modal)

	this.add_child(cancel)

	this.children << close
	this.close = close
	return close
}

fn resize_close_click(mut e ui.MouseEvent) {
	e.ctx.win.components = e.ctx.win.components.filter(mut it !is ui.Modal)
	mut width_lbl := e.ctx.win.get[&ui.TextField]('resize_width')
	mut heigh_lbl := e.ctx.win.get[&ui.TextField]('resize_heigh')
	mut app := e.ctx.win.get[&App]('app')

	app.canvas.resize(width_lbl.text.int(), heigh_lbl.text.int())
}
