module main

import vpng
import gg
import iui as ui
import gx

//
// Brushes
//
interface Brush {
	name string
	set_pixels(voidptr, int, int, vpng.TrueColorAlpha, int)
	draw_hint(voidptr, int, int, int, int, gx.Color, int)
}

//
// Brush: Calligraphy Brush (Left)
//
struct CalligraphyBrushLeft {
	name string = 'Calligraphy Brush'
}

fn (brush &CalligraphyBrushLeft) set_pixels(ptr voidptr, x int, y int, color vpng.TrueColorAlpha, size int) {
	mut pixels := &KA(ptr)
	for i in 0 .. size {
		pixels.file.set_pixel(x + i, y - i, color)
		pixels.file.set_pixel(x - i, y + i, color)
	}
}

fn (brush &CalligraphyBrushLeft) draw_hint(ptr voidptr, tx int, ty int, cx int, cy int, color gx.Color, size int) {
	mut win := &ui.Window(ptr)
	zoom := win.extra_map['zoom'].f32()
	for i in 0 .. size {
		win.gg.draw_rect_empty(tx + ((cx + i) * zoom), ty + ((cy - i) * zoom), zoom, zoom,
			gx.blue)
		win.gg.draw_rect_empty(tx + ((cx - i) * zoom), ty + ((cy + i) * zoom), zoom, zoom,
			gx.blue)
	}
}

//
// Brush: Calligraphy Brush (Right)
//
struct CalligraphyBrush {
	name string = 'Calligraphy Brush'
}

fn (brush &CalligraphyBrush) set_pixels(ptr voidptr, x int, y int, color vpng.TrueColorAlpha, size int) {
	mut pixels := &KA(ptr)
	for i in 0 .. size {
		pixels.file.set_pixel(x - i, y - i, color)
		pixels.file.set_pixel(x + i, y + i, color)
	}
}

fn (brush &CalligraphyBrush) draw_hint(ptr voidptr, tx int, ty int, cx int, cy int, color gx.Color, size int) {
	mut win := &ui.Window(ptr)
	zoom := win.extra_map['zoom'].f32()
	for i in 0 .. size {
		win.gg.draw_rect_empty(tx + ((cx - i) * zoom), ty + ((cy - i) * zoom), zoom, zoom,
			gx.blue)
		win.gg.draw_rect_empty(tx + ((cx + i) * zoom), ty + ((cy + i) * zoom), zoom, zoom,
			gx.blue)
	}
}

//
// Brush: Pencil
//
struct PencilBrush {
	name string = 'Pencil'
}

fn (brush PencilBrush) set_pixels(ptr voidptr, x int, y int, color vpng.TrueColorAlpha, size int) {
	mut pixels := &KA(ptr)
	for i in 0 .. size {
		for j in 0 .. size {
			pixels.file.set_pixel(x + i, y + j, color)
		}
	}
}

fn (brush PencilBrush) draw_hint(ptr voidptr, tx int, ty int, cx int, cy int, color gx.Color, size int) {
	mut win := &ui.Window(ptr)
	zoom := win.extra_map['zoom'].f32()
	for i in 0 .. size {
		for j in 0 .. size {
			win.gg.draw_rect_empty(tx + ((cx + i) * zoom), ty + ((cy + j) * zoom), zoom,
				zoom, gx.blue)
		}
	}
}
