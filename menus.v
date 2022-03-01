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

	win.bar.add_child(bm)
}

fn make_draw_size_menu(mut win ui.Window) {
	mut mz := ui.menuitem('Size')

	for i in 1 .. 10 {
		mut zoomm := draw_size_item(i)
		mz.add_child(zoomm)
	}

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
