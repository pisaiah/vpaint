module main

import iui as ui
import stbi
import os

fn (app &App) save() {
	mut this := app.data

	if this.file_name.ends_with('jpg') {
		app.write_jpg(this.file, this.file_name)
	} else {
		app.write_img(this.file, this.file_name)
	}

	file_size := format_size(os.file_size(this.file_name))
	this.file_size = file_size
	emsave(this.file_name)
}

fn responsive_field(mut e ui.DrawEvent) {
	padding := 20
	tw := e.ctx.text_width(e.target.text) + padding

	ws := e.ctx.gg.window_size().width
	inw := if ws < 500 { ws } else { 500 }
	min := inw / 3
	e.target.width = if tw > min { tw } else { min }
}

fn responsive_modal(mut e ui.DrawEvent) {
	mut tar := e.get_target[ui.Modal]()
	ws := e.ctx.gg.window_size().width

	inw := if ws < 500 { ws } else { 500 }
	nnw := inw - 10
	if tar.in_width == nnw {
		return
	}
	tar.in_width = nnw
	tar.children[0].width = nnw - 1
	tar.children[0].height = tar.in_height
	tar.children[0].children[1].width = nnw
}

fn responsive_modal_panel(mut e ui.DrawEvent) {
}

fn (app &App) save_as() {
	mut data := app.data

	mut modal := ui.Modal.new(
		title: 'Save As..'
	)

	modal.subscribe_event('draw', responsive_modal)

	modal.top_off = 5
	modal.in_height = 280
	w := modal.in_width - 10

	mut p := ui.Panel.new(
		layout: ui.BoxLayout.new(
			ori: 1
		)
	)
	// p.set_bounds(4, 0, w, modal.in_height)

	folder := os.dir(data.file_name)
	file_name := os.file_name(data.file_name)

	mut f := ui.TextField.new(
		text: folder
	)
	f.set_bounds(0, 0, w / 2, 30)
	f.subscribe_event('draw', responsive_field)

	mut cb := ui.Selectbox.new(
		text:  os.file_ext(file_name)[1..].to_upper()
		items: ['PNG', 'JPG', 'BMP', 'TGA']
	)

	mut nam := ui.TextField.new(
		text: file_name
	)

	cb.set_bounds(0, 0, 140, 30)
	cb.subscribe_event('item_change', fn [mut nam] (mut e ui.ItemChangeEvent) {
		txt := e.target.text
		if !nam.text.ends_with(txt) {
			old_type := os.file_ext(nam.text)
			nam.text = nam.text.replace(old_type, '.' + txt.to_lower())
		}
	})

	mut tb_f := ui.SettingsCard.new(text: 'Save Folder', description: 'The Directory to save in')
	tb_f.stretch = true
	tb_f.add_child(f)

	nam.set_bounds(0, 0, w - 210, 30)

	mut tb_fn := ui.Titlebox.new(
		text:     'File Name'
		children: [nam]
	)

	mut tb_cb := ui.Titlebox.new(
		text:     'Save as Type'
		children: [cb]
	)

	mut p2 := ui.Panel.new(layout: ui.FlowLayout.new())
	p2.subscribe_event('draw', responsive_modal_panel)

	p2.set_bounds(0, 0, w, 170)
	p2.add_child(tb_fn)
	p2.add_child(tb_cb)

	p.add_child(tb_f)
	p.add_child(p2)
	modal.add_child(p)

	modal.needs_init = false

	mut close := ui.Button.new(text: 'Save')
	modal.add_child(close)

	close.subscribe_event('mouse_up', fn [app, mut data, mut f, mut nam] (mut e ui.MouseEvent) {
		full_path := os.join_path(f.text, nam.text)
		typ := os.file_ext(full_path).to_lower()

		ui.default_modal_close_fn(mut e)

		mut good := false
		if typ == '.png' {
			good = app.write_img(data.file, full_path)
		}
		if typ == '.jpg' {
			good = app.write_jpg(data.file, full_path)
		}
		if typ == '.bmp' {
			good = app.write_bmp(data.file, full_path)
		}
		if typ == '.tga' {
			good = app.write_tga(data.file, full_path)
		}
		if typ == '.svg' {
			// TOOD
		}
		if good {
			data.file_name = full_path
			file_size := format_size(os.file_size(full_path))
			data.file_size = file_size
			emsave(data.file_name)
		}
	})

	mut can := modal.make_close_btn(true)
	can.text = 'Cancel'

	y := modal.in_height - 40 // 250
	close.set_bounds(w - 280, y, 135, 30)
	can.set_bounds(w - 140, y, 80, 30)

	app.win.add_child(modal)
}

fn word_wrap_a(txt string, max int) string {
	mut words := txt.split(' ')
	mut line_len := 0
	mut output := ''

	for word in words {
		if line_len + word.len > max {
			output += '\n${word} '
			line_len = word.len + 1
		} else {
			output += '${word} '
			line_len += word.len + 1
		}
	}
	return output
}

fn (app &App) show_error(title string, msg IError) {
	mut modal := ui.Modal.new(
		title: title
	)
	modal.top_off = 20
	modal.in_height = 110
	text := msg.msg()
	mut txt := ui.Label.new(
		text: 'Error Code: ${msg.code()}; Message:\n${text}'
	)
	txt.set_pos(8, 8)
	txt.pack()
	modal.add_child(txt)
	app.win.add_child(modal)
}

// Write as PNG
pub fn (app &App) write_img(img stbi.Image, path string) bool {
	stbi.stbi_write_png(path, img.width, img.height, 4, img.data, img.width * 4) or {
		app.show_error('stbi_image save error', err)
		return false
	}
	return true
}

// Write as JPG
pub fn (app &App) write_jpg(img stbi.Image, path string) bool {
	stbi.stbi_write_jpg(path, img.width, img.height, 4, img.data, 80) or {
		app.show_error('stbi_image save error', err)
		return false
	}
	return true
}

// Write as Bitmap
pub fn (app &App) write_bmp(img stbi.Image, path string) bool {
	stbi.stbi_write_bmp(path, img.width, img.height, 4, img.data) or {
		app.show_error('stbi_image save error', err)
		return false
	}
	return true
}

// Write as TGA
pub fn (app &App) write_tga(img stbi.Image, path string) bool {
	stbi.stbi_write_tga(path, img.width, img.height, 4, img.data) or {
		app.show_error('stbi_image save error', err)
		return false
	}
	return true
}
