module main

import iui as ui
import os

fn (mut app App) show_settings() {
	mut page := ui.Page.new(title: 'Settings')

	mut panel := ui.Panel.new(layout: ui.BoxLayout.new(ori: 1))

	mut box := ui.Checkbox.new(text: 'Auto-hide Sidebar')
	box.is_selected = app.settings.autohide_sidebar
	box.set_bounds(0, 0, 100, 24)
	box.subscribe_event('mouse_up', app.hide_sidebar_mouse_up)

	panel.add_child(box)

	page.add_child(panel)
	app.win.add_child(page)
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
		if spl[0] == 'theme' {
			text := spl[1].trim_space()
			mut theme := ui.theme_by_name(text)
			app.win.set_theme(theme)
			app.set_theme_bg(text)
			app.settings.theme = text
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

	mut txt := ['# VPaint Configuration File']
	txt << 'autohide_sidebar: ${app.settings.autohide_sidebar}'
	txt << 'theme: ${app.settings.theme}'

	os.write_file(file, txt.join('\n')) or { return err }

	if app.wasm_load_tick > 25 {
		wasm_save_files()
	}
}
