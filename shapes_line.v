module main

import gg
import iui as ui
import gx
import math

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

fn (brush &LineShape) set_pixels(ptr voidptr, x int, y int, color gx.Color, size int) {
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

	x_slide := &ui.Slider(win.get_from_id('x_slide'))
	y_slide := &ui.Slider(win.get_from_id('y_slide'))

	rele := down_x == -1

	if mut storage.brush is LineShape {
		box := storage.brush.selected_area
		if zoom == box.zoom && box.x != -1 {
			tcolor := gx.Color{color.r, color.g, color.b, color.a}

			base_x := int(box.w / zoom)
			base_y := int(box.h / zoom)

			min_x := math.min(base_x, 0)
			max_x := math.max(0, base_x)

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

				if rele {
					set_pixel(storage.file, x_val, y_form, tcolor)
					for j in (0 - (size / 2)) .. size / 2 {
						set_pixel(storage.file, x_val, y_form + j, tcolor)
					}
				} else {
					draw_x := tx + (x_val * zoom) - int(x_slide.cur)
					draw_y := ty + (y_form * zoom) - int(y_slide.cur)

					win.gg.draw_rect_filled(draw_x, draw_y, zoom, zoom, color)
					for j in (0 - (size / 2)) .. size / 2 {
						draw_y_ := ty + ((y_form + j) * zoom) - int(y_slide.cur)
						win.gg.draw_rect_filled(draw_x, draw_y_, zoom, zoom, color)
					}
				}
			}

			// Update Canvas
			if rele {
				make_gg_image(mut storage, mut win, false)
				storage.brush.selected_area = Box{}
			}
		}
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
	} else {
		storage.brush.down_x = -1
	}
}
