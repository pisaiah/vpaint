module main

import vpng
import gg
import iui as ui
import gx

//
// Brush: Spraycan
//
struct FillBrush {
	name string = 'FillBrush'
mut:
	down_x int
	down_y int
}

fn (brush FillBrush) set_pixels(ptr voidptr, x int, y int, color vpng.TrueColorAlpha, size int) {
	mut pixels := &KA(ptr)

	down_color := get_pixel(x, y, mut pixels.file)

	check_pix(x, y, mut pixels, down_color, color)
}

// TODO: Optimize, improve.
fn check_pix(x int, y int, mut storage KA, down_color vpng.Pixel, color vpng.TrueColorAlpha) []int {
	mut arr := []int{}
	if x < 0 || y < 0 {
		return arr
	}
	if x > storage.width || y > storage.height {
		return arr
	}

	main := get_pixel(x, y, mut storage.file)

	if main != down_color {
		return arr
	}

	mut yy := y
	for yy > 0 {
		should_continue := do_y(x, yy, mut storage, down_color, color)
		if !should_continue {
			break
		}
		yy -= 1
	}

	yy = y + 1
	for yy > 0 {
		should_continue := do_y(x, yy, mut storage, down_color, color)
		if !should_continue {
			break
		}
		yy += 1
	}

	return arr
}

fn do_y(x int, yy int, mut storage KA, down_color vpng.Pixel, color vpng.TrueColorAlpha) bool {
	main_ := get_pixel(x, yy, mut storage.file)

	if main_ == down_color {
		storage.file.set_pixel(x, yy, color)

		mut xx := x - 1
		for xx > 0 {
			mut color_ := get_pixel(xx, yy, mut storage.file)
			if color_ == down_color {
				storage.file.set_pixel(xx, yy, color)
			} else {
				break
			}
			xx -= 1
		}

		xx = x + 1
		for xx < storage.width {
			mut color_ := get_pixel(xx, yy, mut storage.file)
			if color_ == down_color {
				storage.file.set_pixel(xx, yy, color)
			} else {
				break
			}
			xx += 1
		}
	} else {
		return false
	}
	return true
}

fn (brush FillBrush) draw_hint(ptr voidptr, tx int, ty int, cx int, cy int, color gx.Color, size int) {
	mut win := &ui.Window(ptr)
	zoom := win.extra_map['zoom'].f32()
	wid := (size / 2) * zoom
	for i in 0 .. size {
		for j in 0 .. size {
			win.gg.draw_rect_empty(tx + ((cx + i) * zoom) - wid, ty + ((cy + j) * zoom) - wid,
				zoom, zoom, gx.blue)
		}
	}
}
