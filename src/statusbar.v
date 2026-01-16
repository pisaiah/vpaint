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

fn zoom_label_draw_event(mut e ui.DrawEvent) {
	mut com := e.target
	mut app := e.ctx.win.get[&App]('app')
	zoom := int(app.canvas.get_zoom() * 100)
	com.text = '${zoom}%'
	if mut com is ui.Label {
		com.center_text_y = true
		com.width = e.ctx.text_width(com.text)
		com.height = com.parent.height
	}
}

fn (mut app App) make_status_bar(window &ui.Window) &ui.Panel {
	mut zoom_inc := app.zoom_btn(1)
	zoom_inc.subscribe_event('mouse_up', app.on_zoom_inc)
	zoom_inc.set_bounds(1, 0, 40, 26)

	mut zoom_dec := app.zoom_btn(0)
	zoom_dec.subscribe_event('mouse_up', app.on_zoom_dec)
	zoom_dec.set_bounds(4, 0, 40, 26)

	mut status := ui.Label.new(
		text:           'status'
		vertical_align: .middle
	)
	app.stat_lbl = status

	mut zoom_lbl := ui.Label.new(text: '100%')

	zoom_lbl.subscribe_event('draw', zoom_label_draw_event)
	status.subscribe_event('draw', stat_lbl_draw_event)

	mut stat_btn := ui.Button.new(
		text:     '\uE90E'
		width:    24
		height:   24
		on_click: fn (mut e ui.MouseEvent) {
			mut app := e.ctx.win.get[&App]('app')
			app.show_prop_modal(e.ctx)
		}
	)
	status.set_bounds(0, 0, 0, 24)
	stat_btn.font = 1

	mut tool_select := ui.Selectbox.new(
		text:  'Pencil'
		items: [
			'Select',
			'Pencil',
			'Fillcan',
			'Drag',
			'Airbrush',
			'Eye Dropper',
			'Line',
			'Rectangle',
			'Oval',
			'Triangle',
		]
	)

	tool_select.subscribe_event('item_change', box_change_fn)
	tool_select.subscribe_event('draw', tool_box_draw_event)
	tool_select.set_bounds(0, 0, 90, 25)

	mut west_panel := ui.Panel.new(
		layout:   ui.BoxLayout.new(vgap: 0, hgap: 5)
		children: [
			stat_btn,
			tool_select,
			status,
		]
	)
	west_panel.set_bounds(-5, 0, 250, 0)

	mut zp := ui.Panel.new(
		layout:   ui.BoxLayout.new(vgap: 0, hgap: 5)
		children: [
			zoom_lbl,
			zoom_dec,
			zoom_inc,
		]
	)

	mut sb := ui.Panel.new(
		layout: ui.BorderLayout.new(vgap: 4)
	)
	sb.subscribe_event('draw', statusbar_draw_event)
	sb.add_child_with_flag(west_panel, ui.borderlayout_west)
	sb.add_child_with_flag(zp, ui.borderlayout_east)
	return sb
}

fn box_change_fn(mut e ui.ItemChangeEvent) {
	mut app := e.ctx.win.get[&App]('app')
	app.set_tool_by_name(e.new_val)
}

fn tool_box_draw_event(mut e ui.DrawEvent) {
	app := e.ctx.win.get[&App]('app')
	e.target.text = '${app.tool.tool_name}'

	tw := e.ctx.text_width(e.target.text) + 32

	if e.target.width < tw {
		e.target.width = tw
	}
}

fn stat_lbl_draw_event(mut e ui.DrawEvent) {
	app := e.ctx.win.get[&App]('app')
	mouse_details := '(${app.canvas.mx}, ${app.canvas.my})'
	mut com := e.target

	ww := e.ctx.gg.window_size().width
	if ww < 440 {
		com.text = '${app.canvas.w}x${app.canvas.h} / ${mouse_details}'
	} else {
		com.text = '${app.canvas.w}x${app.canvas.h} / ${app.data.file_size} / m: ${mouse_details}'
	}

	if mut com is ui.Label {
		com.width = e.ctx.text_width(com.text)
		com.height = 24
	}
}

fn (mut app App) zoom_btn(val int) &ui.Button {
	txt := if val == 0 { '\ue989' } else { '\ue988' }
	mut btn := ui.Button.new(text: txt)
	btn.font = 1
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
