module main

import vpng
import gg
import iui as ui
import gx
import math

//
// Brush: RectangleShape
//
struct RectShape {
	name string = 'Rectangle'
mut:
	down_x        int
	down_y        int
	selected_area Box
}

fn (brush &RectShape) set_pixels(ptr voidptr, x int, y int, color vpng.TrueColorAlpha, size int) {
	mut storage := &KA(ptr)
	if storage.brush.down_x == -1 {
		storage.brush.down_x = x
		storage.brush.down_y = y
	}
}

fn (brush &RectShape) draw_hint(ptr voidptr, tx int, ty int, cx int, cy int, color gx.Color, size int) {
	mut win := &ui.Window(ptr)
	mut storage := &KA(win.id_map['pixels'])
	zoom := win.extra_map['zoom'].f32()

	down_x := storage.brush.down_x
	down_y := storage.brush.down_y

	mut x_slide := &ui.Slider(win.get_from_id('x_slide'))
	mut y_slide := &ui.Slider(win.get_from_id('y_slide'))

	if down_x == -1 {
		if mut storage.brush is RectShape {
			box := storage.brush.selected_area
			if zoom == box.zoom && box.x != -1 {
				win.gg.draw_rect_empty(box.x, box.y, box.w, box.h, gx.blue)

				tcolor := vpng.TrueColorAlpha{color.r, color.g, color.b, color.a}

				base_x := int(box.w / zoom)
				base_y := int(box.h / zoom)

				min_x := math.min(base_x, 0)
				max_x := math.max(0, base_x)

				min_y := math.min(base_y, 0)
				max_y := math.max(0, base_y)

				for i in min_x .. max_x {
					for j in min_y .. max_y {
						if (i == min_x || i == max_x - 1) || j == min_y || j == max_y - 1 {
							storage.file.set_pixel(box.x + i, box.y + j, tcolor)
						}
					}
				}

				// Update Canvas
				make_gg_image(mut storage, mut win, false)

				storage.brush.selected_area = Box{}
			}
		}
		return
	}

	bx := int(down_x * zoom) + tx - int(x_slide.cur)
	by := int(down_y * zoom) + ty - int(y_slide.cur)

	hei := win.mouse_y - by
	wid := win.mouse_x - bx

	if mut storage.brush is RectShape {
		if bx > tx && by > ty {
			storage.brush.selected_area = Box{storage.brush.down_x, storage.brush.down_y, wid, hei, zoom}
		}
	}

	if bx > tx && by > ty {
		win.draw_filled_rect(bx, by, wid, hei, 0, gx.rgba(0, 0, 0, 0), gx.black)
	} else {
		storage.brush.down_x = -1
	}
}

//
// Brush: SquareShape
//
struct SquareShape {
	name string = 'Square'
mut:
	down_x        int
	down_y        int
	selected_area Box
}

fn (brush &SquareShape) set_pixels(ptr voidptr, x int, y int, color vpng.TrueColorAlpha, size int) {
	mut storage := &KA(ptr)
	if storage.brush.down_x == -1 {
		storage.brush.down_x = x
		storage.brush.down_y = y
	}
}

