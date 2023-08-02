module main

import iui as ui
import gg

fn statusbar_draw_event(mut e ui.DrawEvent) {
	mut win := e.ctx.win
	mut app := win.get[&App]('app')
	ws := win.gg.window_size()
	mut sb := app.status_bar
	sb.width = ws.width
	sb.height = 35

	win.gg.draw_rect_filled(sb.x, sb.y, sb.width, sb.height, win.theme.menubar_background)
	win.gg.draw_rect_empty(sb.x, sb.y, sb.width, 1, win.theme.dropdown_border)
	win.gg.draw_rect_empty(sb.x, 26, sb.width, 1, win.theme.dropdown_border)
}

fn (mut app App) make_status_bar(window &ui.Window) &ui.Panel {
	mut sb := ui.Panel.new(
		layout: ui.BorderLayout{}
	)

	sb.subscribe_event('draw', statusbar_draw_event)

	mut zoom_inc := app.zoom_btn(1)
	zoom_inc.set_click_fn(on_zoom_inc_click, app)
	zoom_inc.set_bounds(1, 0, 40, 25)

	mut zoom_dec := app.zoom_btn(0)
	zoom_dec.set_click_fn(on_zoom_dec_click, app)
	zoom_dec.set_bounds(4, 0, 40, 25)

	mut status := ui.Label.new(text: 'status')
	app.stat_lbl = status
	// mut stat_lbl := &status

	mut zoom_lbl := ui.label(window, '100%')

	zoom_lbl.subscribe_event('draw', fn (mut e ui.DrawEvent) {
		mut com := e.target
		mut app := e.ctx.win.get[&App]('app')
		zoom := app.canvas.get_zoom() * 100
		com.text = '${zoom}%'
		if mut com is ui.Label {
			com.pack()
			com.set_y(18 - (com.height / 2)) // Y-Center
		}
	})

	status.subscribe_event('draw', stat_lbl_draw_event)

	mut zp := ui.Panel.new(
		layout: ui.FlowLayout{
			vgap: 4
			hgap: 4
		}
	)
	zp.set_bounds(0, 0, 160, 25)

	sb.add_child_with_flag(status, ui.borderlayout_center)
	zp.add_child(zoom_lbl)
	zp.add_child(zoom_dec)
	zp.add_child(zoom_inc)
	sb.add_child_with_flag(zp, ui.borderlayout_east)
	return sb
}

fn stat_lbl_draw_event(mut e ui.DrawEvent) {
	app := e.ctx.win.get[&App]('app')
	mouse_details := 'm: (${app.canvas.mx}, ${app.canvas.my})'
	mut com := e.target
	com.text = '${app.canvas.w} x ${app.canvas.h}     ${app.data.file_size}     ${mouse_details}'
	if mut com is ui.Label {
		com.pack()
	}
	com.set_x(10)
	com.set_y(10)
}

fn (mut app App) zoom_btn(val int) &ui.Button {
	txt := if val == 0 { '-' } else { '+' }
	mut btn := ui.button(text: txt)
	btn.border_radius = 0
	return btn
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
