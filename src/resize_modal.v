module main

import iui as ui
import os

// Resize Modal
fn (mut app App) show_resize_modal(cw int, ch int) {
	mut width_box := ui.TextField.new(text: '${cw}')
	mut heigh_box := ui.TextField.new(text: '${ch}')

	width_box.set_id(mut app.win, 'resize_width')
	heigh_box.set_id(mut app.win, 'resize_heigh')

	mut p := ui.Panel.new(
		layout:   ui.GridLayout.new(rows: 2)
		children: [
			ui.Label.new(text: 'Width'),
			ui.Label.new(text: 'Height'),
			width_box,
			heigh_box,
		]
	)
	p.set_bounds(25, 25, 250, 80)

	modal := ui.Modal.new(
		title:     'Resize Canvas'
		width:     300
		height:    200
		children:  [
			p,
			ui.Button.new(
				text:     'OK'
				on_click: resize_close_click
				accent:   true
				bounds:   ui.Bounds{24, 200 - 45, 130, 30}
			),
			ui.Button.new(
				text:     'Cancel'
				on_click: end_modal
				bounds:   ui.Bounds{165, 200 - 45, 105, 30}
			),
		]
		close_idx: 1
	)

	app.win.add_child(modal)
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
	mut width_box := ui.TextField.new(text: '0')
	mut heigh_box := ui.TextField.new(text: '0')

	width_box.set_id(mut app.win, 'over_width')
	heigh_box.set_id(mut app.win, 'over_heigh')

	mut tool := app.tool
	if mut tool is CustomPencilTool {
		width_box.text = '${tool.width}'
		heigh_box.text = '${tool.height}'
	}

	y := 200 - 45

	mut modal := ui.Modal.new(
		title:     'Custom Pencil Tool'
		width:     300
		height:    200
		children:  [
			ui.Panel.new(
				layout:   ui.GridLayout.new(hgap: 5, vgap: 5, rows: 3)
				children: [
					ui.Label.new(text: 'Override Size (0 = No Override, use tool size)'),
					ui.Label.new(),
					ui.Label.new(text: 'Width'),
					ui.Label.new(text: 'Height'),
					width_box,
					heigh_box,
				]
				width:    250
				height:   130
			),
			ui.Button.new(
				text:     'OK'
				on_click: customp_close_click
				accent:   true
				bounds:   ui.Bounds{24, y, 125, 30}
			),
			ui.Button.new(
				text:     'Cancel'
				on_click: end_modal
				bounds:   ui.Bounds{160, y, 110, 30}
			),
		]
		close_idx: 2
	)

	modal.needs_init = false
	modal.children[0].set_bounds(25, 20, 250, 105)

	app.win.add_child(modal)
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
	mut width_box := ui.numeric_field(app.brush_size)
	width_box.set_bounds(20, 64, 200, 40)
	width_box.set_id(mut app.win, 'bs_size')

	modal := ui.Modal.new(
		title:     'Set Brush Size'
		width:     245
		height:    210
		children:  [
			ui.Label.new(
				text: 'Tool/Brush Size (px)'
				pack: true
				x:    60
				y:    34
			),
			width_box,
			ui.Button.new(
				text:     'OK'
				bounds:   ui.Bounds{12, 210 - 50, 120, 35}
				accent:   true
				on_click: close_modal
			),
			ui.Button.new(
				text:     'Cancel'
				bounds:   ui.Bounds{138, 210 - 50, 90, 35}
				on_click: end_modal
			),
		]
		close_idx: 2
	)

	app.win.add_child(modal)
	app.canvas.is_mouse_down = false
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
	txt := [
		'Image Size:: ${app.canvas.w} x ${app.canvas.h} px',
		'Zoom:: ${app.canvas.zoom}x',
		'Megapixel:: ${f32(app.canvas.w * app.canvas.h) / 1000000} MP',
	]

	txt2 := [
		'File Size:: ${app.get_image_data().file_size}',
		'File Name:: ${os.base(app.get_image_data().file_name)}',
	]

	mut gp := ui.Panel.new(
		layout: ui.GridLayout.new(cols: 2)
	)

	mut fp := ui.Panel.new(
		layout: ui.GridLayout.new(cols: 2)
	)

	mut modal := ui.Modal.new(
		title:    'Image Properties'
		width:    250
		height:   250
		children: [
			ui.Panel.new(
				layout:   ui.BoxLayout.new(ori: 1)
				children: [
					gp,
					fp,
				]
			),
		]
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

	app.win.add_child(modal)
	app.canvas.is_mouse_down = false
}

@[heap]
struct NewModal {
	ui.Modal
mut:
	w_box &ui.TextField
	h_box &ui.TextField
	same  bool
}

// Resize Modal
fn (mut app App) show_new_modal(cw int, ch int) {
	mut width_box := ui.TextField.new(text: '${cw}')
	mut heigh_box := ui.TextField.new(text: '${ch}')

	mut nm := &NewModal{
		text:      'New Image'
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
		accent:   true
	)
	link.font = 1
	mut p := ui.Panel.new(
		layout:   ui.GridLayout.new(cols: 3)
		children: [
			ui.Label.new(text: 'Width'),
			ui.Label.new(text: ' '),
			ui.Label.new(text: 'Height'),
			width_box,
			link,
			heigh_box,
		]
	)
	p.set_bounds(20, 20, 260, 90)
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
	y := nm.in_height - 45

	mut close := ui.Button.new(
		text:     'OK'
		accent:   true
		on_click: nm.new_close_click
		bounds:   ui.Bounds{20, y, 150, 30}
	)

	mut cancel := ui.Button.new(
		text:     'Cancel'
		on_click: end_modal2
		bounds:   ui.Bounds{175, y, 105, 30}
	)

	nm.add_child(cancel)
	nm.add_child(close)
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
