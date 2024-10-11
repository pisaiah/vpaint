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
	count int
}

fn (mut this PencilTool) draw_hover_fn(a voidptr, ctx &ui.GraphicsContext) {
	mut img := unsafe { &Image(a) }

	size := img.app.brush_size
	half_size := size / 2
	pix := img.zoom

	xpos := img.sx - (half_size * pix)
	ypos := img.sy - (half_size * pix)

	width := img.zoom + ((size - 1) * pix)

	ctx.gg.draw_rounded_rect_empty(xpos, ypos, width, width, 1, gx.blue)

	// Draw lines instead of individual rects;
	// to reduce our drawing instructions.
	for i in 0 .. size {
		yy := ypos + (i * pix)
		xx := xpos + (i * pix)

		ctx.gg.draw_line(xpos, yy, xpos + width, yy, gx.blue)
		ctx.gg.draw_line(xx, ypos, xx, ypos + width, gx.blue)
	}
}

fn (mut this PencilTool) draw_down_fn(a voidptr, g &ui.GraphicsContext) {
	mut img := unsafe { &Image(a) }

	size := img.app.brush_size
	half_size := size / 2

	if img.last_x != -1 {
		pp := bresenham(img.last_x, img.last_y, img.mx, img.my)
		for p in pp {
			// img.set(p.x, p.y, img.app.get_color())

			for x in 0 .. size {
				for y in 0 .. size {
					img.set(p.x + (x - half_size), p.y + (y - half_size), img.app.get_color())
				}
			}
		}
	}

	img.last_x = img.mx
	img.last_y = img.my
	img.refresh()
}

fn (mut this PencilTool) draw_click_fn(a voidptr, b &ui.GraphicsContext) {
}

// Select Tool
struct SelectTool {
	tool_name string = 'Select'
mut:
	dx        int = -1
	dy        int
	selection Selection
}

struct Selection {
	x1 int
	y1 int
	x2 int
	y2 int
}

fn (mut this SelectTool) draw_hover_fn(a voidptr, ctx &ui.GraphicsContext) {
	if this.dx == -1 {
		return
	}

	mut img := unsafe { &Image(a) }

	xoff := img.mx - this.dx
	yoff := img.my - this.dy

	sx, sy := img.get_point_screen_pos(this.dx, this.dy)

	x := math.min(sx, sx + (img.zoom * xoff))
	y := math.min(sy, sy + (img.zoom * yoff))
	width := math.abs(img.zoom * xoff) + img.zoom
	height := math.abs(img.zoom * yoff) + img.zoom

	ctx.gg.draw_rounded_rect_empty(x, y, width, height, 1, gx.blue)
	ctx.gg.draw_rounded_rect_filled(x, y, width, height, 1, gx.rgba(0, 0, 255, 50))
}

fn (mut this SelectTool) draw_down_fn(a voidptr, b &ui.GraphicsContext) {
	mut img := unsafe { &Image(a) }
	if this.dx == -1 {
		this.dx = img.mx
		this.dy = img.my
	}
}

fn (mut this SelectTool) draw_click_fn(a voidptr, b &ui.GraphicsContext) {
	mut img := unsafe { &Image(a) }

	this.selection = Selection{
		x1: math.min(img.mx, this.dx)
		y1: math.min(img.my, this.dy)
		x2: math.max(img.mx, this.dx)
		y2: math.max(img.my, this.dy)
	}

	this.dx = -1
	this.dy = -1
}

// Drag Tool
struct DragTool {
	tool_name string = 'Drag Selection'
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
				ctx.gg.draw_rounded_rect_empty(xpos, ypos, img.zoom, img.zoom, 1, gx.blue)
			}
		}
	}
	ctx.gg.draw_rounded_rect_empty(img.sx, img.sy, img.zoom, img.zoom, 1, gx.blue)
}

fn (mut this AirbrushTool) draw_down_fn(a voidptr, b &ui.GraphicsContext) {
	mut img := unsafe { &Image(a) }

	size := img.app.brush_size
	half_size := size / 2

	for x in 0 .. size {
		for y in 0 .. size {
			rand_int := intn(size)
			if rand_int == 0 {
				img.set(img.mx + (x - half_size), img.my + (y - half_size), img.app.get_color())
			}
		}
	}

	img.set(img.mx, img.my, img.app.get_color())
	img.refresh()
}

fn (mut this AirbrushTool) draw_click_fn(a voidptr, b &ui.GraphicsContext) {
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
	ctx.gg.draw_rounded_rect_empty(xpos, ypos, width, width, 1, gx.blue)
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

// Pencil Tool
struct WidePencilTool {
	tool_name string = 'Wide Pencil'
}

fn (mut this WidePencilTool) draw_hover_fn(a voidptr, ctx &ui.GraphicsContext) {
	mut img := unsafe { &Image(a) }

	size := img.app.brush_size
	// half_size := size / 2
	q_size := 1 // half_size / 2
	pix := img.zoom

	xpos := img.sx - (size * pix)
	ypos := img.sy - (q_size * pix)

	width := img.zoom + (((size * 2) - 1) * pix)
	hei := img.zoom + ((2 - 1) * pix)

	ctx.gg.draw_rounded_rect_empty(xpos, ypos, width, hei, 1, gx.blue)
}

fn (mut this WidePencilTool) draw_down_fn(a voidptr, b &ui.GraphicsContext) {
	mut img := unsafe { &Image(a) }

	size := img.app.brush_size
	half_size := size / 2

	if img.last_x != -1 {
		pp := bresenham(img.last_x, img.last_y, img.mx, img.my)
		for p in pp {
			for x in -half_size .. size + half_size {
				for y in 0 .. 2 {
					img.set(p.x + (x - half_size), p.y + (y - 1), img.app.get_color())
				}
			}
		}
	}

	img.last_x = img.mx
	img.last_y = img.my
	img.refresh()
}

fn (mut this WidePencilTool) draw_click_fn(a voidptr, b &ui.GraphicsContext) {
}
