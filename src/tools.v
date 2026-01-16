module main

import iui as ui
import gx
import math
// import rand { intn }

// Use rand from stdlib
// Saves 4KB on wasm build
fn C.rand() int
fn intn(max int) int {
	return C.rand() % (max + 1)
}

// Tools
interface Tool {
	tool_name string
mut:
	draw_hover_fn(voidptr, &ui.GraphicsContext)
	draw_down_fn(voidptr, &ui.GraphicsContext)
	draw_click_fn(voidptr, &ui.GraphicsContext)
}

// Pencil Tool
struct PencilTool {
	tool_name string = 'Pencil'
mut:
	count  int
	change Multichange = Multichange.new()
}

fn pos_in_circle(x f32, y f32, center_x f32, center_y f32, radius f32) bool {
	dx := x - center_x
	dy := y - center_y
	return (dx * dx + dy * dy) <= (radius * radius)
}

fn (mut this PencilTool) draw_hover_fn(a voidptr, ctx &ui.GraphicsContext) {
	mut img := unsafe { &Image(a) }

	size := img.app.brush_size
	half_size := size / 2
	pix_size := img.zoom

	xpos := img.sx - (half_size * pix_size)
	ypos := img.sy - (half_size * pix_size)

	width := img.zoom + ((size - 1) * pix_size)

	round := img.app.settings.round_ends

	// ctx.gg.draw_rounded_rect_empty(xpos, ypos, width, width, 1, ctx.theme.accent_fill)

	// Draw lines instead of individual rects;
	// to reduce our drawing instructions.

	if size == 1 {
		ctx.gg.draw_rect_empty(xpos, ypos, width, width, ctx.theme.accent_fill)
		return
	}

	if !round || size == 1 {
		for i in 0 .. size + 1 {
			yy := ypos + (i * pix_size)
			xx := xpos + (i * pix_size)

			// Draw a line to represent the border of the pixel
			ctx.gg.draw_line(xpos, yy, xpos + width, yy, ctx.theme.accent_fill)
			ctx.gg.draw_line(xx, ypos, xx, ypos + width, ctx.theme.accent_fill)
		}
		return
	}

	radius := half_size

	// Draw lines only inside the circle
	// Reduce draw instructions
	mut sy := -1

	c := img.app.get_color()
	sr := radius * radius

	for xx in -radius .. radius {
		px := img.sx + (xx * pix_size)

		for yy in -radius .. radius {
			if xx * xx + yy * yy <= sr {
				if sy == -1 {
					sy = yy
					break
				}
			}
		}

		py := img.sy + (sy * pix_size)
		eey := if -sy >= radius { radius } else { -sy + 1 }
		ey := img.sy + (eey * pix_size)

		ctx.gg.draw_rect_filled(px, py, pix_size, ey - py, c)
		sy = -1
	}
	// ctx.gg.draw_circle_line(img.sx, img.sy, int(size * pix_size) / 2, 100, ctx.theme.accent_fill)
}

fn (mut this PencilTool) draw_down_fn(a voidptr, g &ui.GraphicsContext) {
	mut img := unsafe { &Image(a) }

	size := img.app.brush_size
	half_size := size / 2

	if img.last_x != -1 {
		if img.app.settings.round_ends {
			img.set_line(img.last_x, img.last_y, img.mx, img.my, img.app.get_color(),
				size, mut this.change)
		} else {
			pp := bresenham(img.last_x, img.last_y, img.mx, img.my)
			for p in pp {
				for offset in 0 .. size * size {
					x := offset % size
					y := offset / size
					img.set_raw(p.x + (x - half_size), p.y + (y - half_size), img.app.get_color(), mut
						this.change)
				}
			}
		}
	}

	img.last_x = img.mx
	img.last_y = img.my
	img.refresh()
}

fn (mut this PencilTool) draw_click_fn(a voidptr, b &ui.GraphicsContext) {
	mut img := unsafe { &Image(a) }
	img.push(this.change)
	this.change = Multichange.new()
}

// Drag Tool
struct DragTool {
	tool_name string = 'Drag'
mut:
	dx int = -1
	dy int
	sx f32
	sy f32
}

fn (mut this DragTool) draw_hover_fn(a voidptr, ctx &ui.GraphicsContext) {
}

