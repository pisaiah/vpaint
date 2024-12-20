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
	w := if h > 180 { 46 } else { 104 }

	color := e.ctx.theme.textbox_background
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
		'Select' {
			app.tool = &SelectTool{}
		}
		'Pencil' {
			app.tool = &PencilTool{}
		}
		'Fill', 'Fillcan' {
			app.tool = &FillTool{}
		}
		'Drag' {
			app.tool = &DragTool{}
		}
		'Airbrush' {
			app.tool = &AirbrushTool{}
		}
		'Dropper', 'Eye Dropper' {
			app.tool = &DropperTool{}
		}
		'WidePencil' {
			app.tool = &CustomPencilTool{
				width:  0
				height: 2
			}
		}
		'CustomPencil' {
			app.tool = &CustomPencilTool{}
		}
		'Line' {
			app.tool = &LineTool{}
		}
		'Rectangle' {
			app.tool = &RectTool{}
		}
		'Oval', 'Circle' {
			app.tool = &OvalTool{}
		}
		else {
			app.tool = &PencilTool{}
		}
	}
}

fn (mut app App) make_sidebar() {
	// Sidebar
	app.sidebar.subscribe_event('draw', sidebar_draw_event)

	// icons
	img_icon_file := $embed_file('assets/tools.png')
	mut gg := app.win.gg
	gg_im := gg.create_image_from_byte_array(img_icon_file.to_bytes()) or { panic(err) }
	cim := gg.cache_image(gg_im)
	app.win.graphics_context.icon_cache['icons-3'] = cim

	/*
	img_sele_file := $embed_file('assets/select.png')
	img_pencil_file := $embed_file('assets/pencil-tip.png')
	img_fill_file := $embed_file('assets/fill-can.png')
	img_drag_file := $embed_file('assets/icons8-drag-32.png')
	img_resize_file := $embed_file('assets/resize.png')
	img_airbrush_file := $embed_file('assets/icons8-paint-sprayer-32.png')
	img_dropper_file := $embed_file('assets/color-dropper.png')
	img_wide_file := $embed_file('assets/icons8-pencil-drawing-32.png')
	*/

	// Buttons
	mut b0 := app.icon_btn_1(0, 0, 'Select')
	mut b1 := app.icon_btn_1(1, 0, 'Pencil')
	mut b2 := app.icon_btn_1(2, 0, 'Fill')
	mut b3 := app.icon_btn_1(3, 0, 'Drag')
	mut b4 := app.icon_btn_1(4, 0, 'Resize Canvas')
	mut b5 := app.icon_btn_1(5, 0, 'Airbrush')
	mut b6 := app.icon_btn_1(6, 0, 'Dropper')
	mut b7 := app.icon_btn_1(7, 0, 'WidePencil')

	b4.subscribe_event('mouse_up', fn [mut app] (mut e ui.MouseEvent) {
		app.show_resize_modal(app.canvas.w, app.canvas.h)
	})

	mut p := ui.Panel.new(
		layout: ui.FlowLayout.new(
			hgap: 1
			vgap: 2
		)
	)

	mut group := ui.buttongroup[ui.Button]()

	for child in [b0, b1, b2, b3, b4, b5, b6, b7] {
		p.add_child(child)
		group.add(child)
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
		for i in 1 .. 2 {
			x := btn.x + i
			y := btn.y + i
			w := btn.width - (2 * i)
			h := btn.height - (2 * i)
			e.ctx.gg.draw_rect_empty(x, y, w, h, e.ctx.theme.accent_fill)
		}
	}
}

fn (mut app App) group_clicked(mut e ui.MouseEvent) {
}

fn (mut app App) icon_btn_1(xp int, yp int, name string) &ui.Button {
	mut btn := ui.Button.new(
		icon: -3
	)

	btn.icon_info = ui.ButtonIconInfo{
		id:         'icons-3'
		atlas_size: 32
		x:          xp
		y:          yp
		skip_text:  true
	}

	btn.set_bounds(0, 0, 42, 32)

	btn.icon_width = 32
	btn.icon_height = 32

	btn.set_area_filled(false)
	btn.border_radius = -1

	btn.extra = name // tool.tool_name
	btn.text = name

	btn.subscribe_event('after_draw', after_draw_btn)
	btn.subscribe_event('draw', draw_btn)

	btn.subscribe_event('mouse_up', fn [mut app] (mut e ui.MouseEvent) {
		// Note: debug this.
		// seems my closure impl for emscripten always returns
		// the last 'name' instead of the real name.
		app.set_tool_by_name(e.target.text)
	})
	return btn
}

fn (mut app App) icon_btn(data []u8, name string) &ui.Button {
	mut gg := app.win.gg
	gg_im := gg.create_image_from_byte_array(data) or { panic(err) }
	cim := gg.cache_image(gg_im)
	mut btn := ui.Button.new(icon: cim)
	btn.set_bounds(0, 0, 42, 32)
	btn.icon_width = 32

	btn.set_area_filled(false)
	btn.border_radius = -1

	btn.extra = name // tool.tool_name
	btn.text = name

	btn.subscribe_event('after_draw', after_draw_btn)
	btn.subscribe_event('draw', draw_btn)

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
