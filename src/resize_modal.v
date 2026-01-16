module main

import iui as ui
import os

// Resize Modal
fn (mut app App) show_resize_modal(cw int, ch int) {
	mut modal := ui.Modal.new(
		title:  'Resize Canvas'
		width:  300
		height: 200
	)

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
	mut close := ui.Button.new(
		text:     'OK'
		on_click: resize_close_click
	)
	mut cancel := ui.Button.new(
		text:     'Cancel'
		on_click: end_modal
	)

	y := this.in_height - 45
	close.set_accent_filled(true)
	close.set_bounds(24, y, 130, 30)
	cancel.set_bounds(165, y, 105, 30)

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

// Custom Pencil Button
fn (mut app App) show_custom_pencil_modal() {
	mut modal := ui.Modal.new(title: 'Custom Pencil Tool')

	modal.in_width = 300
	modal.in_height = 200

	mut tool := app.tool

	mut width_box := ui.text_field(text: '0')
	mut heigh_box := ui.text_field(text: '0')

	if mut tool is CustomPencilTool {
		width_box.text = '${tool.width}'
		heigh_box.text = '${tool.height}'
	}

	mut width_lbl := ui.Label.new(text: 'Width')
	mut heigh_lbl := ui.Label.new(text: 'Height')

	mut p := ui.Panel.new(
		layout: ui.GridLayout.new(rows: 3)
	)
	p.set_bounds(25, 25, 250, 80)

	mut info := ui.Label.new(text: 'Override Size (0 = No Override, use tool size)')
	p.add_child(info)

	mut lbl2 := ui.Label.new()
	p.add_child(lbl2)

	p.add_child(width_lbl)
	p.add_child(heigh_lbl)
	p.add_child(width_box)
	p.add_child(heigh_box)
	modal.add_child(p)

	width_box.set_id(mut app.win, 'over_width')
	heigh_box.set_id(mut app.win, 'over_heigh')

	modal.needs_init = false
	create_close_btn_2(mut modal, app.win)

	app.win.add_child(modal)
}

pub fn create_close_btn_2(mut this ui.Modal, app &ui.Window) &ui.Button {
	mut close := ui.Button.new(text: 'OK')
	mut cancel := ui.Button.new(text: 'Cancel')

	y := this.in_height - 45
	close.set_bounds(24, y, 130, 30)
	cancel.set_bounds(165, y, 105, 30)

	close.subscribe_event('mouse_up', customp_close_click)
	cancel.subscribe_event('mouse_up', end_modal)

	this.add_child(cancel)

	this.children << close
	this.close = close
	return close
}

fn customp_close_click(mut e ui.MouseEvent) {
	e.ctx.win.components = e.ctx.win.components.filter(mut it !is ui.Modal)
	mut width_lbl := e.ctx.win.get[&ui.TextField]('over_width')
	mut heigh_lbl := e.ctx.win.get[&ui.TextField]('over_heigh')

	mut app := e.ctx.win.get[&App]('app')
	mut tool := app.tool

	if mut tool is CustomPencilTool {
		tool.width = width_lbl.text.int()
		tool.height = heigh_lbl.text.int()
	}
}

fn (mut app App) show_size_modal() {
	mut modal := ui.Modal.new(
		title:  'Set Brush Size'
		width:  245
		height: 210
	)

	mut width_box := ui.numeric_field(app.brush_size)

	mut width_lbl := ui.Label.new(
		text: 'Tool/Brush Size (px)'
		pack: true
	)

	width_lbl.set_pos(60, 34)
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
	y := this.in_height - 50

	mut close := ui.Button.new(
		text:   'OK'
		bounds: ui.Bounds{12, y, 120, 35}
	)

	mut cancel := ui.Button.new(
		text:   'Cancel'
		bounds: ui.Bounds{138, y, 90, 35}
	)

	close.set_accent_filled(true)
	close.subscribe_event('mouse_up', close_modal)
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

// Prop Modal
fn (mut app App) show_prop_modal(g &ui.GraphicsContext) {
	mut modal := ui.Modal.new(
		title:  'Image Properties'
		width:  250
		height: 250
	)

	txt := [
		'Image Size:: ${app.canvas.w} x ${app.canvas.h} px',
		'Zoom:: ${app.canvas.zoom}x',
		'Megapixel:: ${f32(app.canvas.w * app.canvas.h) / 1000000} MP',
	]

	txt2 := [
		'File Size:: ${app.data.file_size}',
		'File Name:: ${os.base(app.data.file_name)}',
	]

	mut gp := ui.Panel.new(
		layout: ui.GridLayout.new(cols: 2)
	)

	for line in txt {
		for spl in line.split(': ') {
			mut lbl := ui.Label.new(
				text: spl
				pack: true
			)
			gp.add_child(lbl)
		}
	}

	mut fp := ui.Panel.new(
		layout: ui.GridLayout.new(cols: 2)
	)

	for line in txt2 {
		for spl in line.split(': ') {
			mut lbl := ui.Label.new(
				text: spl
				pack: true
			)
			fp.add_child(lbl)
		}

		w := g.text_width(line) + 40
		if modal.in_width < w {
			modal.in_width = w
		}
	}

	mut p := ui.Panel.new(
		layout: ui.BoxLayout.new(ori: 1)
	)

	p.set_pos(5, 5)
	p.add_child(gp)
	p.add_child(fp)

	modal.add_child(p)

	app.win.add_child(modal)
	app.canvas.is_mouse_down = false
}

@[heap]
struct NewModal {
	ui.Modal
mut:
	// modal &ui.Modal
	w_box &ui.TextField
	h_box &ui.TextField
	same  bool
}

// Resize Modal
fn (mut app App) show_new_modal(cw int, ch int) {
	mut width_box := ui.TextField.new(text: '${cw}')
	mut heigh_box := ui.TextField.new(text: '${ch}')

	mut width_lbl := ui.Label.new(text: 'Width')
	mut blank_lbl := ui.Label.new(text: ' ')
	mut heigh_lbl := ui.Label.new(text: 'Height')

	mut nm := &NewModal{
		text:      'New!'
		in_width:  300
		in_height: 250
		z_index:   500
		close:     unsafe { nil }
		w_box:     width_box
		h_box:     heigh_box
		same:      true
	}

	width_box.subscribe_event('text_change', nm.text_change_fn)
	heigh_box.subscribe_event('text_change', nm.text_change_fn)

	mut link := ui.Button.new(
		text:     '\ue167'
		pack:     true
		on_click: nm.button_click_fn
	)
	link.set_accent_filled(true)
	link.font = 1
	mut p := ui.Panel.new(
		layout: ui.GridLayout.new(cols: 3)
	)
	p.set_bounds(20, 20, 260, 90)

	p.add_child(width_lbl)
	p.add_child(blank_lbl)
	p.add_child(heigh_lbl)
	p.add_child(width_box)
	p.add_child(link)
	p.add_child(heigh_box)

	nm.add_child(p)

	nm.needs_init = false
	nm.new_modal_close_btn()

	nm.set_bounds(0, 0, 1280, 720)

	app.win.add_child(nm)
}

pub fn (mut nm NewModal) button_click_fn(mut e ui.MouseEvent) {
	nm.same = !nm.same

	mut tar := e.target
	if mut tar is ui.Button {
		tar.set_accent_filled(nm.same)
	}
}

pub fn (mut nm NewModal) text_change_fn(mut e ui.TextChangeEvent) {
	if nm.same {
		nm.w_box.text = e.target.text
		nm.h_box.text = e.target.text
		nm.w_box.carrot_left = e.target.text.len
		nm.h_box.carrot_left = e.target.text.len
	}
}

pub fn (mut nm NewModal) new_modal_close_btn() &ui.Button {
	mut close := ui.Button.new(text: 'OK')
	mut cancel := ui.Button.new(text: 'Cancel')

	y := nm.in_height - 45
	close.set_accent_filled(true)
	close.set_bounds(20, y, 150, 30)
	cancel.set_bounds(175, y, 105, 30)

	close.subscribe_event('mouse_up', nm.new_close_click)
	cancel.subscribe_event('mouse_up', end_modal2)

	nm.add_child(cancel)

	nm.children << close
	nm.close = close
	return close
}

fn end_modal2(mut e ui.MouseEvent) {
	mut win := e.ctx.win
	win.components = win.components.filter(mut it !is NewModal)
}

fn (mut nm NewModal) new_close_click(mut e ui.MouseEvent) {
	// TODO: prompt 'do you want to save'

	mut app := e.ctx.win.get[&App]('app')
	app.load_new(nm.w_box.text.int(), nm.h_box.text.int())

	e.ctx.win.components = e.ctx.win.components.filter(mut it !is NewModal)
}
