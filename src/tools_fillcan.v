module main

import iui as ui
import gx
import time

// Fill Tool
struct FillTool {
	tool_name string = 'Fillcan'
mut:
	color gx.Color
	img   &Image = unsafe { nil }
	count int
	next  []Point
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
		this.next.free()
		free(this.next)
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

	img.set(img.mx, img.my, img.app.get_color())
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
		this.img.set_no_undo(x, y, this.img.app.get_color())
		this.next << Point{x, y}
	}
}

fn (mut this FillTool) draw_click_fn(a voidptr, b &ui.GraphicsContext) {
	// this.next = Point{-1, -1}
}
