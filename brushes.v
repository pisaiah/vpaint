module main

import vpng
import gg
import iui as ui
import gx
import rand

//
// Brushes
//
interface Brush {
	name string
	set_pixels(voidptr, int, int, vpng.TrueColorAlpha, int)
	draw_hint(voidptr, int, int, int, int, gx.Color, int)
mut:
	down_x int
	down_y int
}

//
// Brush: Calligraphy Brush (Left)
//
struct CalligraphyBrushLeft {
	name string = 'Calligraphy Brush'
mut:
	down_x int
	down_y int
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
mut:
	down_x int
	down_y int
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
mut:
	down_x int
	down_y int
}

fn (brush PencilBrush) set_pixels(ptr voidptr, x int, y int, color vpng.TrueColorAlpha, size int) {
	mut pixels := &KA(ptr)
	wid := size / 2

	for i in 0 .. size {
		for j in 0 .. size {
			xx := x + i - wid
			yy := y + j - wid
			if xx >= 0 && yy >= 0 && xx <= pixels.width {
				if size < 4 || (!(j == size - 1 && i == size - 1) && !(j == size - 1 && i == 0)
					&& !(j == 0 && i == 0) && !(j == 0 && i == size - 1)) {
					if xx < pixels.width && yy < pixels.height {
						pixels.file.set_pixel(xx, yy, color)
					}
				}
			}
		}
	}
}

fn (brush PencilBrush) draw_hint(ptr voidptr, tx int, ty int, cx int, cy int, color gx.Color, size int) {
	mut win := &ui.Window(ptr)
	zoom := win.extra_map['zoom'].f32()
	wid := (size / 2) * zoom
	for i in 0 .. size {
		for j in 0 .. size {
			if size < 4 || (!(j == size - 1 && i == size - 1) && !(j == size - 1 && i == 0)
				&& !(j == 0 && i == 0) && !(j == 0 && i == size - 1)) {
				win.gg.draw_rect_empty(tx + ((cx + i) * zoom) - wid, ty + ((cy + j) * zoom) - wid,
					zoom, zoom, gx.blue)
			}
		}
	}
}

//
// Brush: Spraycan
//
struct SpraycanBrush {
	name string = 'Spraycan'
mut:
	down_x int
	down_y int
}

fn (brush SpraycanBrush) set_pixels(ptr voidptr, x int, y int, color vpng.TrueColorAlpha, size int) {
	mut pixels := &KA(ptr)
	wid := size / 2

	for i in 0 .. size {
		for j in 0 .. size {
			xx := x + i - wid
			yy := y + j - wid

			rand_int := rand.intn(size) or { -1 }

			if xx >= 0 && yy >= 0 && xx <= pixels.width && yy <= pixels.height {
				if size < 4 || (!(j == size - 1 && i == size - 1) && !(j == size - 1 && i == 0)
					&& !(j == 0 && i == 0) && !(j == 0 && i == size - 1)) {
					if rand_int == 0 {
						pixels.file.set_pixel(xx, yy, color)
					}
				}
			}
		}
	}
}

fn (brush SpraycanBrush) draw_hint(ptr voidptr, tx int, ty int, cx int, cy int, color gx.Color, size int) {
	mut win := &ui.Window(ptr)
	zoom := win.extra_map['zoom'].f32()
	wid := (size / 2) * zoom
	for i in 0 .. size {
		for j in 0 .. size {
			rand_int := rand.intn(size) or { -1 }

			if size < 4 || (!(j == size - 1 && i == size - 1) && !(j == size - 1 && i == 0)
				&& !(j == 0 && i == 0) && !(j == 0 && i == size - 1)) {
				if rand_int == 0 {
					win.gg.draw_rect_empty(tx + ((cx + i) * zoom) - wid, ty + ((cy + j) * zoom) - wid,
						zoom, zoom, gx.blue)
				}
			}
		}
	}
}

//
// Testing of Selction
// (note: seperate brushes & tools ?)
//
struct SelectionTool {
	name string = 'Selection'
mut:
	down_x        int = -1
	down_y        int = -1
	selected_area Box
}

struct Box {
	x    int = -1
	y    int
	w    int
	h    int
	zoom f32
}

fn (brush &SelectionTool) set_pixels(ptr voidptr, x int, y int, color vpng.TrueColorAlpha, size int) {
	mut storage := &KA(ptr)
	if storage.brush.down_x == -1 {
		storage.brush.down_x = x
		storage.brush.down_y = y
	}
}

fn (brush &SelectionTool) draw_hint(ptr voidptr, tx int, ty int, cx int, cy int, color gx.Color, size int) {
	mut win := &ui.Window(ptr)
	mut storage := &KA(win.id_map['pixels'])
	zoom := win.extra_map['zoom'].f32()

	if storage.brush.down_x == -1 {
		if mut storage.brush is SelectionTool {
			box := storage.brush.selected_area
			if zoom == box.zoom && box.x != -1 {
				win.gg.draw_rect_empty(box.x, box.y, box.w, box.h, gx.blue)
			}
		}
		return
	}

	wid := int((cx * zoom) - (storage.brush.down_x * zoom))
	hei := int((cy * zoom) - (storage.brush.down_y * zoom))

	bx := int(tx + (storage.brush.down_x * zoom))
	by := int(ty + (storage.brush.down_y * zoom))

	if mut storage.brush is SelectionTool {
		if bx > tx && by > ty {
			storage.brush.selected_area = Box{int(bx), int(by), int(wid), int(hei), zoom}
		}
	}

	if bx > tx && by > ty {
		win.draw_filled_rect(bx, by, wid, hei, 0, gx.rgba(173, 216, 230, 99), gx.blue)
	} else {
		storage.brush.down_x = -1
	}
}
