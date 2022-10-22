module main

import gg
import iui as ui
import os
import gx

[heap]
struct App {
mut:
	win         &ui.Window
	sv          &ui.ScrollView
	sidebar     &ui.HBox
	canvas_zoom int
	data        &ImageViewData
	canvas      &Image
	color       gx.Color
	color_2     gx.Color = gx.white
	sele_color  bool
	tool        &Tool
	ribbon      &ui.HBox
	status_bar  &ui.HBox
	stat_lbl    &ui.Label
	brush_size  int = 1
}

fn (app &App) get_color() gx.Color {
	if app.sele_color {
		return app.color_2
	}
	return app.color
}

fn (mut app App) set_color(c gx.Color) {
	if app.sele_color {
		app.color_2 = c
		return
	}
	app.color = c
}

[console]
fn main() {
	// Create Window
	mut app := &App{
		sv: unsafe { nil }
		sidebar: unsafe { nil }
		data: unsafe { nil }
		canvas: unsafe { nil }
		win: unsafe { nil }
		ribbon: unsafe { nil }
		status_bar: unsafe { nil }
		stat_lbl: unsafe { nil }
		tool: &PencilTool{}
	}
	mut window := ui.make_window(
		title: 'vPaint'
		width: 700
		height: 500
		font_size: 14
		ui_mode: true
	)
	app.win = window
	window.id_map['app'] = app

	app.make_menubar(mut window)

	mut path := os.resource_abs_path('v.png')

	if os.args.len > 1 {
		path = os.real_path(os.args[1])
	}

	if !os.exists(path) {
		mut blank_png := $embed_file('v.png')
		os.write_file_array(path, blank_png.to_bytes()) or { panic(error) }
	}

	dump(path)
	dump(os.exists(path))
	mut tree := make_image_view(path, mut window, mut app)

	mut sidebar := ui.hbox(window)
	app.sidebar = sidebar
	sidebar.z_index = 21

	mut sv := &ui.ScrollView{
		children: [tree]
	}
	app.sv = sv
	sv.set_bounds(0, 0, 500, 210)
	sv.draw_event_fn = image_scrollview_draw_event_fn

	app.make_sidebar(mut sidebar)

	// Ribbon bar
	app.ribbon = ui.hbox(window)
	app.ribbon.z_index = 21
	app.ribbon.draw_event_fn = ribbon_draw_fn

	app.make_ribbon(mut app.ribbon)

	window.add_child(sidebar)
	window.add_child(app.ribbon)
	window.add_child(sv)

	mut sb := app.make_status_bar(window)
	app.status_bar = sb
	window.add_child(sb)

	window.gg.run()
}

fn fit_lbl(mut lbl ui.Label) {
	lbl.pack()
	lbl.x = 10
	lbl.y = (32 / 2) - (lbl.height / 2) // Y-Center
}

// Image canvas ScrollView draw event
fn image_scrollview_draw_event_fn(win &ui.Window, com &ui.Component) {
	mut app := &App(win.id_map['app'])
	ws := win.gg.window_size()
	x_pos := 72
	bar_y := app.sidebar.y
	app.sv.set_bounds(x_pos, bar_y, ws.width - x_pos, ws.height - 31 - bar_y)

	reff := &gx.Color(win.id_map['background'])
	color := if 'background' in win.id_map {
		gx.rgb(reff.r, reff.g, reff.b)
	} else {
		gx.rgb(210, 220, 240)
	}

	win.gg.draw_rect_filled(app.sv.x, 0, ws.width, ws.height, color)
}
