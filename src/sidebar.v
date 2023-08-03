module main

import iui as ui

fn sidebar_draw_event(mut e ui.DrawEvent) {
	// webasm build works better without closures
	mut app := e.ctx.win.get[&App]('app')

	app.sidebar.width = 64

	color := e.ctx.theme.menubar_background
	e.ctx.gg.draw_rect_filled(0, app.sidebar.ry, app.sidebar.width, app.sidebar.height,
		color)
}

fn (mut app App) make_sidebar() {
	// Sidebar
	app.sidebar.subscribe_event('draw', sidebar_draw_event)

	// Select
	img_sele_file := $embed_file('assets/select.png')
	mut test := app.icon_btn(img_sele_file.to_bytes(), &SelectTool{})

	// Pencil
	img_pencil_file := $embed_file('assets/pencil-tip.png')
	mut test2 := app.icon_btn(img_pencil_file.to_bytes(), &PencilTool{})

	// Fill
	img_fill_file := $embed_file('assets/fill-can.png')
	mut test3 := app.icon_btn(img_fill_file.to_bytes(), &FillTool{})

	// Drag
	img_drag_file := $embed_file('assets/icons8-drag-32.png')
	mut test4 := app.icon_btn(img_drag_file.to_bytes(), &DragTool{})

	// Drag
	img_resize_file := $embed_file('assets/resize.png')
	mut test5 := app.icon_btn(img_resize_file.to_bytes(), &SelectTool{})
	test5.set_click_fn(fn (win &ui.Window, b voidptr, c voidptr) {
		mut app := win.get[&App]('app')
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

	// Pencil
	img_wide_file := $embed_file('assets/icons8-pencil-drawing-32.png')
	mut test9 := app.icon_btn(img_wide_file.to_bytes(), &WidePencilTool{})

	mut hbox := ui.Panel.new()

	hbox.add_child(test)
	hbox.add_child(test2)
	hbox.add_child(test3)
	hbox.add_child(test4)
	hbox.add_child(test5)
	hbox.add_child(test6)
	hbox.add_child(test7)
	hbox.add_child(test8)
	hbox.add_child(test9)

	mut group := ui.buttongroup[ui.Button]()

	group.add(test)
	group.add(test2)
	group.add(test3)
	group.add(test4)
	group.add(test5)
	group.add(test6)
	group.add(test7)
	group.add(test8)
	group.add(test9)

	mut btns := [test, test2, test3, test4, test5, test6, test7, test8, test9]
	for mut b in btns {
		b.subscribe_event('after_draw', after_draw_btn)
	}

	group.subscribe_event('mouse_up', app.group_clicked)
	group.setup()

	app.sidebar.add_child(hbox)
}

fn after_draw_btn(mut e ui.DrawEvent) {
	if e.target.is_selected {
		mut btn := e.target
		for i in 1 .. 4 {
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

fn (mut app App) icon_btn(data []u8, tool &Tool) &ui.Button {
	mut gg := app.win.gg
	gg_im := gg.create_image_from_byte_array(data) or { panic(err) }
	cim := gg.cache_image(gg_im)
	mut btn := ui.button_with_icon(cim)

	btn.set_bounds(2, 0, 50, 32)
	btn.icon_width = 32

	btn.extra = tool.tool_name

	btn.set_click_fn(tool_btn_click, tool)
	return btn
}

fn tool_btn_click(winn voidptr, btn voidptr, tool &Tool) { //(mut app App)
	mut win := unsafe { &ui.Window(winn) }
	mut app := win.get[&App]('app')
	app.tool = unsafe { tool }
}
