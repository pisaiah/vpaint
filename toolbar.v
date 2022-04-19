module main

import iui as ui
import gg
import gx
import os

struct Toolbar {
	ui.Component_A
pub mut:
	kids []ui.Component
}

// Toolbar - Shape Select
fn (mut this Toolbar) draw_shapes(mut win ui.Window, sw int) {
	// Colors (taken from MSPaint)
	mut shapes := [Brush(RectShape{}), Brush(SquareShape{}), Brush(LineShape{})]

	mut sx := 410

	mut x := this.x + (sw - sx)
	mut y := this.y

	// Shape Click
	if this.is_mouse_rele {
		mx := win.mouse_x
		my := win.mouse_y

		if mx > x && mx < sw && my < (this.y + 44) {
			mut indx := 0

			indx = (mx - x) / 24
			if my > (this.y + 21) {
				indx += 5
			}

			mut storage := &KA(win.id_map['pixels'])
			if indx < shapes.len && indx >= 0 {
				storage.brush = shapes[indx]
			}

			this.is_mouse_rele = false
		}
	}

	win.draw_bordered_rect(x, y, 24 * shapes.len, 42, 4, win.theme.textbox_background,
		gx.rgb(160, 160, 160))

	// Draw Shape
	mut index := 0
	for shape in shapes {
		// win.draw_bordered_rect(x, y, 22, 20, 4, gx.white, gx.rgb(160, 160, 160))
		if shape is RectShape {
			win.gg.draw_rect_empty(x + 4, y + 5, 15, 11, win.theme.text_color)
		}
		if shape is SquareShape {
			win.gg.draw_rect_empty(x + 4, y + 4, 14, 14, win.theme.text_color)
		}
		if shape is LineShape {
			win.gg.draw_line(x + 4, y + 4, x + 17, y + 17, win.theme.text_color)
		}

		x += 24

		index += 1
		if index >= 5 {
			x = this.x + (sw - sx)
			y += 22
			index = 0
		}
	}

	// TODO end of draw
	this.is_mouse_rele = false
}

// Toolbar - Color Select
fn (mut this Toolbar) draw_colors(mut win ui.Window, sw int) {
	// Colors (taken from MSPaint)
	colors := [gx.rgb(0, 0, 0), gx.rgb(127, 127, 127), gx.rgb(136, 0, 21),
		gx.rgb(237, 28, 36), gx.rgb(255, 127, 39), gx.rgb(255, 242, 0),
		gx.rgb(34, 177, 76), gx.rgb(0, 162, 232), gx.rgb(63, 72, 204),
		gx.rgb(163, 73, 164), gx.rgb(255, 255, 255), gx.rgb(195, 195, 195),
		gx.rgb(185, 122, 87), gx.rgb(255, 174, 201), gx.rgb(255, 200, 15),
		gx.rgb(239, 228, 176), gx.rgb(180, 230, 30), gx.rgb(153, 217, 235),
		gx.rgb(112, 146, 190), gx.rgba(200, 190, 230, 0)]

	mut sx := 250

	mut x := this.x + (sw - 320)
	mut y := this.y

	// Draw Primary Color
	win.draw_filled_rect(x, y + 2, 30, 40, 0, gx.white, win.theme.button_border_hover)
	mut canvas := &KA(win.id_map['pixels'])
	win.gg.draw_rect_filled(x + 1, y + 3, 27, 20, canvas.color)
	win.gg.draw_text_def(x, y + 24, '1')

	x += 34

	// Draw 2nt Color
	win.draw_filled_rect(x, y + 2, 30, 40, 0, gx.white, gx.rgb(160, 160, 160))
	win.gg.draw_rect_filled(x + 1, y + 3, 27, 20, canvas.off_color)
	win.gg.draw_text_def(x, y + 24, '2')

	x = this.x + (sw - sx)

	// Color Click
	if this.is_mouse_rele {
		mx := win.mouse_x
		my := win.mouse_y

		if mx > (this.x + (sw - 320)) && mx < x {
			off_color := canvas.off_color
			canvas.off_color = canvas.color
			canvas.color = off_color
			this.is_mouse_rele = false
		}

		if mx > x && mx < sw && my < (this.y + 44) {
			mut indx := 0

			indx = (mx - x) / 25
			if my > (this.y + 21) {
				indx += 10
			}
			canvas.color = colors[indx]

			this.is_mouse_rele = false
		}
	}

	// Draw Color
	mut index := 0
	for color in colors {
		win.draw_bordered_rect(x, y, 22, 20, 4, gx.white, gx.rgb(160, 160, 160))
		win.gg.draw_rect_filled(x + 3, y + 2, 16, 16, color)
		x += 25

		index += 1
		if index >= 10 {
			x = this.x + (sw - sx)
			y += 22
			index = 0
		}
	}
}

