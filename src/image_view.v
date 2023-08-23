module main

import stbi
import gx
import iui as ui
import gg
import os

[heap]
struct ImageViewData {
mut:
	file      stbi.Image
	id        int
	file_name string
	file_size string
}

pub fn make_image_view(file string, mut win ui.Window, mut app App) &ui.Panel {
	mut vbox := ui.Panel.new(
		layout: ui.FlowLayout.new(
			hgap: 0
			vgap: 0
		)
	)

	mut png_file := stbi.load(file) or { return vbox }
	mut data := &ImageViewData{
		file: png_file
		file_name: file
	}
	app.data = data

	mut img := image_from_data(data)
	img.app = app
	app.canvas = img
	vbox.add_child(img)

	vbox.subscribe_event('draw', fn (mut e ui.DrawEvent) {
		app := e.ctx.win.get[&App]('app')
		e.target.width = app.canvas.width + 2
		e.target.height = app.canvas.height + 2
	})

	file_size := format_size(os.file_size(file))
	data.file_size = file_size

	vbox.set_pos(24, 24)

	return vbox
}

fn (mut img Image) set_zoom(mult f32) {
	img.width = int(img.w * mult)
	img.height = int(img.h * mult)
	img.zoom = mult
}

fn (mut img Image) get_zoom() f32 {
	return img.zoom
}

fn format_size(val f64) string {
	by := f64(1024)

	kb := val / by
	str := '${kb}'.str()[0..4]

	if kb > 1024 {
		mb := kb / by
		str2 := '${mb}'.str()[0..4]

		return '${str} KB / ${str2} MB'
	}
	return '${str} KB'
}

fn make_gg_image(mut storage ImageViewData, mut win ui.Window, first bool) {
	if first {
		storage.id = win.gg.new_streaming_image(storage.file.width, storage.file.height,
			4, gg.StreamingImageConfig{
			pixel_format: .rgba8
			mag_filter: .nearest
		})
	}
	win.gg.update_pixel_data(storage.id, storage.file.data)
}

// Get RGB value from image loaded with STBI
pub fn get_pixel(x int, y int, this stbi.Image) gx.Color {
	if x == -1 || y == -1 {
		return gx.rgba(0, 0, 0, 0)
	}

	x_oob := x < 0 || x >= this.width
	y_oob := y < 0 || y >= this.height
	if x_oob || y_oob {
		return gx.rgba(0, 0, 0, 0)
	}

	image := this
	unsafe {
		data := &u8(image.data)
		p := data + (4 * (y * image.width + x))
		r := p[0]
		g := p[1]
		b := p[2]
		a := p[3]
		return gx.Color{r, g, b, a}
	}
}

fn mix_color(ca gx.Color, cb gx.Color) gx.Color {
	if cb.a < 0 {
		return ca
	}

	ratio := f32(1) / 2
	mut r := u8(0)
	mut g := u8(0)
	mut b := u8(0)
	mut a := u8(0)
	for color in [ca, cb] {
		r += u8(color.r * ratio)
		g += u8(color.g * ratio)
		b += u8(color.b * ratio)
		a += u8(color.a * ratio)
	}
	return gx.rgba(r, g, b, a)
}

struct Change {
	x    int
	y    int
	from gx.Color
	to   gx.Color
mut:
	batch bool
}

fn (this Change) compare(b Change) u8 {
	same_pos := this.x == b.x && this.y == b.y
	same_from := this.from == b.from
	same_to := this.to == b.to

	if same_pos && same_to && same_from {
		return 2
	}
	if same_pos && same_to {
		return 1
	}
	return 0
}

fn (mut this Image) note_multichange() {
	change := Change{
		x: -1
		y: -1
		from: gx.white
		to: gx.white
		batch: false
	}
	this.history.insert(0, change)
}

fn (mut this Image) undo() {
	if this.history.len == 0 {
		return
	}
	last_change := this.history[0]
	old_color := last_change.from
	x := last_change.x
	y := last_change.y
	batch := last_change.batch

	set_pixel(this.data.file, x, y, old_color)
	this.history.delete(0)

	if batch {
		mut b := true
		for b {
			change := this.history[0]
			set_pixel(this.data.file, change.x, change.y, change.from)
			b = change.batch
			this.history.delete(0)
			if change.x == -1 {
				break
			}
		}
	}

	this.refresh()
}

fn (mut this Image) mark_batch_change() {
	this.history[0].batch = true
}

fn (mut this Image) set(x int, y int, color gx.Color) bool {
	return this.set2(x, y, color, false)
}

fn (mut this Image) set2(x int, y int, color gx.Color, batch bool) bool {
	change := Change{
		x: x
		y: y
		from: this.get(x, y)
		to: color
		batch: batch
	}

	if this.history.len > 1000 {
		this.history.delete_last()
	}

	if this.history.len > 0 {
		if this.history[0].compare(change) == 0 {
			this.history.insert(0, change)
		}
	} else {
		this.history.insert(0, change)
	}

	return set_pixel(this.data.file, x, y, color)
}

