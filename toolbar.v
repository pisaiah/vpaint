module main

import iui as ui
import gg
import gx

struct Toolbar {
	ui.Component_A
pub mut:
	kids []ui.Component
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

	mut x := this.x + (sw - sx)
	mut y := this.y

	// Color Click
	if this.is_mouse_rele {
		mx := win.mouse_x
		my := win.mouse_y

		if mx > x && mx < sw {
			mut indx := 0

			indx = (mx - x) / 25
			if my > (this.y + 21) {
				indx += 10
			}
			mut canvas := &KA(win.id_map['pixels'])
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

// Toolbar - Make Toolbar
fn make_toolbar(mut win ui.Window) {
	mut toolbar := &Toolbar{}
	toolbar.z_index = 5
	toolbar.set_pos(0, 25)

	mut picker_btn := ui.button(win, 'Picker')
	picker_btn.z_index = 6
	picker_btn.set_id(mut win, 'picker_btn')
	picker_btn.set_bounds(0, 26, 70, 40)
	picker_btn.click_event_fn = fn (mut win ui.Window, com ui.Button) {
		show_rgb_picker(mut win)
	}
	win.add_child(picker_btn)

	toolbar.draw_event_fn = fn (mut win ui.Window, com &ui.Component) {
		if mut com is Toolbar {
			mut picker_btn := &ui.Button(win.get_from_id('picker_btn'))
			size := gg.window_size()

			picker_btn.x = size.width - picker_btn.width - 23

			com.x = 0
			com.y = 25
			com.width = size.width
			com.height = 45
			win.gg.draw_rect_filled(com.x, com.y, com.width, com.height, win.theme.menubar_background)
			win.gg.draw_line(com.x, com.y + com.height, size.width, com.y + com.height,
				gx.rgb(200, 200, 200))

			com.draw_colors(mut win, picker_btn.x)
		}
	}

	win.add_child(toolbar)
}
