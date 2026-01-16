module main

import iui as ui
import os
import gg

// Version
const version = '0.7'

// About Info
const about_text = [
	'Simple Image Editor written in the V Language.',
	'(version ${version}) (iUI: ${ui.version})',
	'\t ',
	'Copyright \u00A9 2022-2026 Isaiah.',
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
	color          gg.Color
	color_2        gg.Color = gg.white
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

fn (app &App) get_color() gg.Color {
	if app.sele_color {
		return app.color_2
	}
	return app.color
}

fn (mut app App) set_color(c gg.Color) {
	if app.sele_color {
		app.color_2 = c
		return
	}
	app.color = c
}

fn get_load_path() string {
	path := os.resource_abs_path('untitledv.png')

	if os.args.len > 1 {
		return os.real_path(os.args[1])
	}

	if !os.exists(path) {
		return os.resource_abs_path('Untitled.png')
	}
	return path
}

// Command Line Arguments
// 	Compile Time:
// 		-d bigcanvas	= Start with a blank 4096x4096 Image
// 		-d bigtool		= Start with a Tool Size of 2048px
// 	Cmd Args:
// 		input.png -upscale=N -path=output.png	= Run scale2x on input for N times
fn (mut app App) parse_args() {
	$if bigcanvas ? {
		size := 4096
		app.load_new(size, size)
	}

	$if bigtool ? {
		app.brush_size = 2048
	}

	if '-upscale' in os.args {
		println('Upscaling ${os.args[1]}...')
		out_path := os.args[3].split('-path=')[1]
		app.canvas.scale2x()
		app.write_img(app.data.file, out_path)
		return
	}

	if os.args.len == 4 && os.args[2].contains('-scale=') && os.args[3].contains('-t=') {
		// hq3x

		times := os.args[2].split('-scale=')[1]

		// app.canvas.hq3x()

		rs := os.args[3].split('-t=')[1].split(',')
		rs0 := rs[0].int()
		rs1 := rs[1].int()

		for app.canvas.width < rs0 || app.canvas.height < rs1 {
			// app.canvas.hq3x()
			if times == 'hq3x' {
				app.canvas.hq3x()
			}
			if times == 'scale2x' {
				app.canvas.scale2x()
			}
		}

		app.canvas.resize(rs[0].int(), rs[1].int())
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
}

// Main Function
fn main() {
	// Create Window
	mut window := ui.Window.new(
		title:     'vPaint ${version}'
		width:     800 // 700
		height:    600
		font_size: 16
		ui_mode:   false
	)

	path := get_load_path()

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

	mut image_panel := app.make_image_view(path)

	app.parse_args()

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

	background := gg.rgb(210, 220, 240)
	window.gg.set_bg_color(background)

	app.set_theme_bg(app.win.theme.name)

	window.gg.run()
}
