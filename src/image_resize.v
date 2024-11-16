module main

import stbi
import gx
import os
import iui.src.extra.file_dialog

// wasm
pub fn C.emscripten_run_script(&char)
pub fn C.emscripten_run_script_string(&char) &char
pub fn C.emscripten_sleep(int)

fn (mut app App) open() {
	$if emscripten ? {
		unsafe {
			C.emscripten_run_script(c'iui.trigger = "openfiledialog"')
			app.need_open = true
		}
		return
	}

	path := file_dialog.open_dialog('Select Image File to Open')
	app.canvas.open(path)
}

fn cstr(the_string string) &char {
	return &char(the_string.str)
}

fn emsave(path string) {
	$if emscripten ? {
		C.emscripten_run_script(cstr('iui.trigger = "savefile=' + path + '"'))
	}
}

fn (mut this Image) open(path string) {
	png_file := stbi.load(path) or { panic(err) }

	this.data.file_name = path
	this.data.file_size = format_size(os.file_size(path))
	this.load_stbi(png_file)
}

fn (mut app App) load_new(w int, h int) {
	png_file := make_stbi(w, h)
	app.canvas.load_stbi(png_file)
}

fn (mut this Image) resize(w int, h int) {
	png_file := stbi.resize_uint8(this.data.file, w, h) or { panic(err) }
	this.load_stbi(png_file)
}

fn (mut this Image) grayscale_filter() {
	mut change := Multichange.new()
	for x in 0 .. this.w {
		for y in 0 .. this.h {
			rgb := this.get(x, y)
			gray := (rgb.r + rgb.g + rgb.b) / 3
			new_color := gx.rgb(gray, gray, gray)
			this.set_raw(x, y, new_color, mut change)
		}
	}
	this.push(change)
	this.refresh()
}

fn (mut this Image) invert_filter() {
	mut change := Multichange.new()

	for x in 0 .. this.w {
		for y in 0 .. this.h {
			rgb := this.get(x, y)
			new_color := gx.rgba(255 - rgb.r, 255 - rgb.g, 255 - rgb.b, rgb.a)
			this.set_raw(x, y, new_color, mut change)
		}
	}
	this.push(change)
	this.refresh()
}

fn make_stbi(w int, h int) stbi.Image {
	img_size := w * h * 4
	img_pixels := unsafe { &u8(malloc(img_size)) }

	png_file := stbi.Image{
		ok:          true
		ext:         'png'
		data:        img_pixels
		width:       w
		height:      h
		nr_channels: 4
	}
	return png_file
}

fn (mut this Image) load_stbi(png_file stbi.Image) {
	mut data := this.data
	this.zoom = 1
	data.file.free()
	data.file = png_file
	this.data = data
	this.img = data.id
	this.w = png_file.width
	this.h = png_file.height
	this.width = data.file.width
	this.height = data.file.height
	this.loaded = false
}

// TODO: Better upscale
fn (mut this Image) upscale() {
	this.hq3x()
	// this.bilinear_interpolation(this.w * 2, this.h * 2)
}

