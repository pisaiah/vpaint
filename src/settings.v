module main

import iui as ui
import os

fn (mut app App) show_settings() {
	mut page := ui.Page.new(title: 'Settings')

	mut p := ui.Panel.new(
		layout: ui.FlowLayout.new()
	)

	mut panel := ui.Panel.new(layout: ui.BoxLayout.new(ori: 1))

	// Auto-hide Sidebar
	mut card := ui.SettingsCard.new(
		uicon:       '\uE700'
		text:        'Sidebar Hidden'
		description: 'Choose to autohide the side toolbar.'
		stretch:     true
	)
	mut box := ui.Checkbox.new(text: 'Autohide')
	box.is_selected = app.settings.autohide_sidebar
	box.set_bounds(0, 0, 100, 24)
	box.subscribe_event('mouse_up', app.hide_sidebar_mouse_up)

	card.add_child(box)

	// App Theme
	mut theme_card := ui.SettingsCard.new(
		uicon:       '\uE790'
		text:        'App Theme'
		description: 'Choose how the app looks'
		stretch:     true
	)

	mut cb := ui.Selectbox.new(
		text:  app.win.theme.name
		items: ui.get_all_themes().map(it.name)
	)

	cb.set_bounds(0, 0, 120, 30)
	cb.subscribe_event('item_change', fn (mut e ui.ItemChangeEvent) {
		txt := e.target.text.replace('Light', 'Default')
		mut app := e.ctx.win.get[&App]('app')
		app.set_theme(txt)
	})
	theme_card.add_child(cb)

	// Round card
	mut round_card := ui.SettingsCard.new(
		uicon:       '\uF127'
		text:        'Round End Points'
		description: 'Round end-points of drawn lines'
		stretch:     true
	)

	mut rbox := ui.Switch.new(text: 'Round')
	rbox.is_selected = app.settings.round_ends
	rbox.set_bounds(0, 0, 100, 24)
	rbox.subscribe_event('mouse_up', app.round_ends_mouse_up)
	round_card.add_child(rbox)

	// Gridlines
	mut grid_card := ui.SettingsCard.new(
		uicon:       '\uEA72'
		text:        'Show Gridlines'
		description: 'Choose to display gridlines on the Canvas.'
		stretch:     true
	)
	mut box2 := ui.Checkbox.new(text: 'Gridlines')
	box2.is_selected = app.settings.show_gridlines
	box2.set_bounds(0, 0, 100, 24)
	box2.subscribe_event('mouse_up', gridlines_item_click)

	grid_card.add_child(box2)

	panel.add_child(card)
	panel.add_child(theme_card)
	panel.add_child(round_card)
	panel.add_child(grid_card)

	// About Text

	mut lbl := ui.Label.new(
		text: 'About vPaint\n${about_text.join('\n')}\n'
	)
	lbl.pack()

	mut about_p := ui.Panel.new(layout: ui.FlowLayout.new(hgap: 10, vgap: 10))
	about_p.add_child(lbl)

	p.add_child(panel)
	p.add_child(about_p)

	p.subscribe_event('draw', fn (mut e ui.DrawEvent) {
		pw := e.ctx.gg.window_size().width
		tt := int(pw * f32(0.65))
		size := if pw < 800 { pw } else { tt }
		e.target.children[0].width = size - 10
	})

	page.add_child(p)
	app.win.add_child(page)
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
			mut theme := ui.theme_by_name(text)
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
