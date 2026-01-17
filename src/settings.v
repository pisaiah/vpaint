module main

import iui as ui
import os

fn (mut app App) show_settings() {
	// Auto-hide Sidebar
	mut card := ui.SettingsCard.new(
		uicon:       '\uE700'
		text:        'Sidebar Hidden'
		description: 'Choose to autohide the side toolbar.'
		stretch:     true
		children:    [
			ui.Checkbox.new(
				text:     'Autohide'
				selected: app.settings.autohide_sidebar
				bounds:   ui.Bounds{0, 0, 100, 24}
				on_click: app.hide_sidebar_mouse_up
			),
		]
	)

	// App Theme
	mut theme_card := ui.SettingsCard.new(
		uicon:       '\uE790'
		text:        'App Theme'
		description: 'Choose how the app looks'
		stretch:     true
		children:    [
			ui.Selectbox.new(
				text:      app.win.theme.name
				items:     app.win.get_theme_manager().get_themes().map(it.name)
				on_change: theme_select_change
				width:     120
				height:    30
			),
		]
	)

	// Round card
	mut round_card := ui.SettingsCard.new(
		uicon:       '\uF127'
		text:        'Round End Points'
		description: 'Round end-points of drawn lines'
		stretch:     true
		children:    [
			ui.Switch.new(
				text:     'Round'
				selected: app.settings.round_ends
				bounds:   ui.Bounds{0, 0, 100, 24}
				on_click: app.round_ends_mouse_up
			),
		]
	)

	// Gridlines
	mut grid_card := ui.SettingsCard.new(
		uicon:       '\uEA72'
		text:        'Show Gridlines'
		description: 'Choose to display gridlines on the Canvas.'
		stretch:     true
		children:    [
			ui.Checkbox.new(
				text:     'Gridlines'
				selected: app.settings.show_gridlines
				bounds:   ui.Bounds{0, 0, 100, 24}
				on_click: gridlines_item_click
			),
		]
	)

	// Content Panel
	mut p := ui.Panel.new(
		layout:   ui.FlowLayout.new()
		children: [
			ui.Panel.new(
				layout:   ui.BoxLayout.new(ori: 1)
				children: [
					card,
					theme_card,
					round_card,
					grid_card,
				]
			),
			ui.Panel.new(
				layout:   ui.FlowLayout.new(hgap: 10, vgap: 10)
				children: [
					ui.Label.new(
						text: 'About vPaint\n${about_text.join('\n')}\n'
					),
				]
			),
		]
	)

	p.subscribe_event('draw', fn (mut e ui.DrawEvent) {
		pw := e.ctx.gg.window_size().width
		tt := int(pw * f32(0.65))
		size := if pw < 800 { pw } else { tt }
		e.target.children[0].width = size - 10
	})

	mut page := ui.Page.new(
		title:    'Settings'
		children: [p]
	)
	app.win.add_child(page)
}

fn theme_select_change(mut e ui.ItemChangeEvent) {
	txt := e.target.text.replace('Light', 'Default')
	mut app := e.ctx.win.get[&App]('app')
	app.set_theme(txt)
}

fn (mut app App) round_ends_mouse_up(mut e ui.MouseEvent) {
	// TODO
	app.settings.round_ends = !e.target.is_selected
	app.settings_save() or {}
}

fn (mut app App) hide_sidebar_mouse_up(mut e ui.MouseEvent) {
	// TODO
	app.settings.autohide_sidebar = !e.target.is_selected
	app.settings_save() or {}
}

const default_config = ['# VPaint Configuration File', 'theme: Default']

fn wasm_save_files() {
	$if emscripten ? {
		C.emscripten_run_script(c'iui.trigger = "savefiles"')
	}
}

fn wasm_load_files() {
	$if emscripten ? {
		C.emscripten_run_script(c'iui.trigger = "lloadfiles"')
	}
}

fn get_cfg_dir() string {
	$if emscripten ? {
		return os.home_dir()
	}
	return os.config_dir() or { os.home_dir() }
}

fn (mut app App) settings_load() ! {
	wasm_load_files()

	cfg_dir := get_cfg_dir()
	dir := os.join_path(cfg_dir, '.vpaint')
	file := os.join_path(dir, 'config.txt')

	if !os.exists(dir) {
		os.mkdir(dir) or { return err }
	}

	if !os.exists(file) {
		app.settings_save()!
	}

	lines := os.read_lines(file) or { return err }
	for line in lines {
		if line.contains('# ') {
			continue
		}

		if !line.contains(':') {
			continue
		}

		spl := line.split(':')

		if spl[0] == 'autohide_sidebar' {
			app.settings.autohide_sidebar = spl[1].trim_space().bool()
		}
		if spl[0] == 'round_ends' {
			app.settings.round_ends = spl[1].trim_space().bool()
		}
		if spl[0] == 'theme' {
			text := spl[1].trim_space()
			mut theme := app.win.get_theme(text)
			app.win.set_theme(theme)
			app.set_theme_bg(text)
			app.settings.theme = text
		}
		if spl[0] == 'show_gridlines' {
			app.settings.show_gridlines = spl[1].trim_space().bool()
		}
	}
}

fn (mut app App) settings_save() ! {
	cfg_dir := get_cfg_dir()
	dir := os.join_path(cfg_dir, '.vpaint')
	file := os.join_path(dir, 'config.txt')

	if !os.exists(dir) {
		os.mkdir(dir) or { return err }
	}

	if !os.exists(file) {
		os.write_file(file, default_config.join('\n')) or { println(err) }
	}

	mut txt := [
		'# VPaint Configuration File',
		'autohide_sidebar: ${app.settings.autohide_sidebar}',
		'theme: ${app.settings.theme}',
		'round_ends: ${app.settings.round_ends}',
		'show_gridlines: ${app.settings.show_gridlines}',
	]
	os.write_file(file, txt.join('\n')) or { return err }

	if app.wasm_load_tick > 25 {
		wasm_save_files()
	}
}