fn (brush &SquareShape) draw_hint(ptr voidptr, tx int, ty int, cx int, cy int, color gx.Color, size int) {
	mut win := &ui.Window(ptr)
	mut storage := &KA(win.id_map['pixels'])
	zoom := win.extra_map['zoom'].f32()

	down_x := storage.brush.down_x
	down_y := storage.brush.down_y

	mut x_slide := &ui.Slider(win.get_from_id('x_slide'))
	mut y_slide := &ui.Slider(win.get_from_id('y_slide'))

	if down_x == -1 {
		if mut storage.brush is SquareShape {
			box := storage.brush.selected_area
			if zoom == box.zoom && box.x != -1 {
				win.gg.draw_rect_empty(box.x, box.y, box.w, box.h, gx.blue)

				tcolor := vpng.TrueColorAlpha{color.r, color.g, color.b, color.a}

				base_x := int(box.w / zoom)
				base_y := int(box.h / zoom)

				min_x := math.min(base_x, 0)
				max_x := math.max(0, base_x)

				min_y := math.min(base_y, 0)
				max_y := math.max(0, base_y)

				for i in min_x .. max_x {
					for j in min_y .. max_y {
						if (i == min_x || i == max_x - 1) || j == min_y || j == max_y - 1 {
							storage.file.set_pixel(box.x + i, box.y + j, tcolor)
						}
					}
				}

				// Update Canvas
				make_gg_image(mut storage, mut win, false)

				storage.brush.selected_area = Box{}
			}
		}
		return
	}

	bx := int(down_x * zoom) + tx - int(x_slide.cur)
	by := int(down_y * zoom) + ty - int(y_slide.cur)

	hei := win.mouse_y - by
	wid := win.mouse_x - bx

	mut width := math.abs(math.min(wid, hei))
	mut height := math.abs(math.min(wid, hei))

	if wid < 0 {
		width = -width
	}
	if hei < 0 {
		height = -height
	}

	if mut storage.brush is SquareShape {
		if bx > tx && by > ty {
			storage.brush.selected_area = Box{storage.brush.down_x, storage.brush.down_y, width, height, zoom}
		}
	}

	if bx > tx && by > ty {
		win.draw_filled_rect(bx, by, width, height, 0, gx.rgba(0, 0, 0, 0), gx.black)
	} else {
		storage.brush.down_x = -1
	}
}

//
// Brush: LineShape
//
struct LineShape {
	name string = 'Line'
mut:
	down_x        int
	down_y        int
	selected_area Box
}

fn (brush &LineShape) set_pixels(ptr voidptr, x int, y int, color vpng.TrueColorAlpha, size int) {
	mut storage := &KA(ptr)
	if storage.brush.down_x == -1 {
		storage.brush.down_x = x
		storage.brush.down_y = y
	}
}

fn (brush &LineShape) draw_hint(ptr voidptr, tx int, ty int, cx int, cy int, color gx.Color, size int) {
	mut win := &ui.Window(ptr)
	mut storage := &KA(win.id_map['pixels'])
	zoom := win.extra_map['zoom'].f32()

	down_x := storage.brush.down_x
	down_y := storage.brush.down_y

	mut x_slide := &ui.Slider(win.get_from_id('x_slide'))
	mut y_slide := &ui.Slider(win.get_from_id('y_slide'))

	if down_x == -1 {
		if mut storage.brush is LineShape {
			box := storage.brush.selected_area
			if zoom == box.zoom && box.x != -1 {
				tcolor := vpng.TrueColorAlpha{color.r, color.g, color.b, color.a}

				base_x := int(box.w / zoom)
				base_y := int(box.h / zoom)

				min_x := math.min(base_x, 0)
				max_x := math.max(0, base_x)

				min_y := math.min(base_y, 0)
				max_y := math.max(0, base_y)

				real_y := box.y + base_y
				real_x := box.x + base_x

				// Calculate slope
				// m = (y2 - y1) / (x2 - x1)
				point_slope := f32(real_y - box.y) / (real_x - box.x)

				// b = y1 - (m * x1)
				b := real_y - (point_slope * real_x)

				for i in min_x .. max_x {
					x_val := box.x + i

					// y = mx + b
					y_form := int((point_slope * x_val) + b)

					storage.file.set_pixel(x_val, y_form, tcolor)
					for j in (0 - (size / 2)) .. size / 2 {
						storage.file.set_pixel(x_val, y_form + j, tcolor)
					}
				}

				// Update Canvas
				make_gg_image(mut storage, mut win, false)

				storage.brush.selected_area = Box{}
			}
		}
		return
	}

	bx := int(down_x * zoom) + tx - int(x_slide.cur)
	by := int(down_y * zoom) + ty - int(y_slide.cur)

	hei := win.mouse_y - by
	wid := win.mouse_x - bx

	if mut storage.brush is LineShape {
		if bx > tx && by > ty {
			storage.brush.selected_area = Box{storage.brush.down_x, storage.brush.down_y, wid, hei, zoom}
		}
	}

	if bx > tx && by > ty {
		win.gg.draw_line(bx, by, win.mouse_x, win.mouse_y, gx.black)
	} else {
		storage.brush.down_x = -1
	}
}
