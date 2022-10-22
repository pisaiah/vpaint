module main

import iui as ui

fn sidebar_draw_event(win &ui.Window, com &ui.Component) { //(mut app App)
	// webasm build works better without closures
	mut app := &App(win.id_map['app'])

	ws := win.gg.window_size()
	y := 90
	app.sidebar.set_bounds(0, y, 70, ws.height - y - 29)
	color := win.theme.menubar_background
	win.gg.draw_rect_filled(0, y, app.sidebar.width, app.sidebar.height, color)
}

fn (mut app App) make_sidebar(mut sidebar ui.HBox) {
	// Sidebar
	sidebar.draw_event_fn = sidebar_draw_event

	// Select
	img_sele_file := $embed_file('assets/icons8-select-none-32.png')
	mut test := app.icon_btn(img_sele_file.to_bytes(), &SelectTool{})

	// Pencil
	img_pencil_file := $embed_file('assets/pencil-tip.png')
	mut test2 := app.icon_btn(img_pencil_file.to_bytes(), &PencilTool{})

	// Fill
	img_fill_file := $embed_file('assets/icons8-fill-color-32-2.png')
	mut test3 := app.icon_btn(img_fill_file.to_bytes(), &FillTool{})

	// Drag
	img_drag_file := $embed_file('assets/icons8-drag-32.png')
	mut test4 := app.icon_btn(img_drag_file.to_bytes(), &DragTool{})

	// Drag
	img_resize_file := $embed_file('assets/resize.png')
	mut test5 := app.icon_btn(img_resize_file.to_bytes(), &SelectTool{})
	test5.set_click_fn(fn (win &ui.Window, b voidptr, c voidptr) {
		mut app := &App(win.id_map['app'])
		app.show_resize_modal(app.canvas.w, app.canvas.h)
	}, 0)

	// Pencil
	img_pencil_file2 := $embed_file('assets/icons8-pencil-drawing-32.png')
	mut test6 := app.icon_btn(img_pencil_file2.to_bytes(), &PencilTool2{})

	// Airbrush
	img_airbrush_file := $embed_file('assets/icons8-paint-sprayer-32.png')
	mut test7 := app.icon_btn(img_airbrush_file.to_bytes(), &AirbrushTool{})

	// Eye Dropper
	img_dropper_file := $embed_file('assets/color-dropper.png')
	mut test8 := app.icon_btn(img_dropper_file.to_bytes(), &DropperTool{})

	mut hbox := ui.hbox(app.win)
	off := 16
	hbox.set_bounds(off, 16, 70 - off, 40 * 3)

	hbox.add_child(test)
	hbox.add_child(test2)
	hbox.add_child(test3)
	hbox.add_child(test4)
	hbox.add_child(test5)
	hbox.add_child(test6)
	hbox.add_child(test7)
	hbox.add_child(test8)
	sidebar.add_child(hbox)
}

fn (mut app App) icon_btn(data []u8, tool &Tool) &ui.Button {
	mut gg := app.win.gg
	gg_im := gg.create_image_from_byte_array(data)
	cim := gg.cache_image(gg_im)
	mut btn := ui.button_with_icon(cim)

	btn.set_bounds(2, 4, 32, 32)

	btn.set_click_fn(tool_btn_click, tool)
	return btn
}

fn tool_btn_click(winn voidptr, btn voidptr, tool &Tool) { //(mut app App)
	mut win := &ui.Window(winn)
	mut app := &App(win.id_map['app'])
	app.tool = unsafe { tool }
}
