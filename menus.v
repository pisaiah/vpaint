module main

import iui as ui

fn make_brush_menu(mut win ui.Window) {
	mut bm := ui.menuitem('Brush')

	mut pencil := ui.menuitem('Pencil')
	pencil.set_click(fn (mut win ui.Window, com ui.MenuItem) {
		mut pixels := &KA(win.id_map['pixels'])
		pixels.brush = PencilBrush{}
	})
	bm.add_child(pencil)

	mut calli := ui.menuitem('Calligraphy Brush (Right)')
	calli.set_click(fn (mut win ui.Window, com ui.MenuItem) {
		mut pixels := &KA(win.id_map['pixels'])
		pixels.brush = CalligraphyBrush{}
	})
	bm.add_child(calli)

	mut calli_ := ui.menuitem('Calligraphy Brush (Left)')
	calli_.set_click(fn (mut win ui.Window, com ui.MenuItem) {
		mut pixels := &KA(win.id_map['pixels'])
		pixels.brush = CalligraphyBrushLeft{}
	})
	bm.add_child(calli_)

	mut spray := ui.menuitem('Spraycan Brush')
	spray.set_click(fn (mut win ui.Window, com ui.MenuItem) {
		mut pixels := &KA(win.id_map['pixels'])
		pixels.brush = SpraycanBrush{}
	})
	bm.add_child(spray)

	// testing
	mut test := ui.menuitem('Testing of Select')
	test.set_click(fn (mut win ui.Window, com ui.MenuItem) {
		mut pixels := &KA(win.id_map['pixels'])
		pixels.brush = SelectionTool{}
	})
	bm.add_child(test)

	win.bar.add_child(bm)
}

fn make_draw_size_menu(mut win ui.Window) {
	mut mz := ui.menuitem('Size')

	for i in 1 .. 16 {
		mut zoomm := draw_size_item(i)
		if i % 2 == 0 || i <= 4 {
			mz.add_child(zoomm)
		}
	}

	mut zoomm := draw_size_item(99)
	mz.add_child(zoomm)

	win.bar.add_child(mz)
}

fn draw_size_item(ds int) &ui.MenuItem {
	mut item := ui.menuitem(ds.str() + 'px')
	item.set_click(fn (mut win ui.Window, com ui.MenuItem) {
		mut storage := &KA(win.id_map['pixels'])
		storage.draw_size = com.text.replace('px', '').int()
	})
	return item
}
