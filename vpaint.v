module main

import vpng
import os
import gg
import iui as ui
import gx

// Our storage
struct KA {
pub mut:
	window    &ui.Window = 0
	width     int
	height    int
	file      vpng.PngFile
	ggim      int
	strr      int
	iid       int
	draw_size int = 1
	color     gx.Color
	off_color gx.Color = gx.gray
	brush     Brush    = PencilBrush{}
	lx        int
	ly        int
	cl        int
}

pub fn get_pixel(x int, y int, mut this vpng.PngFile) vpng.Pixel {
	ind := y * this.width + x
	if ind > this.pixels.len {
		return vpng.TrueColorAlpha{0, 0, 0, 0}
	}
	return this.pixels[ind]
}

[console]
fn main() {
	mut path := os.resource_abs_path('test.png')
	mut win := ui.window(ui.get_system_theme(), 'vPaint', 800, 550)

	if os.args.len > 1 {
		// Open file
		path = os.args[1]
		win.extra_map['save_path'] = path
	}

	mut png_file := vpng.read(path) or { panic(err) }
	win.bar = ui.menubar(win, win.theme)

	mut storage := &KA{
		window: win
		file: png_file
		width: png_file.width
		height: png_file.height
		ggim: -1
	}
	win.id_map['pixels'] = storage
	win.extra_map['zoom'] = '1'

	mut file := ui.menuitem('File')

	mut save_btn := ui.menuitem('Save...')
	save_btn.set_click(save_as_click)
	file.add_child(save_btn)

	mut save_as := ui.menuitem('Save As...')
	save_as.set_click(save_as_click)
	file.add_child(save_as)

	win.bar.add_child(file)

	mut help := ui.menuitem('Help')
	mut about := ui.menuitem('About iUI')
	mut about_this := ui.menuitem('About vPaint')
	about_this.set_click(about_click)

	make_zoom_menu(mut win)
	make_brush_menu(mut win)
	make_draw_size_menu(mut win)

	mut theme_menu := ui.menuitem('Theme')
	mut themes := [ui.theme_default(), ui.theme_dark()]
	for theme2 in themes {
		mut item := ui.menuitem(theme2.name)
		item.set_click(theme_click)
		theme_menu.add_child(item)
	}

	win.bar.add_child(theme_menu)
	help.add_child(about_this)
	help.add_child(about)
	win.bar.add_child(help)

	make_toolbar(mut win)

	mut lbl := ui.label(win, '')
	lbl.set_pos(10, 40 + 40)
	lbl.pack()
	lbl.set_id(mut win, 'canvas')
	lbl.draw_event_fn = fn (mut win ui.Window, com &ui.Component) {
		draw_image(mut win, com)
	}

	win.add_child(lbl)
	make_status_bar(mut win)
	make_sliders(mut win)

	win.gg.run()
}

fn make_sliders(mut win ui.Window) {
	mut y_slide := ui.slider(win, 0, 0, .vert)
	y_slide.set_bounds(0, 70, 18, 100)
	y_slide.set_id(mut win, 'y_slide')
	y_slide.draw_event_fn = fn (mut win ui.Window, com &ui.Component) {
		if mut com is ui.Slider {
			mut canvas := &ui.Label(win.get_from_id('canvas'))
			com.max = canvas.height

			size := gg.window_size()
			com.hide = canvas.height < (size.height - 50)

			com.x = size.width - com.width
			com.height = size.height - 30 - 65
		}
	}
	y_slide.z_index = 15
	win.add_child(y_slide)

	mut x_slide := ui.slider(win, 0, 0, .hor)
	x_slide.set_bounds(0, 26, 0, 18)
	x_slide.set_id(mut win, 'x_slide')
	x_slide.draw_event_fn = fn (mut win ui.Window, com &ui.Component) {
		if mut com is ui.Slider {
			mut canvas := &ui.Label(win.get_from_id('canvas'))
			com.max = canvas.width

			size := gg.window_size()
			com.hide = canvas.width < (size.width - 50)

			com.y = size.height - com.height - 25
			com.width = size.width - 18
		}
	}
	x_slide.z_index = 15
	win.add_child(x_slide)
}

fn about_click(mut win ui.Window, com ui.MenuItem) {
	mut about := ui.modal(win, 'About vPaint')
	about.in_height = 250

	mut title := ui.label(win, 'vPaint ')
	title.set_pos(120, 20)
	title.set_config(16, false, true)
	title.pack()
	about.add_child(title)

	mut lbl := ui.label(win,
		'Simple Image Viewer & Editor written\nin the V Programming Language.' +
		'\n\nThis program is free software licensed under\nthe GNU General Public License v2')
	lbl.set_pos(120, 70)
	about.add_child(lbl)

	mut copy := ui.label(win, 'Copyright © 2021-2022 Isaiah. All Rights Reserved')
	copy.set_pos(120, 185)
	copy.set_config(12, true, false)
	about.add_child(copy)

	win.add_child(about)
}

fn save_as_click(mut win ui.Window, com ui.MenuItem) {
	mut modal := ui.modal(win, 'Save As')

	mut l1 := ui.label(win, 'File path:')
	l1.pack()
	l1.set_pos(30, 70)
	modal.add_child(l1)

	mut path := ui.textbox(win, '')
	path.set_id(mut win, 'save-as-path')
	path.set_bounds(140, 70, 300, 25)
	path.multiline = false

	if 'save_path' in win.extra_map {
		path.text = win.extra_map['save_path']
	}
	modal.add_child(path)

	mut l2 := ui.label(win, 'Save as type: ')
	l2.pack()
	l2.set_pos(30, 100)
	modal.add_child(l2)

	mut typeb := ui.selector(win, 'PNG (*.png)')
	typeb.items << 'PNG (*.png)'
	typeb.set_bounds(140, 100, 300, 25)
	modal.add_child(typeb)

	modal.needs_init = false

	mut save := ui.button(win, 'Save')
	save.set_bounds(150, 250, 100, 25)
	save.set_click(fn (mut win ui.Window, btn ui.Button) {
		mut path := &ui.Textbox(win.get_from_id('save-as-path'))
		canvas := &KA(win.id_map['pixels'])
		file := canvas.file

		win.extra_map['save_path'] = path.text
		file.write(path.text)

		win.components = win.components.filter(mut it !is ui.Modal)
	})
	modal.add_child(save)

	win.add_child(modal)
}
