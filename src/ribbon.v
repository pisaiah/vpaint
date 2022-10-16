module main

// import gg
import gx
import iui as ui

fn (mut app App) make_ribbon(mut ribbon ui.HBox) {
	mut color_box := ui.hbox(app.win)
	colors := [gx.rgb(0, 0, 0), gx.rgb(127, 127, 127), gx.rgb(136, 0, 21),
		gx.rgb(237, 28, 36), gx.rgb(255, 127, 39), gx.rgb(255, 242, 0),
		gx.rgb(34, 177, 76), gx.rgb(0, 162, 232), gx.rgb(63, 72, 204),
		gx.rgb(163, 73, 164), gx.rgb(255, 255, 255), gx.rgb(195, 195, 195),
		gx.rgb(185, 122, 87), gx.rgb(255, 174, 201), gx.rgb(255, 200, 15),
		gx.rgb(239, 228, 176), gx.rgb(180, 230, 30), gx.rgb(153, 217, 235),
		gx.rgb(112, 146, 190), gx.rgba(200, 190, 230, 0)]

	size := 24

	mut count := 0
	for color in colors {
		mut btn := ui.button(app.win, ' ')
		btn.set_background(color)
		btn.set_bounds(4, 4, size, size)
		btn.border_radius = 64

		if count == 0 || count == 10 {
			txt := if count == 0 { '' } else { ' ' }
			mut current_btn := ui.button(app.win, txt)
			current_btn.set_bounds(2, 8, 30, 20)
			current_btn.draw_event_fn = current_color_btn_draw
			btn.set_bounds(20, 4, size, size)
			if count == 10 {
				current_btn.set_bounds(2, 4, 30, 20)
			}
			color_box.add_child(current_btn)
		}

		btn.set_click_fn(cbc, color)
		color_box.add_child(btn)
		count += 1
	}

	// color_box.pack()
	color_box.set_bounds(20, 1, (size + 6) * 11, 64)
	ribbon.add_child(color_box)
}

fn current_color_btn_draw(win &ui.Window, mut com ui.Component) {
	if mut com is ui.Button {
		mut app := &App(win.id_map['app'])
		bg := if com.text == '' { app.color } else { app.color_2 }
		com.set_background(bg)
		sele := (com.text == ' ' && app.sele_color) || (com.text == '' && !app.sele_color)
		if sele {
			o := 4
			width := com.width + (o * 2)
			heigh := com.height + o
			win.gg.draw_rounded_rect_empty(com.rx - o, com.ry - (o / 2), width, heigh,
				4, win.theme.text_color)
		} else if com.is_mouse_rele {
			app.sele_color = !app.sele_color
		}
	}
}

fn cbc(a voidptr, b voidptr, c voidptr) {
	btn := &ui.Button(b)
	color := btn.override_bg_color
	mut win := &ui.Window(a)
	mut app := &App(win.id_map['app'])
	app.set_color(color)
}

fn ribbon_draw_fn(win &ui.Window, mut com ui.Component) {
	ws := win.gg.window_size()
	ui.set_bounds(mut com, 0, 26, ws.width, 64)
	color := win.theme.menubar_background
	win.gg.draw_rect_filled(0, 26, com.width, com.height, color)
}
