module main

import stbi
import gx
import os

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
	}
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
	mut data := this.data

	this.zoom = 1

	mut png_file := stbi.load(path) or { panic(err) }

	data.file = png_file
	data.file_name = path
	data.file_size = format_size(os.file_size(path))

	this.data = data
	this.img = data.id
	this.w = png_file.width
	this.h = png_file.height
	this.width = data.file.width
	this.height = data.file.height
	this.loaded = false
}

fn (mut app App) make_new(w int, h int) stbi.Image {
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

fn (mut app App) load_new(w int, h int) {
	mut this := app.canvas

	mut png_file := app.make_new(w, h)

	mut data := this.data

	this.zoom = 1

	data.file = png_file
	this.data = data
	this.img = data.id
	this.w = png_file.width
	this.h = png_file.height
	this.width = data.file.width
	this.height = data.file.height
	this.loaded = false
}

fn (mut this Image) resize(w int, h int) {
	mut data := this.data

	this.zoom = 1

	mut png_file := stbi.resize_uint8(data.file, w, h) or { panic(err) }

	data.file = png_file
	this.data = data
	this.img = data.id
	this.w = png_file.width
	this.h = png_file.height
	this.width = data.file.width
	this.height = data.file.height
	this.loaded = false
}

fn (mut this Image) grayscale_filter() {
	this.note_multichange()
	for x in 0 .. this.w {
		for y in 0 .. this.h {
			rgb := this.get(x, y)
			gray := (rgb.r + rgb.g + rgb.b) / 3
			new_color := gx.rgb(gray, gray, gray)
			this.set2(x, y, new_color, true)
		}
	}
	this.refresh()
}

fn (mut this Image) invert_filter() {
	this.note_multichange()
	for x in 0 .. this.w {
		for y in 0 .. this.h {
			rgb := this.get(x, y)
			new_color := gx.rgb(255 - rgb.r, 255 - rgb.g, 255 - rgb.b)
			this.set(x, y, new_color)
			this.mark_batch_change()
		}
	}
	this.refresh()
}

// TODO: Better upscale;
// Currently looks same as resize()
fn (mut this Image) upscale() {
	mut data := this.data
	w := this.w * 2
	h := this.h * 2

	this.zoom = 1

	mut png_file := stbi.resize_uint8(data.file, w, h) or { panic(err) }

	for x in 0 .. w {
		for y in 0 .. h {
			set_pixel(png_file, x, y, gx.rgb(255, 0, 255))
		}
	}

	for x in 0 .. this.w {
		for y in 0 .. this.h {
			a := get_pixel(x, y, data.file)
			b := get_pixel(x + 1, y, data.file)

			n := mix_color(a, b)

			// Oringal
			set_pixel(png_file, x * 2, (y * 2), a)

			// Right
			set_pixel(png_file, (x * 2) + 1, (y * 2), n) // Right
		}
	}

	for x in 0 .. w {
		for y in 0 .. this.h {
			a := get_pixel(x, y * 2, png_file)
			b := get_pixel(x, (y * 2) + 2, png_file)

			n := mix_color(a, b)

			set_pixel(png_file, x, (y * 2) + 1, n) // Right
		}
	}

	unsafe {
		data.file.free()
	}
	data.file = png_file

	this.data = data
	this.img = data.id
	this.w = png_file.width
	this.h = png_file.height
	this.width = data.file.width
	this.height = data.file.height
	this.loaded = false
}
