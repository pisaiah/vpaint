module main

import iui as ui
import gg

fn statusbar_draw_event(win &ui.Window, com &ui.Component) { //(mut app App)
	mut app := &App(win.id_map['app'])
	ws := win.gg.window_size()
	mut sb := app.status_bar
	sb.width = ws.width + 50
	sb.height = 31
	sb.y = ws.height - 30

	win.gg.draw_rect_filled(sb.x, sb.y, sb.width, sb.height, win.theme.menubar_background)
	win.gg.draw_rect_empty(sb.x, sb.y, sb.width, 1, win.theme.dropdown_border)
	win.gg.draw_rect_empty(sb.x, 26, sb.width, 1, win.theme.dropdown_border)
}

fn (mut app App) make_status_bar(window &ui.Window) &ui.HBox {
	mut sb := ui.hbox(window)

	sb.draw_event_fn = statusbar_draw_event

	mut zoom_inc := app.zoom_btn(1)
	zoom_inc.set_click_fn(on_zoom_inc_click, app)
	zoom_inc.set_bounds(1, 2, 40, 25)

	mut zoom_dec := app.zoom_btn(0)
	zoom_dec.set_click_fn(on_zoom_dec_click, app)
	zoom_dec.set_bounds(9, 2, 40, 25)

	mut status := ui.label(window, 'status')
	app.stat_lbl = &status
	// mut stat_lbl := &status

	mut zoom_lbl := ui.label(window, '100%')
	mut zl_ref := &zoom_lbl // TODO: make ui.label return reference

	zoom_lbl.draw_event_fn = fn (win &ui.Window, mut com ui.Component) {
		mut app := &App(win.id_map['app']) // Let's avoid closures here to support wasm
		zoom := app.canvas.get_zoom() * 100
		com.text = '$zoom%'
		if mut com is ui.Label {
			com.pack()
			ws := win.gg.window_size()
			com.x = ws.width - com.width - app.stat_lbl.width - 120
			com.y = 18 - (com.height / 2) // Y-Center
		}
	}

	status.draw_event_fn = stat_lbl_draw_event

	sb.add_child(status)
	sb.add_child(zl_ref)
	sb.add_child(zoom_dec)
	sb.add_child(zoom_inc)
	sb.z_index = 20
	return sb
}

fn stat_lbl_draw_event(win &ui.Window, mut com ui.Component) { //(mut app App)
	app := &App(win.id_map['app'])
	mouse_details := 'm: ($app.canvas.mx, $app.canvas.my)'
	com.text = '$app.canvas.w x $app.canvas.h     $app.data.file_size     $mouse_details'
	if mut com is ui.Label {
		com.pack()
	}
	com.x = 12
	com.y = (32 / 2) - (com.height / 2) // Y-Center
	// fit_lbl(mut stat_lbl)
}

fn (mut app App) zoom_btn(val int) &ui.Button {
	txt := if val == 0 { '-' } else { '+' }
	mut btn := ui.button(app.win, txt)
	btn.border_radius = 0
	return &btn
}

fn on_zoom_inc_click(win voidptr, btn voidptr, mut app App) {
	zoom := app.canvas.get_zoom()
	new_zoom := if zoom >= 1 { zoom + 1 } else { zoom + .25 }

	app.canvas.set_zoom(new_zoom)
}

fn on_zoom_dec_click(win voidptr, mut btn ui.Button, mut app App) {
	zoom := app.canvas.get_zoom()
	new_zoom := if zoom > 1 { zoom - 1 } else { zoom - .25 }

	app.canvas.set_zoom(new_zoom)
}
