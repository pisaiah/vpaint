module main

import vpng
import os
import gg
import iui as ui
import gx

// Our storage
struct KA {
pub mut:
	width     int
	height    int
	file      vpng.PngFile
	ggim      int
	strr      int
	iid       int
	draw_size int   = 1
	brush     Brush = PencilBrush{}
}

[console]
fn main() {
	mut png_file := vpng.read(os.resource_abs_path('test.png')) or { panic(err) }
	mut win := ui.window(ui.get_system_theme(), 'vPaint', 800, 550)

	win.bar = ui.menubar(win, win.theme)
	mut storage := &KA{
		file: png_file
		width: png_file.width
		height: png_file.height
		ggim: -1
	}
	win.id_map['pixels'] = storage
	win.extra_map['zoom'] = '1'

	mut file := ui.menuitem('File')

	mut save_as := ui.menuitem('Save As...')
	save_as.set_click(save_as_click)
	file.add_child(save_as)

	win.bar.add_child(file)

	mut help := ui.menuitem('Help')
	mut about := ui.menuitem('About iUI')
	mut about_this := ui.menuitem('About vPaint')
	about_this.set_click(about_click)

	// Zoom menu
	mut mz := ui.menuitem('Zoom')

	mut zoomm := ui.menuitem('Decrease (-)')
	zoomm.set_click(fn (mut win ui.Window, com ui.MenuItem) {
		zoom := win.extra_map['zoom'].f32()
		win.extra_map['zoom'] = (zoom - 0.5).str()
	})
	mz.add_child(zoomm)

	mut zoomp := ui.menuitem('Increase (+)')
	zoomp.set_click(fn (mut win ui.Window, com ui.MenuItem) {
		zoom := win.extra_map['zoom'].f32()
		win.extra_map['zoom'] = (zoom + 0.5).str()
	})
	mz.add_child(zoomp)
	win.bar.add_child(mz)

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

	mut lbl := ui.label(win, '')
	lbl.set_pos(10, 40)
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
	y_slide.set_bounds(0, 26, 18, 100)
	y_slide.set_id(mut win, 'y_slide')
	y_slide.draw_event_fn = fn (mut win ui.Window, com &ui.Component) {
		if mut com is ui.Slider {
			mut canvas := &ui.Label(win.get_from_id('canvas'))
			com.max = canvas.height

			size := gg.window_size()
			com.hide = canvas.height < (size.height - 50)

			com.x = size.width - com.width
			com.height = size.height - 30 - 21
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

		file.write(path.text)

		win.components = win.components.filter(mut it !is ui.Modal)
	})
	modal.add_child(save)

	win.add_child(modal)
}

fn draw_image(mut win ui.Window, com &ui.Component) {
	mut pixels := &KA(win.id_map['pixels'])
	zoom := win.extra_map['zoom'].f32()
	mut this := *com

	mut x_slide := &ui.Slider(win.get_from_id('x_slide'))
	mut y_slide := &ui.Slider(win.get_from_id('y_slide'))

	if this.is_mouse_down && win.bar.tik > 90 {
		mut cx := int((win.mouse_x - (this.x - int(x_slide.cur))) / zoom)
		mut cy := int((win.mouse_y - (this.y - int(y_slide.cur))) / zoom)

		size := gg.window_size()
		if win.mouse_y < (size.height - 25) && cy < this.height && cx < this.width
			&& (cy * zoom) >= 0 && (cx * zoom) >= 0 {
			color := vpng.TrueColorAlpha{0, 0, 0, 255}
			dsize := pixels.draw_size
			pixels.brush.set_pixels(pixels, cx, cy, color, dsize)

			// Update canvas
			make_gg_image(mut pixels, mut win, false)
		}
	}

	this.height = int(pixels.height * zoom) + 1
	this.width = int(pixels.width * zoom) + 1

	if pixels.ggim == -1 {
		make_gg_image(mut pixels, mut win, true)
	}

	// Draw Image
	config := gg.DrawImageConfig{
		img_id: pixels.ggim
		img_rect: gg.Rect{
			x: this.x - int(x_slide.cur)
			y: this.y - int(y_slide.cur)
			width: this.width
			height: this.height
		}
	}
	mut gg := win.gg
	gg.draw_image_with_config(config)

	// Draw canvas border
	gg.draw_rect_empty(this.x - int(x_slide.cur), this.y - int(y_slide.cur), this.width + 1,
		this.height + 1, gx.rgb(215, 215, 215))

	// Draw brush hint
	cx := int((win.mouse_x - this.x) / zoom)
	cy := int((win.mouse_y - this.y) / zoom)

	dsize := pixels.draw_size
	pixels.brush.draw_hint(win, this.x, this.y, cx, cy, gx.blue, dsize)

	// Draw box-shadow
	draw_box_shadow(this, y_slide, x_slide, gg)
}

//
// Draw box shadow around image canvas
//
fn draw_box_shadow(this ui.Component, y_slide &ui.Slider, x_slide &ui.Slider, gg gg.Context) {
	mut shadows := [gx.rgb(171, 183, 203), gx.rgb(176, 188, 207),
		gx.rgb(182, 193, 212), gx.rgb(187, 198, 215), gx.rgb(193, 203, 220),
		gx.rgb(198, 208, 225), gx.rgb(204, 213, 230), gx.rgb(209, 218, 234)]

	mut si := this.y + this.height + 2
	mut sx := this.x + this.width + 1
	for mut shadow in shadows {
		gg.draw_line(this.x + 10 - int(x_slide.cur), si - int(y_slide.cur), this.width + this.x + 1 - int(x_slide.cur),
			si - int(y_slide.cur), shadow)
		gg.draw_line(sx - int(x_slide.cur), this.y + 10 - int(y_slide.cur), sx - int(x_slide.cur),
			this.y + this.height + 1 - int(y_slide.cur), shadow)
		si += 1
		sx += 1
	}
}

//
// Update the canvas image
//
fn make_gg_image(mut storage KA, mut win ui.Window, first bool) {
	if first {
		storage.ggim = win.gg.new_streaming_image(storage.file.width, storage.file.height,
			4, gg.StreamingImageConfig{ pixel_format: .rgba8 })
		win.gg.set_bg_color(gx.rgb(210, 220, 240))
	}
	bytess := storage.file.get_unfiltered()
	win.gg.update_pixel_data(storage.ggim, bytess.data)
}

//
// Change Window Theme
//
fn theme_click(mut win ui.Window, com ui.MenuItem) {
	text := com.text
	mut theme := ui.theme_by_name(text)
	win.set_theme(theme)

	if text.contains('Dark') {
		win.gg.set_bg_color(gx.rgb(25, 42, 77))
	} else {
		win.gg.set_bg_color(gx.rgb(210, 220, 240))
	}
}
