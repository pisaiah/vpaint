module main

import iui as ui
import gx

fn upscale_click(mut win ui.Window, com ui.MenuItem) {
	mut app := win.get[&App]('app')
	app.canvas.upscale()
}

fn grayscale_click(mut win ui.Window, com ui.MenuItem) {
	mut app := win.get[&App]('app')
	app.canvas.grayscale_filter()
}

fn invert_click(mut win ui.Window, com ui.MenuItem) {
	mut app := win.get[&App]('app')
	app.canvas.invert_filter()
}

fn undo_click(mut win ui.Window, com ui.MenuItem) {
	mut app := win.get[&App]('app')
	app.canvas.undo()
}

fn save_click(mut win ui.Window, com ui.MenuItem) {
	mut app := win.get[&App]('app')
	app.data.save()
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
				text: 'Save'
				click_event_fn: save_click
			),
			ui.menu_item(
				text: 'Settings'
				click_event_fn: settings_click
			),
			ui.menu_item(
				text: 'About Paint'
				click_event_fn: about_click
			),
			ui.menu_item(
				text: 'About iUI'
			),
		]
	))
	window.bar.add_child(ui.menu_item(
		text: 'Tools'
		children: [
			ui.menu_item(
				text: 'Upscale 2x'
				click_event_fn: upscale_click
			),
			ui.menu_item(
				text: 'Apply Grayscale'
				click_event_fn: grayscale_click
			),
			ui.menu_item(
				text: 'Invert Image'
				click_event_fn: invert_click
			),
			ui.menu_item(
				text: 'Undo'
				click_event_fn: undo_click
			),
		]
	))

	window.bar.add_child(ui.menu_item(
		text: 'View'
		children: [
			ui.menu_item(
				text: 'Fit Canvas'
				click_event_fn: menubar_fit_zoom_click
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
			ui.menu_item(
				text: 'Custom'
				click_event_fn: menu_size_custom_click
			),
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

	undo_img := $embed_file('assets/undo.png')

	undo_icon := ui.image_from_bytes(mut window, undo_img.to_bytes(), 24, 24)
	mut undo_item := ui.menu_item(
		text: 'Undo'
		click_event_fn: undo_click
		icon: undo_icon
	)
	undo_item.width = 30
	window.bar.add_child(undo_item)
}

fn size_menu_item(size int) &ui.MenuItem {
	item := ui.menu_item(
		text: '${size} px'
		click_event_fn: menu_size_click
	)
	return item
}

fn menu_size_custom_click(mut win ui.Window, com ui.MenuItem) {
	mut app := win.get[&App]('app')
	app.show_size_modal()
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
		background := gx.rgb(210, 220, 240)
		win.gg.set_bg_color(background)
		win.id_map['background'] = &background
	}
}

fn settings_click(mut win ui.Window, com ui.MenuItem) {
	mut app := win.get[&App]('app')
	app.show_settings()
}

fn about_click(mut win ui.Window, com ui.MenuItem) {
	mut modal := ui.modal(win, 'About vPaint')

	mut title := ui.Label.new(text: 'VPaint')
	title.set_config(32, true, true)
	title.pack()

	mut label := ui.Label.new(
		text: 'Simple Image Editor written in the V Programming Language.' +
			'\n\n\u00A9 2022-2023 Isaiah. All Rights Reserved.'
	)

	mut versions := ui.Label.new(
		text: 'Version: 1.0 (Development Build) \u2014 UI Version: ${ui.version}'
	)

	icons8 := ui.link(
		text: 'Icons by Icons8'
		url: 'https://icons8.com/'
		bounds: ui.Bounds{
			x: 0
			y: 16
		}
		pack: true
	)

	git := ui.link(
		text: 'vpaint @ Github'
		url: 'https://github.com/isaiahpatton/vpaint'
		bounds: ui.Bounds{
			x: 0
			y: 16
		}
		pack: true
	)

	// label.set_config(18, true, false)
	// versions.set_config(18, true, false)
	versions.pack()
	label.pack()

	mut vbox := ui.Panel.new()
	vbox.set_pos(32, 18)
	vbox.add_child(title)
	vbox.add_child(label)
	vbox.add_child(versions)
	vbox.add_child(icons8)
	vbox.add_child(git)

	modal.add_child(vbox)

	win.add_child(modal)
}
