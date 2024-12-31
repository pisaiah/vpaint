module main

import iui as ui
import os
import gx

// Version
const version = '0.6-dev'

// About Info
const about_text = [
	'Simple Image Editor written in the V Language.',
	'(version ${version}) (iUI: ${ui.version})',
	'\t ',
	'Copyright \u00A9 2022-2025 Isaiah.',
	'Released under MIT License.',
]

// Settings
struct Settings {
mut:
	autohide_sidebar bool
	theme            string = 'Default'
	round_ends       bool   = true
	show_gridlines   bool   = true
}

// Our Paint App
@[heap]
struct App {
mut:
	win            &ui.Window
	sv             &ui.ScrollView
	sidebar        &ui.Panel
	canvas_zoom    int
	data           &ImageViewData
	canvas         &Image
	color          gx.Color
	color_2        gx.Color = gx.white
	sele_color     bool
	tool           &Tool
	ribbon         &ui.Panel
	status_bar     &ui.Panel
	stat_lbl       &ui.Label
	brush_size     int = 1
	bg_id          int
	need_open      bool
	settings       &Settings
	wasm_load_tick int
	cp             &ColorPicker
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
	mut window := ui.Window.new(
		title:     'vPaint ${version}'
		width:     550 // 700
		height:    450
		font_size: 16
		ui_mode:   false
	)

	mut app := &App{
		sv:         unsafe { nil }
		sidebar:    ui.Panel.new(layout: ui.FlowLayout.new(vgap: 1, hgap: 1))
		data:       unsafe { nil }
		canvas:     unsafe { nil }
		win:        window
		ribbon:     ui.Panel.new(layout: ui.BoxLayout.new(vgap: 4, hgap: 4))
		status_bar: unsafe { nil }
		stat_lbl:   unsafe { nil }
		tool:       &PencilTool{}
		settings:   &Settings{}
		cp:         unsafe { nil }
	}
	window.id_map['app'] = app

	app.settings_load() or { println('Error loading settings: ${err}') }
	app.make_menubar(mut window)

	mut path := os.resource_abs_path('untitledv.png')

	if os.args.len > 1 {
		path = os.real_path(os.args[1])
	}

	if !os.exists(path) {
		mut blank_png := $embed_file('blank.png')
		os.write_file_array(path, blank_png.to_bytes()) or { panic(error) }
	}

	mut image_panel := app.make_image_view(path)

	if '-upscale' in os.args {
		println('Upscaling ${os.args[1]}...')
		out_path := os.args[3].split('-path=')[1]
		app.canvas.scale2x()
		app.write_img(app.data.file, out_path)
		return
	}

	if os.args.len == 4 && os.args[2].contains('-upscale=') {
		times := os.args[2].split('-upscale=')[1].int()

		println('Upscaling ${times}x "${os.args[1]}"...')
		out_path := os.args[3].split('-path=')[1]

		for _ in 0 .. times {
			app.canvas.scale2x()
		}
		app.write_img(app.data.file, out_path)
		return
	}

	mut sv := &ui.ScrollView{
		children:  [image_panel]
		increment: 2
		padding:   50
	}
	app.sv = sv
	sv.set_bounds(0, 0, 500, 210)

	app.make_sidebar()

	// Ribbon bar
	// app.ribbon.z_index = 21
	app.ribbon.subscribe_event('draw', ribbon_draw_fn)

	app.make_ribbon()

	mut sb := app.make_status_bar(window)
	app.status_bar = sb

	mut pan := ui.Panel.new(
		layout: ui.BorderLayout.new(
			hgap: 0
			vgap: 0
		)
	)

	pan.add_child(app.ribbon, value: ui.borderlayout_north)
	pan.add_child_with_flag(app.sidebar, ui.borderlayout_west)
	pan.add_child_with_flag(app.sv, ui.borderlayout_center)
	pan.add_child_with_flag(sb, ui.borderlayout_south)

	window.add_child(pan)

	mut win := app.win
	tb_file := $embed_file('assets/checker2.png')
	data := tb_file.to_bytes()
	gg_im := win.gg.create_image_from_byte_array(data) or { panic(err) }
	cim := win.gg.cache_image(gg_im)
	app.bg_id = cim

	background := gx.rgb(210, 220, 240)
	window.gg.set_bg_color(background)

	app.set_theme_bg(app.win.theme.name)

	window.gg.run()
}
