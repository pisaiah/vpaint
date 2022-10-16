module main

import iui as ui
import gx

fn (mut app App) set_tool_pencil(mut win ui.Window, com ui.MenuItem) {
	app.tool = &PencilTool{}
}

fn (mut app App) set_tool_select(mut win ui.Window, com ui.MenuItem) {
	app.tool = &SelectTool{}
}

fn (mut app App) set_tool_fill(mut win ui.Window, com ui.MenuItem) {
	app.tool = &FillTool{}
}

fn upscale_click(mut win ui.Window, com ui.MenuItem) {
	mut app := &App(win.id_map['app'])
	app.canvas.upscale()
}

// Make menubar
fn (mut app App) make_menubar(mut window ui.Window) {
	// Setup Menubar and items
	window.bar = ui.menubar(window, window.theme)
	window.bar.add_child(ui.menu_item(
		text: 'File'
		children: [
			ui.menu_item(
				text: 'New'
			),
			ui.menu_item(
				text: 'Open'
			),
			ui.menu_item(
				text: 'About Paint'
				click_event_fn: about_click
			),
		]
	))
	window.bar.add_child(ui.menu_item(
		text: 'Tools'
		children: [
			ui.menu_item(
				text: 'Pencil'
				// click_event_fn: app.set_tool_pencil
			),
			ui.menu_item(
				text: 'Select'
				// click_event_fn: app.set_tool_select
			),
			ui.menu_item(
				text: 'Fillcan'
				// click_event_fn: app.set_tool_fill
			),
			ui.menu_item(
				text: 'Upscale 2x'
				click_event_fn: upscale_click
			),
		]
	))

	window.bar.add_child(ui.menu_item(
		text: 'View'
		children: [
			ui.menu_item(
				text: 'Fit Canvas'
				// click_event_fn: app.menubar_fit_zoom_click
			),
			ui.menu_item(
				text: 'Zoom-out'
				// click_event_fn: app.menubar_zoom_out_click
			),
			ui.menu_item(
				text: 'Zoom-In'
				// click_event_fn: app.menubar_zoom_in_click
			),
		]
	))

	window.bar.add_child(ui.menu_item(
		text: 'Size'
		children: [
			size_menu_item(1),
			size_menu_item(2),
			size_menu_item(4),
			size_menu_item(8),
			size_menu_item(16),
			size_menu_item(32),
			size_menu_item(64),
		]
	))

	mut theme_menu := ui.menuitem('Theme')
	mut themes := ui.get_all_themes()
	for theme2 in themes {
		mut item := ui.menuitem(theme2.name)
		item.set_click(theme_click)
		theme_menu.add_child(item)
	}

	window.bar.add_child(theme_menu)
}

fn size_menu_item(size int) &ui.MenuItem {
	item := ui.menu_item(
		text: '$size px'
		click_event_fn: menu_size_click
	)
	return item
}

fn menu_size_click(mut win ui.Window, com ui.MenuItem) {
	mut app := &App(win.id_map['app'])

	size := com.text.replace(' px', '').int()

	app.brush_size = size
}

fn (mut app App) menubar_zoom_in_click(mut win ui.Window, com ui.MenuItem) {
	zoom := app.canvas.get_zoom()
	new_zoom := if zoom >= 1 { zoom + 2 } else { 1 }
	app.canvas.set_zoom(new_zoom)
}

fn (mut app App) menubar_zoom_out_click(mut win ui.Window, com ui.MenuItem) {
	app.tool = &PencilTool{}
	zoom := app.canvas.get_zoom()
	new_zoom := if zoom > 1 { zoom - 2 } else { 1 }
	app.canvas.set_zoom(new_zoom)
}

fn (mut app App) menubar_fit_zoom_click(mut win ui.Window, com ui.MenuItem) {
	canvas_height := app.sv.height - 50
	level := canvas_height / app.data.file.height
	app.canvas.set_zoom(level)
}

// Change Window Theme
fn theme_click(mut win ui.Window, com ui.MenuItem) {
	text := com.text
	mut theme := ui.theme_by_name(text)
	win.set_theme(theme)

	if text.contains('Dark') {
		background := gx.rgb(25, 42, 77)
		win.gg.set_bg_color(gx.rgb(25, 42, 77))
		win.id_map['background'] = &background
	} else if text.contains('Black') {
		win.gg.set_bg_color(gx.rgb(0, 0, 0))
		background := gx.rgb(0, 0, 0)
		win.id_map['background'] = &background
	} else if text.contains('Green Mono') {
		win.gg.set_bg_color(gx.rgb(0, 16, 0))
		background := gx.rgb(0, 16, 0)
		win.id_map['background'] = &background
	} else {
		win.gg.set_bg_color(gx.rgb(210, 220, 240))
		background := gx.rgb(210, 220, 240)
		win.id_map['background'] = &background
	}
}

fn about_click(mut win ui.Window, com ui.MenuItem) {
	mut modal := ui.page(win, 'About vPaint')

	mut title := ui.label(win, 'VPaint')
	title.set_config(32, true, true)
	title.pack()

	mut label := ui.label(win, 'Simple Image Editor written in the V Programming Language.' +
		'\n\n\u00A9 2022 Isaiah. All Rights Reserved.')

	mut versions := ui.label(win, 'Version: 1.0 (Development Build) \u2014 UI Version: $ui.version')

	mut icons8 := ui.link(
		text: 'Icons by Icons8'
		url: 'https://icons8.com/'
		bounds: ui.Bounds{
			x: 8
			y: 16
		}
		pack: true
	)

	label.set_config(18, true, false)
	versions.set_config(18, true, false)
	icons8.set_config(18, true, true)

	versions.pack()
	label.pack()

	mut vbox := ui.vbox(win)
	vbox.set_pos(32, 18)
	vbox.add_child(title)
	vbox.add_child(label)
	vbox.add_child(versions)
	vbox.add_child(icons8)

	modal.add_child(vbox)

	win.add_child(modal)
}
