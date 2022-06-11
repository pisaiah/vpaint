module main

import gg
import iui as ui
import gx

//
// Brush: Eyedrop
//
struct ColorDropper {
	name string = 'Dropper'
mut:
	down_x int
	down_y int
}

fn (brush ColorDropper) set_pixels(ptr voidptr, x int, y int, color gx.Color, size int) {
	mut canvas := &KA(ptr)

	down_color := get_pixel(x, y, mut canvas.file)

	canvas.color = down_color
}

fn (brush ColorDropper) draw_hint(ptr voidptr, tx int, ty int, cx int, cy int, color gx.Color, size int) {
	mut win := &ui.Window(ptr)
	zoom := win.extra_map['zoom'].f32()
	wid := (size / 2) * zoom

	win.gg.draw_rect_empty(tx + (cx * zoom) - wid, ty + (cy * zoom) - wid, zoom, zoom,
		gx.blue)
}
