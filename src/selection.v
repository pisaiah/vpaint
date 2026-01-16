module main

import iui as ui
import math
import gg

// Select Tool
// TODO: Implement Selection
struct SelectTool {
	tool_name string = 'Select'
mut:
	dx        int = -1
	dy        int
	selection Selection = Selection{-1, -1, -1, -1, [][]gg.Color{}, ui.Bounds{}}
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
	px [][]gg.Color
	og ui.Bounds
}

pub fn (mut sel Selection) clear_before(a voidptr) {
	mut img := unsafe { &Image(a) }
	for x in 0 .. (sel.x2 - sel.x1) {
		for y in 0 .. (sel.y2 - sel.y1) {
			img.set2(sel.og.x + x, sel.og.y + y, img.app.color_2, true)
		}
	}
	img.refresh()
}

pub fn (mut sel Selection) fill_px(a voidptr) {
	mut img := unsafe { &Image(a) }

	for x in sel.x1 .. sel.x2 + 1 {
		for y in sel.y1 .. sel.y2 + 1 {
			sel.px[x - sel.x1][y - sel.y1] = img.get(x, y)
		}
	}
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
	x3, y3 := img.get_point_screen_pos(this.selection.og.x, this.selection.og.y)

	sw := this.selection.x2 - this.selection.x1 + 1
	sh := this.selection.y2 - this.selection.y1 + 1

	// Fake removing old pixels
	/*
	ctx.gg.draw_image_with_config(gg.DrawImageConfig{
		img_id:   img.app.bg_id
		img_rect: gg.Rect{
			x:      x3
			y:      y3
			width:  sw * img.zoom
			height: sh * img.zoom
		}
	})
	ctx.gg.draw_rounded_rect_filled(x3, y3, sw * img.zoom, sh * img.zoom, 1, img.app.color_2)
	*/

	width := (x2 - x1) + img.zoom
	height := (y2 - y1) + img.zoom

	// Draw old rect
	if !(x1 == x3 && y1 == y3) {
		ctx.gg.draw_rounded_rect_empty(x3, y3, width, height, 1, gg.red)
		ctx.gg.draw_rounded_rect_filled(x3, y3, width, height, 1, gg.rgba(255, 0, 0, 80))
		ctx.gg.draw_line(x3, y3, x3 + width, y3 + height, gg.red)
		ctx.gg.draw_line(x3, y3 + height, x3 + width, y3, gg.red)
	}

	// Draw new rect
	ctx.gg.draw_image_with_config(gg.DrawImageConfig{
		img_id:    img.img
		img_rect:  gg.Rect{
			x:      x1
			y:      y1
			width:  x2 - x1 + img.zoom
			height: y2 - y1 + img.zoom
		}
		part_rect: gg.Rect{
			x:      this.selection.og.x
			y:      this.selection.og.y
			width:  sw
			height: sh
		}
	})

	ctx.gg.draw_rounded_rect_empty(x1, y1, width, height, 1, gg.green)
	ctx.gg.draw_rounded_rect_filled(x1, y1, width, height, 1, gg.rgba(0, 255, 0, 50))

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

	ctx.gg.draw_rounded_rect_empty(x, y, width, height, 1, ctx.theme.accent_fill)
	ctx.gg.draw_rounded_rect_filled(x, y, width, height, 1, gg.rgba(0, 0, 255, 50))
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
		x1 := math.min(img.mx, this.dx)
		y1 := math.min(img.my, this.dy)
		x2 := math.max(img.mx, this.dx)
		y2 := math.max(img.my, this.dy)

		this.selection = Selection{
			x1: x1
			y1: y1
			x2: x2
			y2: y2
			px: [][]gg.Color{len: (x2 - x1) + 1, init: []gg.Color{len: (y2 - y1) + 1}}
			og: ui.Bounds{x1, y1, x2, y2}
		}
		this.selection.fill_px(img)
	} else {
		// Clicked out of current Selection
		this.moving = false

		sx, sy := img.get_point_screen_pos(img.mx, img.my)
		if !this.selection.is_in(img, sx, sy) {
			sw := this.selection.x2 - this.selection.x1 + 1
			sh := this.selection.y2 - this.selection.y1 + 1

			// img.note_multichange()

			mut change := Multichange.new()

			for x in 0 .. sw {
				for y in 0 .. sh {
					img.set_raw(this.selection.og.x + x, this.selection.og.y + y, img.app.color_2, mut
						change)
				}
			}

			img.push(change)
			change = Multichange.new()

			change.second = true

			for x in 0 .. sw {
				for y in 0 .. sh {
					c := this.selection.px[x][y]

					// Set New
					img.set_raw(this.selection.x1 + x, this.selection.y1 + y, c, mut change)
				}
			}
			img.push(change)
			img.refresh()

			this.selection = Selection{-1, -1, -1, -1, [][]gg.Color{}, ui.Bounds{}}
		}
	}

	this.sx = -1
	this.dx = -1
	this.dy = -1
}
