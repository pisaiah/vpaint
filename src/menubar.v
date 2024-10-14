module main

import iui as ui
import gx

fn upscale_click(mut win ui.Window, com ui.MenuItem) {
	mut app := win.get[&App]('app')

	txt := com.text

	if txt.contains('bilinear') {
		app.canvas.bilinear_interpolation(app.canvas.w * 2, app.canvas.h * 2)
		return
	}

	if txt.contains('scale2x') {
		app.canvas.scale2x()
		return
	}

	if txt.contains('hq3x') {
		app.canvas.hq3x()
		return
	}

	app.canvas.upscale()
}

fn tool_item_click(mut win ui.Window, com ui.MenuItem) {
	mut app := win.get[&App]('app')
	app.set_tool_by_name(com.text)

	// "Fake" a press
	for mut btn in app.sidebar.children[0].children {
		btn.is_selected = btn.text == com.text
	}
}

fn grayscale_click(mut win ui.Window, com ui.MenuItem) {
	mut app := win.get[&App]('app')
	app.canvas.grayscale_filter()
}

fn inc_alpha_click(mut win ui.Window, com ui.MenuItem) {
	mut app := win.get[&App]('app')
	app.canvas.increase_alpha()
}

fn invert_click(mut win ui.Window, com ui.MenuItem) {
	mut app := win.get[&App]('app')
	app.canvas.invert_filter()
}

fn undo_click(mut win ui.Window, com ui.MenuItem) {
	mut app := win.get[&App]('app')
	app.canvas.undo()
}

fn new_click(mut win ui.Window, com ui.MenuItem) {
	mut app := win.get[&App]('app')
	app.load_new(1024, 1024)
}

fn open_click(mut win ui.Window, com ui.MenuItem) {
	mut app := win.get[&App]('app')
	app.open()
}

fn save_click(mut win ui.Window, com ui.MenuItem) {
	mut app := win.get[&App]('app')
	app.save()
}

fn save_as_click(mut win ui.Window, com ui.MenuItem) {
	mut app := win.get[&App]('app')
	app.save_as()
}

fn menu_zoom_in_click(mut win ui.Window, com ui.MenuItem) {
	mut app := win.get[&App]('app')
	nz := app.canvas.zoom + 100
	app.canvas.set_zoom(nz)
}

// Make menubar
fn (mut app App) make_menubar(mut window ui.Window) {
	// Setup Menubar and items
	window.bar = ui.Menubar.new()
	window.bar.add_child(ui.menu_item(
		text:     'File'
		children: [
			ui.menu_item(
				text:           'New'
				click_event_fn: new_click
			),
			ui.menu_item(
				text:           'Open...'
				click_event_fn: open_click
			),
			ui.menu_item(
				text:           'Save'
				click_event_fn: save_click
			),
			ui.menu_item(
				text:           'Save As...'
				click_event_fn: save_as_click
			),
			ui.menu_item(
				text:           'Settings'
				click_event_fn: settings_click
			),
			ui.menu_item(
				text:           'About Paint'
				click_event_fn: about_click
			),
			ui.menu_item(
				text: 'About iUI'
			),
		]
	))
	window.bar.add_child(ui.menu_item(
		text:     'Edit'
		children: [
			ui.menu_item(
				text:           'Upscale 2x'
				click_event_fn: upscale_click
			),
			ui.MenuItem.new(
				text:     'Scaling...'
				children: [
					ui.MenuItem.new(
						text:           'bilinear interpolation'
						click_event_fn: upscale_click
					),
					ui.MenuItem.new(
						text:           'scale2x'
						click_event_fn: upscale_click
					),
					ui.MenuItem.new(
						text:           'hq3x'
						click_event_fn: upscale_click
					),
				]
			),
			ui.menu_item(
				text:           'Apply Grayscale'
				click_event_fn: grayscale_click
			),
			ui.menu_item(
				text:           'Invert Image'
				click_event_fn: invert_click
			),
			ui.menu_item(
				text:           'Increase Alpha'
				click_event_fn: inc_alpha_click
			),
			ui.menu_item(
				text:           'Undo'
				click_event_fn: undo_click
			),
			ui.menu_item(
				text:           'Resize Canvas'
				click_event_fn: menu_resize_click
			),
		]
	))

	mut tool_item := ui.MenuItem.new(
		text: 'Tools'
	)

	labels := ['Pencil', 'Fill', 'Drag', 'Select', 'Airbrush', 'Dropper', 'WidePencil']

	for label in labels {
		tool_item.add_child(ui.MenuItem.new(
			text:           label
			click_event_fn: tool_item_click
		))
	}

	window.bar.add_child(tool_item)

	window.bar.add_child(ui.menu_item(
		text:     'View'
		children: [
			ui.menu_item(
				text:           'Fit Canvas'
				click_event_fn: menubar_fit_zoom_click
			),
			ui.menu_item(
				text: 'Zoom-out'
				// click_event_fn: app.menubar_zoom_out_click
			),
			ui.menu_item(
				text:           'Zoom-In'
				click_event_fn: menu_zoom_in_click
			),
		]
	))

	window.bar.add_child(ui.menu_item(
		text:     'Size'
		children: [
			size_menu_item(1),
			size_menu_item(2),
			size_menu_item(4),
			size_menu_item(8),
			size_menu_item(16),
			size_menu_item(32),
			size_menu_item(64),
			ui.menu_item(
				text:           'Custom'
				click_event_fn: menu_size_custom_click
			),
		]
	))

	mut theme_menu := ui.MenuItem.new(
		text: 'Theme'
	)
	mut themes := ui.get_all_themes()
	for theme2 in themes {
		mut item := ui.MenuItem.new(text: theme2.name)
		item.set_click(theme_click)
		theme_menu.add_child(item)
	}

	window.bar.add_child(theme_menu)

	undo_img := $embed_file('assets/undo.png')

	undo_icon := ui.image_from_bytes(mut window, undo_img.to_bytes(), 24, 24)
	mut undo_item := ui.menu_item(
		text:           'Undo'
		click_event_fn: undo_click
		icon:           undo_icon
	)
	undo_item.width = 30
	window.bar.add_child(undo_item)
}

