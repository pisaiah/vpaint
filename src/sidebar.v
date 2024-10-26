module main

import iui as ui

fn (mut app App) sidebar_autohide_draw(w int) {
	move := 3
	hidden_size := 6

	if app.win.mouse_x < app.sidebar.width + (hidden_size * 2) && app.win.mouse_y > app.sidebar.ry {
		if app.sidebar.width < w {
			app.sidebar.width += move
			app.sidebar.children[0].set_hidden(false)
		}
	} else {
		if app.sidebar.width > hidden_size {
			app.sidebar.width -= move
		} else {
			app.sidebar.width = hidden_size
			app.sidebar.children[0].set_hidden(true)
		}
	}
	app.sidebar.children[0].x = app.sidebar.width - w
}

fn sidebar_draw_event(mut e ui.DrawEvent) {
	// webasm build works better without closures
	mut app := e.ctx.win.get[&App]('app')

	$if emscripten ? {
		if app.wasm_load_tick < 25 {
			app.wasm_load_tick += 1
		}

		if app.wasm_load_tick > 5 && app.wasm_load_tick < 10 {
			println('Wasm detected. Loading local storage.')
			wasm_load_files()
			app.wasm_load_tick = 10
		}

		if app.wasm_load_tick > 20 && app.wasm_load_tick < 26 {
			// Load Settings after a few ticks
			// for some reason, Emscripten will crash if FS is called without this.
			println('Wasm detected. Reloading settings...')
			app.settings_load() or {}
			app.wasm_load_tick = 28
			app.settings_save() or {}
		}
	}

	h := app.sidebar.height
	w := if h > 180 { 54 } else { 104 }

	color := e.ctx.theme.menubar_background
	e.ctx.gg.draw_rect_filled(0, app.sidebar.ry, app.sidebar.width, app.sidebar.height,
		color)

	if app.settings.autohide_sidebar {
		app.sidebar_autohide_draw(w)
		return
	}

	if app.sidebar.children[0].hidden {
		app.sidebar.children[0].set_hidden(false)
	}

	app.sidebar.width = w
	app.sidebar.children[0].x = 0
	app.sidebar.children[0].width = w
}

fn (mut app App) set_tool_by_name(name string) {
	match name {
		'Select' { app.tool = &SelectTool{} }
		'Pencil' { app.tool = &PencilTool{} }
		'Fill' { app.tool = &FillTool{} }
		'Drag' { app.tool = &DragTool{} }
		'Airbrush' { app.tool = &AirbrushTool{} }
		'Dropper' { app.tool = &DropperTool{} }
		'WidePencil' { app.tool = &WidePencilTool{} }
		'Line' { app.tool = &LineTool{} }
		'Rectangle' { app.tool = &RectTool{} }
		else { app.tool = &PencilTool{} }
	}
}

fn (mut app App) make_sidebar() {
	// Sidebar
	app.sidebar.subscribe_event('draw', sidebar_draw_event)

	img_sele_file := $embed_file('assets/select.png')
	img_pencil_file := $embed_file('assets/pencil-tip.png')
	img_fill_file := $embed_file('assets/fill-can.png')
	img_drag_file := $embed_file('assets/icons8-drag-32.png')
	img_resize_file := $embed_file('assets/resize.png')
	img_airbrush_file := $embed_file('assets/icons8-paint-sprayer-32.png')
	img_dropper_file := $embed_file('assets/color-dropper.png')
	img_wide_file := $embed_file('assets/icons8-pencil-drawing-32.png')

	// Buttons
	mut test := app.icon_btn(img_sele_file.to_bytes(), 'Select')
	mut test2 := app.icon_btn(img_pencil_file.to_bytes(), 'Pencil')
	mut test3 := app.icon_btn(img_fill_file.to_bytes(), 'Fill')
	mut test4 := app.icon_btn(img_drag_file.to_bytes(), 'Drag')
	mut test5 := app.icon_btn(img_resize_file.to_bytes(), 'Select')
	mut test7 := app.icon_btn(img_airbrush_file.to_bytes(), 'Airbrush')
	mut test8 := app.icon_btn(img_dropper_file.to_bytes(), 'Dropper')
	mut test9 := app.icon_btn(img_wide_file.to_bytes(), 'WidePencil')

	// Pencil
	// img_pencil_file2 := $embed_file('assets/icons8-pencil-drawing-32.png')
	// mut test6 := app.icon_btn(img_pencil_file2.to_bytes(), &PencilTool2{})

	test5.subscribe_event('mouse_up', fn [mut app] (mut e ui.MouseEvent) {
		app.show_resize_modal(app.canvas.w, app.canvas.h)
	})

	mut p := ui.Panel.new(
		layout: ui.FlowLayout.new(
			hgap: 1
			vgap: 2
		)
	)

	p.add_child(test)
	p.add_child(test2)
	p.add_child(test3)
	p.add_child(test4)
	p.add_child(test5)
	p.add_child(test7)
	p.add_child(test8)
	p.add_child(test9)

	mut group := ui.buttongroup[ui.Button]()

	group.add(test)
	group.add(test2)
	group.add(test3)
	group.add(test4)
	group.add(test5)
	group.add(test7)
	group.add(test8)
	group.add(test9)

	mut btns := [test, test2, test3, test4, test5, test7, test8, test9]
	for mut b in btns {
		b.subscribe_event('after_draw', after_draw_btn)
		b.subscribe_event('draw', draw_btn)
	}

	group.subscribe_event('mouse_up', app.group_clicked)
	group.setup()

	app.sidebar.add_child(p)
}

fn draw_btn(mut e ui.DrawEvent) {
	mut btn := e.target
	if mut btn is ui.Button {
		btn.set_area_filled(e.target.is_selected)
	}
}

fn after_draw_btn(mut e ui.DrawEvent) {
	if e.target.is_selected {
		mut btn := e.target
		for i in 1 .. 3 {
			x := btn.x + i
			y := btn.y + i
			w := btn.width - (2 * i)
			h := btn.height - (2 * i)
			e.ctx.gg.draw_rect_empty(x, y, w, h, e.ctx.theme.button_border_hover)
		}
	}
}

fn (mut app App) group_clicked(mut e ui.MouseEvent) {
}

fn (mut app App) icon_btn(data []u8, name string) &ui.Button {
	mut gg := app.win.gg
	gg_im := gg.create_image_from_byte_array(data) or { panic(err) }
	cim := gg.cache_image(gg_im)
	mut btn := ui.Button.new(icon: cim)
	btn.set_bounds(2, 0, 46, 32)
	btn.icon_width = 32

	btn.set_area_filled(false)
	btn.border_radius = -1

	btn.extra = name // tool.tool_name
	btn.text = name

	btn.subscribe_event('mouse_up', fn [mut app] (mut e ui.MouseEvent) {
		// Note: debug this.
		// seems my closure impl for emscripten always returns
		// the last 'name' instead of the real name.
		app.set_tool_by_name(e.target.text)
	})
	return btn
}

fn (mut app App) icon_btn_old(data []u8, tool &Tool) &ui.Button {
	mut gg := app.win.gg
	gg_im := gg.create_image_from_byte_array(data) or { panic(err) }
	cim := gg.cache_image(gg_im)
	mut btn := ui.Button.new(icon: cim)
	btn.set_bounds(2, 0, 46, 32)
	btn.icon_width = 32

	btn.set_area_filled(false)
	btn.border_radius = -1

	btn.extra = tool.tool_name

	btn.subscribe_event('mouse_up', fn [mut app, tool] (mut e ui.MouseEvent) {
		app.tool = unsafe { tool }
	})
	return btn
}