fn (mut this Image) bilinear_interpolation(new_width int, new_height int) {
	src_width := this.w
	src_height := this.h

	mut en := make_stbi(new_width, new_height)

	data := &u8(this.data.file.data)

	for y in 0 .. new_height {
		for x in 0 .. new_width {
			// Calculate the position in the source image
			src_x := f32(x) * f32(src_width - 1) / f32(new_width - 1)
			src_y := f32(y) * f32(src_height - 1) / f32(new_height - 1)

			// Get the integer and fractional parts
			x0 := int(src_x)
			y0 := int(src_y)
			x1 := if x0 + 1 < src_width { x0 + 1 } else { x0 }
			y1 := if y0 + 1 < src_height { y0 + 1 } else { y0 }
			dx := src_x - f32(x0)
			dy := src_y - f32(y0)

			unsafe {
				a := data + (4 * (y0 * this.w + x0))
				b := data + (4 * (y0 * this.w + x1))
				c := data + (4 * (y1 * this.w + x0))
				d := data + (4 * (y1 * this.w + x1))

				// Perform the interpolation for each color component
				top_r := (1.0 - dx) * a[0] + dx * b[0]
				bottom_r := (1.0 - dx) * c[0] + dx * d[0]
				cr := u8((1.0 - dy) * top_r + dy * bottom_r)

				top_g := (1.0 - dx) * a[1] + dx * b[1]
				bottom_g := (1.0 - dx) * c[1] + dx * d[1]
				cg := u8((1.0 - dy) * top_g + dy * bottom_g)

				top_b := (1.0 - dx) * a[2] + dx * b[2]
				bottom_b := (1.0 - dx) * c[2] + dx * d[2]
				cb := u8((1.0 - dy) * top_b + dy * bottom_b)

				top_a := (1.0 - dx) * a[3] + dx * b[3]
				bottom_a := (1.0 - dx) * c[3] + dx * d[3]
				ca := u8((1.0 - dy) * top_a + dy * bottom_a)

				set_pixel(en, x, y, gx.rgba(cr, cg, cb, ca))
			}
		}
	}

	this.load_stbi(en)
}

fn (mut this Image) scale2x() [][]gx.Color {
	src_width := this.w
	src_height := this.h
	mut dst := [][]gx.Color{len: src_height * 2, init: []gx.Color{len: src_width * 2}}

	mut en := make_stbi(this.w * 2, this.h * 2)

	for y in 0 .. src_height {
		for x in 0 .. src_width {
			c := this.get(x, y)
			a := if y > 0 { this.get(x, y - 1) } else { c }
			b := if x > 0 { this.get(x - 1, y) } else { c }
			d := if x < src_width - 1 { this.get(x + 1, y) } else { c }
			e := if y < src_height - 1 { this.get(x, y + 1) } else { c }

			dst[y * 2][x * 2] = if a == b { a } else { c }
			dst[y * 2][x * 2 + 1] = if a == d { a } else { c }
			dst[y * 2 + 1][x * 2] = if e == b { e } else { c }
			dst[y * 2 + 1][x * 2 + 1] = if e == d { e } else { c }
		}
	}

	for x in 0 .. this.w * 2 {
		for y in 0 .. this.h * 2 {
			set_pixel(en, x, y, dst[y][x])
		}
	}
	this.load_stbi(en)

	return dst
}

fn (mut this Image) hq3x() {
	src_width := this.w
	src_height := this.h

	mut en := make_stbi(this.w * 3, this.h * 3)

	for y in 0 .. src_height {
		for x in 0 .. src_width {
			c := this.get(x, y)
			a := if y > 0 { this.get(x, y - 1) } else { c }
			b := if x > 0 { this.get(x - 1, y) } else { c }
			d := if x < src_width - 1 { this.get(x + 1, y) } else { c }
			e := if y < src_height - 1 { this.get(x, y + 1) } else { c }

			// Fill the 3x3 block
			for dy in 0 .. 3 {
				for dx in 0 .. 3 {
					set_pixel(en, x * 3 + dx, y * 3 + dy, c)
				}
			}

			// Apply the hq3x rules
			if a == b && a != d && b != e {
				set_pixel(en, x * 3, y * 3, a)
			}
			if a == d && a != b && d != e {
				set_pixel(en, x * 3 + 2, y * 3, d)
			}
			if e == b && e != a && b != d {
				set_pixel(en, x * 3, y * 3 + 2, e)
			}
			if e == d && e != a && d != b {
				set_pixel(en, x * 3 + 2, y * 3 + 2, e)
			}
		}
	}

	this.load_stbi(en)
}

fn (mut this Image) increase_alpha() {
	for x in 0 .. this.w {
		for y in 0 .. this.h {
			color := this.get(x, y)
			if color.a < 5 {
				continue
			}

			new_color := gx.rgba(color.r, color.g, color.b, color.a + 5)
			this.set(x, y, new_color)
		}
	}
	this.refresh()
}
