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
	ribbon      &ui.Panel
	status_bar  &ui.Panel
	stat_lbl    &ui.Label
	brush_size  int = 1
	bg_id       int
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

fn main() {
	// Create Window
	mut window := ui.make_window(
		title: 'vPaint'
		width: 700
		height: 500
		font_size: 16
		// ui_mode: true
	)

	mut app := &App{
		sv: unsafe { nil }
		sidebar: ui.hbox(window)
		data: unsafe { nil }
		canvas: unsafe { nil }
		win: window
		ribbon: ui.Panel.new()
		status_bar: unsafe { nil }
		stat_lbl: unsafe { nil }
		tool: &PencilTool{}
	}
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

	mut tree := make_image_view(path, mut window, mut app)

	// app.sidebar.z_index = 21

	mut sv := &ui.ScrollView{
		children: [tree]
		increment: 2
		padding: 50
	}
	app.sv = sv
	sv.set_bounds(0, 0, 500, 210)

	sv.subscribe_event('draw', image_scrollview_draw_event_fn)

	app.make_sidebar()

	// Ribbon bar
	// app.ribbon.z_index = 21
	app.ribbon.subscribe_event('draw', ribbon_draw_fn)

	app.make_ribbon()

	// window.add_child(app.sidebar)
	// window.add_child(app.ribbon)
	// window.add_child(sv)

	mut sb := app.make_status_bar(window)
	app.status_bar = sb
	// window.add_child(sb)

	mut pan := ui.Panel.new(
		layout: ui.BorderLayout{
			hgap: 0
			vgap: 0
		}
	)

	pan.add_child_with_flag(app.ribbon, ui.borderlayout_north)
	pan.add_child_with_flag(app.sidebar, ui.borderlayout_west)
	pan.add_child_with_flag(app.sv, ui.borderlayout_center)
	pan.add_child_with_flag(sb, ui.borderlayout_south)

	window.add_child(pan)

	mut win := app.win
	tb_file := $embed_file('assets/checker.png')
	data := tb_file.to_bytes()
	gg_im := win.gg.create_image_from_byte_array(data) or { panic(err) }
	cim := win.gg.cache_image(gg_im)
	app.bg_id = cim

	window.gg.run()
}

fn fit_lbl(mut lbl ui.Label) {
	lbl.pack()
	lbl.x = 10
	lbl.y = (32 / 2) - (lbl.height / 2) // Y-Center
}

// Image canvas ScrollView draw event
// fn image_scrollview_draw_event_fn(mut win ui.Window, com &ui.Component) {
fn image_scrollview_draw_event_fn(mut e ui.DrawEvent) {
	mut app := e.ctx.win.get[&App]('app')
	ws := e.ctx.gg.window_size()
	x_pos := 64
	bar_y := app.sidebar.y + 1
	// app.sv.set_bounds(x_pos, bar_y, ws.width - x_pos, ws.height - 31 - bar_y)

	// dump('draw')

	color := if 'background' in e.ctx.win.id_map {
		reff := e.ctx.win.get[&gx.Color]('background')
		gx.rgb(reff.r, reff.g, reff.b)
	} else {
		// gx.rgb(210, 220, 240)
		gx.rgb(230, 235, 245)
	}

	// e.ctx.gg.draw_rect_filled(app.sv.x, 0, ws.width, ws.height, color)
}