fn create_img_button(mut win ui.Window, path string, x int, y int, w int, h int) &ui.Image {
	img_data := os.read_bytes(os.resource_abs_path('resources/' + path)) or { [u8(0)] }
	mut pen_btn := ui.image_from_byte_array_with_size(mut win, img_data, 32, 32)
	pen_btn.z_index = 8

	if x != 0 {
		pen_btn.set_bounds(x, y, w, h)
	}
	return pen_btn
}

fn create_img_button_(mut win ui.Window, img_data []u8, x int, y int, w int, h int) &ui.Image {
	mut pen_btn := ui.image_from_byte_array_with_size(mut win, img_data, 32, 32)
	pen_btn.z_index = 8

	if x != 0 {
		pen_btn.set_bounds(x, y, w, h)
	}
	return pen_btn
}

fn setup_brush_choices(mut win ui.Window) {
	mut hbox := ui.hbox(win)
	hbox.set_bounds(16, 32, 40 * 3, 23)
	hbox.z_index = 7

	embed_pencil := $embed_file('resources/icons8-pencil-drawing-48.png')
	embed_pen := $embed_file('resources/icons8-pen-48.png')
	embed_spray := $embed_file('resources/icons8-paint-sprayer-48.png')

	mut pencil_btn := create_img_button_(mut win, embed_pencil.to_bytes(), 0, 0, 0, 0)
	pencil_btn.draw_event_fn = fn (mut win ui.Window, com &ui.Component) {
		if com.is_mouse_rele {
			mut this := *com
			mut pixels := &KA(win.id_map['pixels'])
			if mut this is ui.Image {
				if this.app.bar.tik > 90 {
					pixels.brush = PencilBrush{}
				}
			}
			this.is_mouse_rele = false
		}
	}
	hbox.add_child(pencil_btn)

	mut pen_btn := create_img_button_(mut win, embed_pen.to_bytes(), 0, 0, 0, 0)
	pen_btn.draw_event_fn = fn (mut win ui.Window, com &ui.Component) {
		if com.is_mouse_rele {
			mut this := *com
			mut pixels := &KA(win.id_map['pixels'])
			pixels.brush = CalligraphyBrush{}
			this.is_mouse_rele = false
		}
	}
	hbox.add_child(pen_btn)

	mut spray_btn := create_img_button_(mut win, embed_spray.to_bytes(), 0, 0, 0, 0)
	spray_btn.draw_event_fn = fn (mut win ui.Window, com &ui.Component) {
		if com.is_mouse_rele {
			mut this := *com
			mut pixels := &KA(win.id_map['pixels'])
			pixels.brush = SpraycanBrush{}
			this.is_mouse_rele = false
		}
	}
	hbox.add_child(spray_btn)
	win.add_child(hbox)
}

// Toolbar - Make Toolbar
fn make_toolbar(mut win ui.Window) {
	mut toolbar := &Toolbar{}
	toolbar.z_index = 5
	toolbar.set_pos(0, 25)

	/*
	mut sel_btn := ui.button(win, 'Select')
	sel_btn.z_index = 6
	sel_btn.set_bounds(10, 26, 70, 40)
	sel_btn.click_event_fn = fn (mut win ui.Window, com ui.Button) {
		mut pixels := &KA(win.id_map['pixels'])
		pixels.brush = SelectionTool{}
	}
	win.add_child(sel_btn)*/

	setup_brush_choices(mut win)

	embed_picker := $embed_file('resources/icons8-color-wheel-2-48.png')
	mut picker_btn := create_img_button_(mut win, embed_picker.to_bytes(), 1, 22, 48,
		48)
	picker_btn.set_id(mut win, 'picker_btn')
	picker_btn.draw_event_fn = fn (mut win ui.Window, com &ui.Component) {
		if com.is_mouse_rele {
			mut this := *com
			show_rgb_picker(mut win)
			this.is_mouse_rele = false
		}
	}
	win.add_child(picker_btn)

	toolbar.draw_event_fn = fn (mut win ui.Window, comm &ui.Component) {
		mut com := *comm
		if mut com is Toolbar {
			mut picker_btn := &ui.Image(win.get_from_id('picker_btn'))
			size := gg.window_size()

			picker_btn.x = size.width - picker_btn.width

			com.x = 0
			com.y = 25
			com.width = size.width
			com.height = 45
			win.gg.draw_rect_filled(com.x, com.y, com.width, com.height, win.theme.background)
			win.gg.draw_line(com.x, com.y + com.height, size.width, com.y + com.height,
				gx.rgb(200, 200, 200))

			com.draw_colors(mut win, picker_btn.x)
			com.draw_shapes(mut win, picker_btn.x)
		}
	}

	win.add_child(toolbar)
}
