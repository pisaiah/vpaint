module main

import iui as ui

fn statusbar_draw_event(mut e ui.DrawEvent) {
	mut win := e.ctx.win
	mut app := win.get[&App]('app')
	ws := win.gg.window_size()
	mut sb := app.status_bar
	sb.width = ws.width
	sb.height = 32

	win.gg.draw_rect_filled(sb.x, sb.y, sb.width, sb.height, win.theme.menubar_background)
	// win.gg.draw_rect_empty(sb.x, sb.y, sb.width, 1, win.theme.dropdown_border)
	// win.gg.draw_rect_empty(sb.x, 26, sb.width, 1, win.theme.dropdown_border)
}

fn (mut app App) make_status_bar(window &ui.Window) &ui.Panel {
	mut sb := ui.Panel.new(
		layout: ui.BorderLayout.new(vgap: 4)
	)

	sb.subscribe_event('draw', statusbar_draw_event)

	mut zoom_inc := app.zoom_btn(1)
	zoom_inc.subscribe_event('mouse_up', app.on_zoom_inc)
	zoom_inc.set_bounds(1, 0, 40, 26)

	mut zoom_dec := app.zoom_btn(0)
	zoom_dec.subscribe_event('mouse_up', app.on_zoom_dec)
	zoom_dec.set_bounds(4, 0, 40, 26)

	mut status := ui.Label.new(text: 'status')
	app.stat_lbl = status

	mut zoom_lbl := ui.Label.new(text: '100%')

	zoom_lbl.subscribe_event('draw', fn (mut e ui.DrawEvent) {
		mut com := e.target
		mut app := e.ctx.win.get[&App]('app')
		zoom := int(app.canvas.get_zoom() * 100)
		com.text = '${zoom}%'
		if mut com is ui.Label {
			com.center_text_y = true
			com.width = e.ctx.text_width(com.text)
			com.height = com.parent.height
		}
	})

	status.subscribe_event('draw', stat_lbl_draw_event)

	mut zp := ui.Panel.new(
		layout: ui.BoxLayout.new(vgap: 0, hgap: 5)
	)
	sb.add_child_with_flag(status, ui.borderlayout_west)
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
	com.text = '${app.canvas.w} x ${app.canvas.h} / ${app.data.file_size} / ${mouse_details} / ${app.tool.tool_name}'
	if mut com is ui.Label {
		com.pack()
	}
	com.set_x(10)
	com.set_y(10)
}

fn (mut app App) zoom_btn(val int) &ui.Button {
	txt := if val == 0 { '-' } else { '+' }
	mut btn := ui.Button.new(text: txt)
	btn.border_radius = 8
	return btn
}

fn (mut app App) on_zoom_inc(mut e ui.MouseEvent) {
	zoom := app.canvas.get_zoom()
	new_zoom := if zoom >= 1 { zoom + 1 } else { zoom + .25 }

	if zoom < .25 {
		app.canvas.set_zoom(.25)
		return
	}

	app.canvas.set_zoom(new_zoom)
}

fn (mut app App) on_zoom_dec(mut e ui.MouseEvent) {
	zoom := app.canvas.get_zoom()
	new_zoom := if zoom > 1 { zoom - 1 } else { zoom - .25 }

	if new_zoom < .25 {
		app.canvas.set_zoom(.15)
		return
	}

	app.canvas.set_zoom(new_zoom)
}