fn (mut this DragTool) draw_down_fn(a voidptr, b &ui.GraphicsContext) {
	mut img := unsafe { &Image(a) }

	if this.dx == -1 {
		this.dx = img.mx
		this.dy = img.my
		this.sx, this.sy = img.get_point_screen_pos(this.dx, this.dy)
	}

	// TODO:
	// if app.selection_area {}

	sx, sy := img.get_point_screen_pos(img.mx, img.my)

	diff_x := sx - this.sx
	diff_y := sy - this.sy

	sdx := if diff_x < 0 { -4 } else { 4 }
	sdy := if diff_y < 0 { -4 } else { 4 }

	if math.abs(diff_x) > img.zoom {
		img.app.sv.scroll_x += sdx
	}
	if math.abs(diff_y) > img.zoom {
		img.app.sv.scroll_i += sdy
	}
}

fn (mut this DragTool) draw_click_fn(a voidptr, b &ui.GraphicsContext) {
	this.dx = -1
	this.dy = -1
	// sapp.set_mouse_cursor(.default)
}

// Pencil Tool
struct AirbrushTool {
	tool_name string = 'Airbrush'
mut:
	change Multichange = Multichange.new()
}

fn (mut this AirbrushTool) draw_hover_fn(a voidptr, ctx &ui.GraphicsContext) {
	mut img := unsafe { &Image(a) }

	size := img.app.brush_size
	half_size := size / 2
	pix := img.zoom

	for x in 0 .. size {
		for y in 0 .. size {
			xpos := img.sx + (x * pix) - (half_size * pix)
			ypos := img.sy + (y * pix) - (half_size * pix)
			rand_int := intn(size)
			if rand_int == 0 {
				ctx.gg.draw_rounded_rect_empty(xpos, ypos, img.zoom, img.zoom, 1, ctx.theme.accent_fill)
			}
		}
	}
	ctx.gg.draw_rounded_rect_empty(img.sx, img.sy, img.zoom, img.zoom, 1, ctx.theme.accent_fill)
}

fn (mut this AirbrushTool) draw_down_fn(a voidptr, b &ui.GraphicsContext) {
	mut img := unsafe { &Image(a) }

	size := img.app.brush_size
	half_size := size / 2

	for x in 0 .. size {
		for y in 0 .. size {
			rand_int := intn(size)
			if rand_int == 0 {
				img.set_raw(img.mx + (x - half_size), img.my + (y - half_size), img.app.get_color(), mut
					this.change)
			}
		}
	}

	img.set_raw(img.mx, img.my, img.app.get_color(), mut this.change)
	img.refresh()
}

fn (mut this AirbrushTool) draw_click_fn(a voidptr, b &ui.GraphicsContext) {
	mut img := unsafe { &Image(a) }
	img.push(this.change)
	this.change = Multichange.new()
}

// Dropper Tool
struct DropperTool {
	tool_name string = 'Eye Dropper'
}

fn (mut this DropperTool) draw_hover_fn(a voidptr, ctx &ui.GraphicsContext) {
	mut img := unsafe { &Image(a) }

	color := img.get(img.mx, img.my)

	width := if img.zoom > 4 { img.zoom * 4 } else { 16 }
	xpos := img.sx + width
	ypos := img.sy + width

	ctx.gg.draw_rounded_rect_filled(xpos, ypos, width, width, 1, color)
	ctx.gg.draw_rounded_rect_empty(xpos, ypos, width, width, 1, ctx.theme.accent_fill)
	str := 'RGBA: ${color.r}, ${color.g}, ${color.b}, ${color.a}'

	ctx.gg.draw_text(int(xpos), int(ypos), str, gx.TextCfg{
		size: 12
	})

	ctx.gg.set_text_cfg()

	mut win := ctx.win
	win.tooltip = str
}

fn (mut this DropperTool) draw_down_fn(a voidptr, b &ui.GraphicsContext) {
	mut img := unsafe { &Image(a) }

	color := img.get(img.mx, img.my)
	img.app.set_color(color)
}

fn (mut this DropperTool) draw_click_fn(a voidptr, b &ui.GraphicsContext) {
}

