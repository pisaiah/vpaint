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
// TODO: Implement Selection
struct SelectTool {
	tool_name string = 'Select'
mut:
	dx        int = -1
	dy        int
	selection Selection = Selection{-1, -1, -1, -1}
	sx        f32       = -1
	sy        f32
	moving    bool
}

struct Selection {
mut:
	x1 int
	y1 int
	x2 int
	y2 int
}

pub fn (sel Selection) is_in(img &Image, px f32, py f32) bool {
	x1, y1 := img.get_point_screen_pos(sel.x1 - 1, sel.y1 - 1)
	x2, y2 := img.get_point_screen_pos(sel.x2, sel.y2)

	width := (x2 - x1) + img.zoom
	height := (y2 - y1) + img.zoom

	x := x1
	y := y1

	midx := x + (width / 2)
	midy := y + (height / 2)

	return math.abs(midx - px) < (width / 2) && math.abs(midy - py) < (height / 2)
}

fn pos_only(num int) int {
	return if num < 0 { 0 } else { num }
}

fn (mut this SelectTool) draw_moving_drag(img &Image, ctx &ui.GraphicsContext) {
	swidth := this.selection.x2 - this.selection.x1
	sheight := this.selection.y2 - this.selection.y1

	tsx, tsy := img.get_pos_point(this.sx, this.sy)
	dsx := tsx - this.selection.x1
	dsy := tsy - this.selection.y1

	mx_ := img.mx - dsx
	my_ := img.my - dsy

	mx := if mx_ + swidth >= img.w { img.w - swidth - 1 } else { pos_only(mx_) }
	my := if my_ + sheight >= img.h { img.h - sheight - 1 } else { pos_only(my_) }

	this.selection.x1 = mx
	this.selection.y1 = my

	this.selection.x2 = this.selection.x1 + swidth
	this.selection.y2 = this.selection.y1 + sheight

	this.sx, this.sy = img.get_point_screen_pos(mx + dsx, my + dsy)
}

fn (mut this SelectTool) draw_moving(img &Image, ctx &ui.GraphicsContext) {
	this.moving = true

	x1, y1 := img.get_point_screen_pos(this.selection.x1, this.selection.y1)
	x2, y2 := img.get_point_screen_pos(this.selection.x2, this.selection.y2)

	width := (x2 - x1) + img.zoom
	height := (y2 - y1) + img.zoom

	ctx.gg.draw_rounded_rect_empty(x1, y1, width, height, 1, gx.green)
	ctx.gg.draw_rounded_rect_filled(x1, y1, width, height, 1, gx.rgba(0, 255, 0, 50))

	sx, sy := img.get_point_screen_pos(img.mx, img.my)

	if this.selection.is_in(img, sx, sy) && this.dx != -1 {
		this.draw_moving_drag(img, ctx)
	}
}

fn (mut this SelectTool) draw_hover_fn(a voidptr, ctx &ui.GraphicsContext) {
	mut img := unsafe { &Image(a) }

	if this.selection.x1 != -1 {
		this.draw_moving(img, ctx)
		return
	}

	if this.dx == -1 {
		return
	}

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

	if this.sx == -1 {
		this.sx, this.sy = img.get_point_screen_pos(this.dx, this.dy)
	}
}