fn size_menu_item(size int) &ui.MenuItem {
	item := ui.menu_item(
		text:           '${size} px'
		click_event_fn: menu_size_click
	)
	return item
}

fn menu_size_custom_click(mut win ui.Window, com ui.MenuItem) {
	mut app := win.get[&App]('app')
	app.show_size_modal()
}

fn menu_resize_click(mut win ui.Window, com ui.MenuItem) {
	mut app := win.get[&App]('app')
	app.show_resize_modal(app.canvas.w, app.canvas.h)
}

fn menu_size_click(mut win ui.Window, com ui.MenuItem) {
	mut app := win.get[&App]('app')
	size := com.text.replace(' px', '').int()
	app.brush_size = size
}

fn menubar_fit_zoom_click(mut win ui.Window, com ui.MenuItem) {
	mut app := win.get[&App]('app')
	canvas_height := app.sv.height - 50
	level := canvas_height / app.data.file.height
	app.canvas.set_zoom(level)
}

// Change Window Theme
fn theme_click(mut win ui.Window, com ui.MenuItem) {
	text := com.text
	mut theme := ui.theme_by_name(text)
	win.set_theme(theme)

	mut app := win.get[&App]('app')
	app.settings.theme = text
	app.set_theme_bg(text)
	app.settings_save() or {}
}

fn (mut app App) set_theme_bg(text string) {
	if text.contains('Dark') {
		background := gx.rgb(25, 42, 77)
		app.win.gg.set_bg_color(gx.rgb(25, 42, 77))
		app.win.id_map['background'] = &background
	} else if text.contains('Black') {
		app.win.gg.set_bg_color(gx.rgb(0, 0, 0))
		background := gx.rgb(0, 0, 0)
		app.win.id_map['background'] = &background
	} else if text.contains('Green Mono') {
		app.win.gg.set_bg_color(gx.rgb(0, 16, 0))
		background := gx.rgb(0, 16, 0)
		app.win.id_map['background'] = &background
	} else {
		background := gx.rgb(210, 220, 240)
		app.win.gg.set_bg_color(background)
		app.win.id_map['background'] = &background
	}
}

fn settings_click(mut win ui.Window, com ui.MenuItem) {
	mut app := win.get[&App]('app')
	app.show_settings()
}

fn about_click(mut win ui.Window, com ui.MenuItem) {
	mut modal := ui.modal(win, 'About vPaint')

	modal.top_off = 25
	modal.in_width = 300
	modal.in_height = 290

	mut title := ui.Label.new(text: 'VPaint')
	title.set_config(32, true, true)
	title.pack()

	mut p := ui.Panel.new(
		layout: ui.BorderLayout.new(
			hgap: 20
		)
	)
	p.add_child_with_flag(title, ui.borderlayout_north)

	txt := [
		'Simple Image Editor written in the V Language.',
		'(version 0.6-dev) (iUI: ${ui.version})',
		'\t ',
		'Copyright \u00A9 2022-2024 Isaiah.',
		'Released under MIT License.',
	]

	mut lbl := ui.Label.new(text: txt.join('\n'))
	lbl.pack()
	p.add_child_with_flag(lbl, ui.borderlayout_center)

	mut lp := ui.Panel.new(
		layout: ui.BoxLayout.new(
			ori:  0
			hgap: 30
		)
	)
	lp.set_bounds(0, 0, modal.in_width - 32, 30)

	icons8 := ui.link(
		text: 'Icons8'
		url:  'https://icons8.com/'
		pack: true
	)

	git := ui.link(
		text: 'Github'
		url:  'https://github.com/pisaiah/vpaint'
		pack: true
	)

	vlang := ui.link(
		text: 'About V'
		url:  'https://vlang.io'
		pack: true
	)

	p.set_bounds(0, 9, modal.in_width, modal.in_height - 100)
	lp.add_child(icons8)
	lp.add_child(git)
	lp.add_child(vlang)
	p.add_child_with_flag(lp, ui.borderlayout_south)

	modal.add_child(p)
	modal.make_close_btn(true)
	modal.close.set_bounds((modal.in_width / 2) - 50, modal.in_height - 45, 100, 30)
	modal.needs_init = false

	win.add_child(modal)
}