fn (mut this Image) get(x int, y int) gx.Color {
	return get_pixel(x, y, this.data.file)
}

fn (mut this Image) refresh() {
	mut data := this.data
	refresh_img(mut data, mut this.app.win.gg)
}

// Get RGB value from image loaded with STBI
fn set_pixel(image stbi.Image, x int, y int, color gx.Color) bool {
	if x < 0 || x >= image.width {
		return false
	}

	if y < 0 || y >= image.height {
		return false
	}

	unsafe {
		data := &u8(image.data)
		p := data + (4 * (y * image.width + x))
		p[0] = color.r
		p[1] = color.g
		p[2] = color.b
		p[3] = color.a
		return true
	}
}

// IMAGE

// Image - implements Component interface
pub struct Image {
	ui.Component_A
pub mut:
	app           &App
	data          &ImageViewData
	w             int
	h             int
	sx            f32
	sy            f32
	mx            int
	my            int
	img           int
	zoom          f32
	loaded        bool
	history       []Change
	history_index int
}

pub fn image_from_data(data &ImageViewData) &Image {
	return &Image{
		app: 0
		data: data
		img: data.id
		w: data.file.width
		h: data.file.height
		width: data.file.width
		height: data.file.height
		zoom: 1
	}
}

// Load image on first drawn frame
pub fn (mut this Image) load_if_not_loaded(ctx &ui.GraphicsContext) {
	mut win := ctx.win

	make_gg_image(mut this.data, mut win, true)
	this.img = this.data.id
	canvas_height := this.app.sv.height // - (this.app.sv.height / 4)
	zoom_fit := canvas_height / this.data.file.height
	if zoom_fit > 1 {
		this.set_zoom(zoom_fit - 1)
	}
	this.loaded = true
}

pub fn (mut this Image) draw(ctx &ui.GraphicsContext) {
	if !this.loaded {
		this.load_if_not_loaded(ctx)
	}

	ctx.gg.draw_image_with_config(gg.DrawImageConfig{
		img_id: this.app.bg_id
		img_rect: gg.Rect{
			x: this.x
			y: this.y
			width: this.width
			height: this.height
		}
	})

	ctx.gg.draw_image_with_config(gg.DrawImageConfig{
		img_id: this.img
		img_rect: gg.Rect{
			x: this.x
			y: this.y
			width: this.width
			height: this.height
		}
	})

	color := ctx.theme.text_color
	ctx.gg.draw_rect_empty(this.x, this.y, this.width, this.height, color)

	// Find mouse location data
	this.calculate_mouse_pixel(ctx)

	// Tools
	mut tool := this.app.tool
	tool.draw_hover_fn(this, ctx)

	if this.is_mouse_down {
		if ctx.win.bar.tik > 90 {
			tool.draw_down_fn(this, ctx)
		}
	}

	if this.is_mouse_rele {
		if ctx.win.bar.tik > 90 {
			tool.draw_click_fn(this, ctx)
		}
		this.is_mouse_rele = false
	}
}

// Updates which pixel the mouse is located
pub fn (mut this Image) calculate_mouse_pixel(ctx &ui.GraphicsContext) {
	mx := ctx.win.mouse_x
	my := ctx.win.mouse_y

	// Simple Editing
	for x in 0 .. this.w {
		for y in 0 .. this.h {
			sx := this.x + (x * this.zoom)
			ex := sx + this.zoom

			sy := this.y + (y * this.zoom)
			ey := sy + this.zoom

			gxa := mx < ex || mx > this.x + (x * this.zoom) || mx < this.x
			gy := my < ey //|| my < this.y

			if mx >= sx && gxa {
				if my >= sy && gy {
					this.sx = sx
					this.sy = sy
					this.mx = x
					this.my = y

					break
				}
			}

			if y == this.h - 1 {
				if mx >= sx && gxa && my > this.y + (y * this.zoom) {
					this.sx = sx
					this.sy = sy
					this.mx = x
					this.my = y
					break
				}
			}

			if y == 0 {
				if mx >= sx && gxa && my < this.y {
					this.sx = sx
					this.sy = sy
					this.mx = x
					this.my = y
					break
				}
			}
		}
	}

	if mx > this.x + ((this.w - 1) * this.zoom) {
		sx := this.x + ((this.w - 1) * this.zoom)

		this.sx = sx
		this.mx = this.w - 1
	}

	if mx < this.x {
		this.sx = this.x
		this.mx = 0
	}
}

fn (this &Image) get_point_screen_pos(x int, y int) (f32, f32) {
	sx := this.x + (x * this.zoom)
	sy := this.y + (y * this.zoom)
	return sx, sy
}

fn refresh_img(mut storage ImageViewData, mut ctx gg.Context) {
	ctx.update_pixel_data(storage.id, storage.file.data)
}