fn (mut this SelectTool) draw_click_fn(a voidptr, b &ui.GraphicsContext) {
	mut img := unsafe { &Image(a) }

	if !this.moving {
		// Making Selection
		this.selection = Selection{
			x1: math.min(img.mx, this.dx)
			y1: math.min(img.my, this.dy)
			x2: math.max(img.mx, this.dx)
			y2: math.max(img.my, this.dy)
		}
	} else {
		// Clicked out of current Selection
		this.moving = false
		sx, sy := img.get_point_screen_pos(img.mx, img.my)
		if !this.selection.is_in(img, sx, sy) {
			this.selection = Selection{-1, -1, -1, -1}
		}
	}

	this.sx = -1
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


// Line Tool
struct LineTool {
	tool_name string = 'Line'
mut:
	count int
	sx    int = -1
	sy    int = -1
}

fn (mut this LineTool) draw_hover_fn(a voidptr, ctx &ui.GraphicsContext) {
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

fn (mut this LineTool) draw_down_fn(a voidptr, g &ui.GraphicsContext) {
	mut img := unsafe { &Image(a) }
	
	if this.sx == -1 {
		this.sx = img.mx
		this.sy = img.my
	}

	size := img.app.brush_size
	half_size := size / 2

	if this.sx != -1 {
		pp := bresenham(this.sx, this.sy, img.mx, img.my)
		for p in pp {
			aa, bb := img.get_point_screen_pos(p.x, p.y)
			g.gg.draw_rect_empty(aa - (half_size * img.zoom), bb - (half_size * img.zoom), img.zoom * size, img.zoom * size, gx.blue)
		}
	}
}

fn (mut this LineTool) draw_click_fn(a voidptr, b &ui.GraphicsContext) {
	mut img := unsafe { &Image(a) }

	size := img.app.brush_size
	half_size := size / 2

	if this.sx != -1 {
		pp := bresenham(this.sx, this.sy, img.mx, img.my)
		for p in pp {
			for x in 0 .. size {
				for y in 0 .. size {
					img.set(p.x + (x - half_size), p.y + (y - half_size), img.app.get_color())
				}
			}
		}
	}

	img.refresh()
	
	// Reset
	this.sx = -1
	this.sy = -1
}

// Rect Tool
struct RectTool {
	tool_name string = 'Rectangle'
mut:
	count int
	sx    int = -1
	sy    int = -1
}

fn (mut this RectTool) draw_hover_fn(a voidptr, ctx &ui.GraphicsContext) {
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

fn (mut this RectTool) draw_down_fn(a voidptr, g &ui.GraphicsContext) {
	mut img := unsafe { &Image(a) }
	
	if this.sx == -1 {
		this.sx = img.mx
		this.sy = img.my
	}

	size := img.app.brush_size
	half_size := size / 2

	x1 := if this.sx < img.mx { this.sx } else { img.mx }
	y1 := if this.sy < img.my { this.sy } else { img.my }
	
	x2 := if this.sx < img.mx { img.mx } else { this.sx }
	y2 := if this.sy < img.my { img.my } else { this.sy }

	if this.sx != -1 {

		aa, bb := img.get_point_screen_pos(x1, y1)
		cc, dd := img.get_point_screen_pos(x2, y2)
		pix_size := img.zoom * size
		
		// Top, Bottom, Left, Right
		g.gg.draw_rect_filled(aa - (half_size * img.zoom), bb - (half_size * img.zoom), pix_size + (cc - aa), pix_size, gx.blue)
		g.gg.draw_rect_filled(aa - (half_size * img.zoom), dd - (half_size * img.zoom), pix_size + (cc - aa), pix_size, gx.blue)
		g.gg.draw_rect_filled(aa - (half_size * img.zoom), bb - (half_size * img.zoom), pix_size, pix_size + (dd - bb), gx.blue)
		g.gg.draw_rect_filled(cc - (half_size * img.zoom), bb - (half_size * img.zoom), pix_size, pix_size + (dd - bb), gx.blue)
	}
}

fn (mut this RectTool) draw_click_fn(a voidptr, b &ui.GraphicsContext) {
	mut img := unsafe { &Image(a) }

	size := img.app.brush_size
	half_size := size / 2
	
	x1 := if this.sx < img.mx { this.sx } else { img.mx }
	y1 := if this.sy < img.my { this.sy } else { img.my }
	
	x2 := if this.sx < img.mx { img.mx } else { this.sx }
	y2 := if this.sy < img.my { img.my } else { this.sy }

	c := img.app.get_color()

	if this.sx != -1 {
		for x in 0 .. size {
			for y in 0 .. size {
				for xx in x1 .. x2 {
					img.set(xx + (x - half_size), y1 + (y - half_size), c)
					img.set(xx + (x - half_size), y2 + (y - half_size), c)
				}
				for yy in y1 .. y2 {
					img.set(x1 + (x - half_size), yy + (y - half_size), c)
					img.set(x2 + (x - half_size), yy + (y - half_size), c)
				}
			}
		}
	}

	img.set(x2, y2, c)
	img.refresh()
	
	// Reset
	this.sx = -1
	this.sy = -1
}