// Custom Pencil Tool
struct CustomPencilTool {
	tool_name string = 'Custom Pencil'
mut:
	width  int         = 8
	height int         = 2
	change Multichange = Multichange.new()
}

fn (mut this CustomPencilTool) draw_hover_fn(a voidptr, ctx &ui.GraphicsContext) {
	mut img := unsafe { &Image(a) }

	size := if this.width > 0 { this.width } else { img.app.brush_size }
	height := if this.height > 0 { this.height } else { img.app.brush_size }

	q_size := height / 2
	pix := img.zoom

	xpos := img.sx - (size * pix)
	ypos := img.sy - (q_size * pix)

	width := img.zoom + (((size * 2) - 1) * pix)
	hei := img.zoom + ((height - 1) * pix)

	ctx.gg.draw_rounded_rect_empty(xpos, ypos, width, hei, 1, ctx.theme.accent_fill)
}

fn (mut this CustomPencilTool) draw_down_fn(a voidptr, b &ui.GraphicsContext) {
	mut img := unsafe { &Image(a) }

	size := if this.width > 0 { this.width } else { img.app.brush_size }
	height := if this.height > 0 { this.height } else { img.app.brush_size }
	half_size := size / 2

	if img.last_x != -1 {
		pp := bresenham(img.last_x, img.last_y, img.mx, img.my)
		for p in pp {
			for x in -half_size .. size + half_size {
				for y in 0 .. height {
					img.set_raw(p.x + (x - half_size), p.y + (y - (height / 2)), img.app.get_color(), mut
						this.change)
				}
			}
		}
	}

	img.last_x = img.mx
	img.last_y = img.my
	img.refresh()
}

fn (mut this CustomPencilTool) draw_click_fn(a voidptr, b &ui.GraphicsContext) {
	mut img := unsafe { &Image(a) }
	img.push(this.change)
	this.change = Multichange.new()
}

// Fill Tool
struct FillTool {
	tool_name string = 'Fillcan'
mut:
	color  gx.Color
	img    &Image = unsafe { nil }
	count  int
	next   []Point
	change Multichange = Multichange.new()
}

fn (mut this FillTool) draw_hover_fn(a voidptr, ctx &ui.GraphicsContext) {
	mut img := unsafe { &Image(a) }
	ctx.gg.draw_rounded_rect_empty(img.sx, img.sy, img.zoom, img.zoom, 1, gx.blue)

	for p in this.next {
		if p.x != -1 {
			this.fill_points(p.x, p.y)
		}
	}
	if this.next.len > 0 {
		this.next.clear()
		unsafe { this.next.free() }
		unsafe { free(this.next) }
		this.next = []Point{}
		this.img.refresh()
	}
}

fn (mut this FillTool) draw_down_fn(a voidptr, b &ui.GraphicsContext) {
	this.next.clear()
	this.count = 0

	mut img := unsafe { &Image(a) }
	this.img = img

	x := img.mx
	y := img.my

	down_color := img.get(x, y)

	if down_color == img.app.get_color() {
		// If same color return
		return
	}

	this.color = down_color
	this.fill_points(x, y)

	img.set_raw(img.mx, img.my, img.app.get_color(), mut this.change)
	img.refresh()
}

fn (mut this FillTool) fill_points(x int, y int) {
	if x < 0 || y < 0 {
		return
	}

	mut img := this.img

	out_of_bounds := x >= img.w || y >= img.h
	same_color := this.color == img.app.get_color()

	if out_of_bounds || same_color {
		return
	}

	this.fill_point_(x, y)
}

fn (mut this FillTool) fill_point_(x int, y int) {
	this.fill_point(x, y - 1)
	this.fill_point(x, y + 1)
	this.fill_point(x - 1, y)
	this.fill_point(x + 1, y)
}

fn (mut this FillTool) fill_point(x int, y int) {
	color := this.img.get(x, y)
	if color == this.color {
		this.img.set_raw(x, y, this.img.app.get_color(), mut this.change)
		this.next << Point{x, y}
	}
}

fn (mut this FillTool) draw_click_fn(a voidptr, b &ui.GraphicsContext) {
	mut img := unsafe { &Image(a) }
	img.push(this.change)
	this.change = Multichange.new()
}
