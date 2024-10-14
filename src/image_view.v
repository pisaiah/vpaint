module main

import stbi
import gx
import iui as ui
import gg
import os

@[heap]
struct ImageViewData {
mut:
	file      stbi.Image
	id        int
	file_name string
	file_size string
}

pub fn (mut app App) make_image_view(file string) &ui.Panel {
	mut p := ui.Panel.new(
		layout: ui.FlowLayout.new(
			hgap: 0
			vgap: 0
		)
	)

	mut png_file := stbi.load(file) or { make_stbi(0, 0) }

	mut data := &ImageViewData{
		file:      png_file
		file_name: file
	}
	app.data = data

	mut img := image_from_data(data)
	img.app = app
	app.canvas = img
	p.add_child(img)

	p.subscribe_event('draw', img_panel_draw)

	if os.exists(file) {
		file_size := format_size(os.file_size(file))
		data.file_size = file_size
	}

	p.set_pos(24, 24)

	if app.data.file_size.len == 0 {
		app.load_new(32, 32)
	}

	return p
}

fn img_panel_draw(mut e ui.DrawEvent) {
	mut app := e.ctx.win.get[&App]('app')
	e.target.width = app.canvas.width + 2
	e.target.height = app.canvas.height + 2

	if app.need_open {
		$if emscripten ? {
			if C.emscripten_run_script_string(c'iui.task_result').vstring() == '1' {
				C.emscripten_run_script(c'iui.task_result = "0"')
				vall := C.emscripten_run_script_string(c'iui.latest_file.name').vstring()
				app.canvas.open(vall)
				app.need_open = false
			}
		}
	}
}

fn (mut img Image) set_zoom(mult f32) {
	img.width = int(img.w * mult)
	img.height = int(img.h * mult)
	img.zoom = mult

	mut sm := f32(128.0)

	zm := mult
	if zm > 10 {
		sf := zm / 8
		sm = (sf * 128) / 4
	}

	img.bw = int(img.width / sm)
	img.bh = int(img.height / sm)
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
		str2 := mb.str()[0..4]

		return str + ' KB / ${str2} MB'
	}
	return str + ' KB'
}

fn make_gg_image(mut storage ImageViewData, mut win ui.Window, first bool) {
	if first {
		storage.id = win.gg.new_streaming_image(storage.file.width, storage.file.height,
			4, gg.StreamingImageConfig{
			pixel_format: .rgba8
			mag_filter:   .nearest
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

	unsafe {
		data := &u8(this.data)
		p := data + (4 * (y * this.width + x))
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

	ratio := f32(.5)
	r := u8(ca.r * ratio) + u8(cb.r * ratio)
	g := u8(ca.g * ratio) + u8(cb.g * ratio)
	b := u8(ca.b * ratio) + u8(cb.b * ratio)
	a := u8(ca.a * ratio) + u8(cb.a * ratio)
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
		x:     -1
		y:     -1
		from:  gx.white
		to:    gx.white
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
	from := this.get(x, y)
	if from == color {
		return true
	}

	change := Change{
		x:     x
		y:     y
		from:  from
		to:    color
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

fn (mut this Image) set_no_undo(x int, y int, color gx.Color) bool {
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
	app           &App           = unsafe { nil }
	data          &ImageViewData = unsafe { nil }
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
	last_x        int = -1
	last_y        int
	bw            int
	bh            int
}

pub fn image_from_data(data &ImageViewData) &Image {
	return &Image{
		data:   data
		img:    data.id
		w:      data.file.width
		h:      data.file.height
		width:  data.file.width
		height: data.file.height
		zoom:   1
	}
}

// Load image on first drawn frame
pub fn (mut this Image) load_if_not_loaded(ctx &ui.GraphicsContext) {
	mut win := ctx.win

	make_gg_image(mut this.data, mut win, true)
	this.img = this.data.id
	canvas_height := this.app.sv.height
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
		img_id:   this.app.bg_id
		img_rect: gg.Rect{
			x:      this.x
			y:      this.y
			width:  this.width
			height: this.height
		}
	})

	ctx.gg.draw_image_with_config(gg.DrawImageConfig{
		img_id:   this.img
		img_rect: gg.Rect{
			x:      this.x
			y:      this.y
			width:  this.width
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

	if !this.is_mouse_down {
		if this.last_x != -1 {
			this.last_x = -1
			this.last_y = -1
		}
	}
}

// Updates which pixel the mouse is located
pub fn (mut this Image) calculate_mouse_pixel(ctx &ui.GraphicsContext) {
	mx := ctx.win.mouse_x - this.x
	my := ctx.win.mouse_y - this.y

	ix := int(mx / this.zoom)
	sx := this.x + (ix * this.zoom)

	iy := int(my / this.zoom)
	sy := this.y + (iy * this.zoom)

	if my > 0 {
		if my > this.height {
			nsy := this.y + ((this.h - 1) * this.zoom)
			this.sy = nsy
			this.my = this.h - 1
		} else {
			this.sy = sy
			this.my = iy
		}
	} else {
		this.sy = this.y
		this.my = 0
	}

	if mx > ((this.w - 1) * this.zoom) {
		nsx := this.x + ((this.w - 1) * this.zoom)

		this.sx = nsx
		this.mx = this.w - 1
		return
	}

	if mx < 0 {
		this.sx = this.x
		this.mx = 0
		return
	}

	this.sx = sx
	this.mx = ix
}

fn (this &Image) get_point_screen_pos(x int, y int) (f32, f32) {
	sx := this.x + (x * this.zoom)
	sy := this.y + (y * this.zoom)
	return sx, sy
}

fn (this &Image) get_pos_point(x f32, y f32) (int, int) {
	px := (x - this.x) / this.zoom
	py := (y - this.y) / this.zoom
	return int(px), int(py)
}

fn refresh_img(mut storage ImageViewData, mut ctx gg.Context) {
	ctx.update_pixel_data(storage.id, storage.file.data)
}
