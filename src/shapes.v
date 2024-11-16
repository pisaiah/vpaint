module main

import iui as ui
import math

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

	ctx.gg.draw_rounded_rect_empty(xpos, ypos, width, width, 1, ctx.theme.accent_fill)

	// Draw lines instead of individual rects;
	// to reduce our drawing instructions.
	for i in 0 .. size {
		yy := ypos + (i * pix)
		xx := xpos + (i * pix)

		ctx.gg.draw_line(xpos, yy, xpos + width, yy, ctx.theme.accent_fill)
		ctx.gg.draw_line(xx, ypos, xx, ypos + width, ctx.theme.accent_fill)
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
			g.gg.draw_rect_empty(aa - (half_size * img.zoom), bb - (half_size * img.zoom),
				img.zoom * size, img.zoom * size, g.theme.accent_fill)
		}
	}
}

fn (mut this LineTool) draw_click_fn(a voidptr, b &ui.GraphicsContext) {
	mut img := unsafe { &Image(a) }

	size := img.app.brush_size
	half_size := size / 2

	if this.sx != -1 {
		pp := bresenham(this.sx, this.sy, img.mx, img.my)
		mut change := Multichange.new()
		for p in pp {
			for x in 0 .. size {
				for y in 0 .. size {
					img.set_raw(p.x + (x - half_size), p.y + (y - half_size), img.app.get_color(), mut
						change)
				}
			}
		}
		img.push(change)
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

	ctx.gg.draw_rounded_rect_empty(xpos, ypos, width, width, 1, ctx.theme.accent_fill)

	// Draw lines instead of individual rects;
	// to reduce our drawing instructions.
	for i in 0 .. size {
		yy := ypos + (i * pix)
		xx := xpos + (i * pix)

		ctx.gg.draw_line(xpos, yy, xpos + width, yy, ctx.theme.accent_fill)
		ctx.gg.draw_line(xx, ypos, xx, ypos + width, ctx.theme.accent_fill)
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
		g.gg.draw_rect_filled(aa - (half_size * img.zoom), bb - (half_size * img.zoom),
			pix_size + (cc - aa), pix_size, g.theme.accent_fill)
		g.gg.draw_rect_filled(aa - (half_size * img.zoom), dd - (half_size * img.zoom),
			pix_size + (cc - aa), pix_size, g.theme.accent_fill)
		g.gg.draw_rect_filled(aa - (half_size * img.zoom), bb - (half_size * img.zoom),
			pix_size, pix_size + (dd - bb), g.theme.accent_fill)
		g.gg.draw_rect_filled(cc - (half_size * img.zoom), bb - (half_size * img.zoom),
			pix_size, pix_size + (dd - bb), g.theme.accent_fill)
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

	mut change := Multichange.new()

	if this.sx != -1 {
		for x in 0 .. size {
			for y in 0 .. size {
				for xx in x1 .. x2 {
					img.set_raw(xx + (x - half_size), y1 + (y - half_size), c, mut change)
					img.set_raw(xx + (x - half_size), y2 + (y - half_size), c, mut change)
				}
				for yy in y1 .. y2 {
					img.set_raw(x1 + (x - half_size), yy + (y - half_size), c, mut change)
					img.set_raw(x2 + (x - half_size), yy + (y - half_size), c, mut change)
				}
			}
		}
	}

	img.set_raw(x2, y2, c, mut change)
	img.push(change)
	img.refresh()

	// Reset
	this.sx = -1
	this.sy = -1
}

// Oval Tool
struct OvalTool {
	tool_name string = 'Oval'
mut:
	count int
	sx    int = -1
	sy    int = -1
}

fn (mut this OvalTool) draw_hover_fn(a voidptr, ctx &ui.GraphicsContext) {
	mut img := unsafe { &Image(a) }

	size := img.app.brush_size
	half_size := size / 2
	pix := img.zoom

	xpos := img.sx - (half_size * pix)
	ypos := img.sy - (half_size * pix)

	width := img.zoom + ((size - 1) * pix)

	ctx.gg.draw_rounded_rect_empty(xpos, ypos, width, width, 1, ctx.theme.accent_fill)

	// Draw lines instead of individual rects;
	// to reduce our drawing instructions.
	for i in 0 .. size {
		yy := ypos + (i * pix)
		xx := xpos + (i * pix)

		ctx.gg.draw_line(xpos, yy, xpos + width, yy, ctx.theme.accent_fill)
		ctx.gg.draw_line(xx, ypos, xx, ypos + width, ctx.theme.accent_fill)
	}
}

fn (mut this OvalTool) draw_down_fn(a voidptr, g &ui.GraphicsContext) {
	mut img := unsafe { &Image(a) }

	if this.sx == -1 {
		this.sx = img.mx
		this.sy = img.my
	}

	size := img.app.brush_size

	x1 := if this.sx < img.mx { this.sx } else { img.mx }
	y1 := if this.sy < img.my { this.sy } else { img.my }

	x2 := if this.sx < img.mx { img.mx } else { this.sx }
	y2 := if this.sy < img.my { img.my } else { this.sy }

	if this.sx != -1 {
		pix_size := img.zoom * size
		half_pix := int(img.zoom * (size / 2))

		center_x := (x1 + x2) / 2
		center_y := (y1 + y2) / 2
		radius_x := (x2 - x1) / 2
		radius_y := (y2 - y1) / 2

		for angle in 0 .. 360 {
			rad := f32(angle) * (f32(math.pi) / 180.0)
			x := int(radius_x * math.cos(rad))
			y := int(radius_y * math.sin(rad))

			aa, bb := img.get_point_screen_pos(center_x + x, center_y + y)
			g.gg.draw_rect_empty(aa - half_pix, bb - half_pix, pix_size, pix_size, g.theme.accent_fill)
		}
	}
}

fn (mut this OvalTool) draw_click_fn(a voidptr, b &ui.GraphicsContext) {
	mut img := unsafe { &Image(a) }

	size := img.app.brush_size
	half_size := size / 2

	x1 := if this.sx < img.mx { this.sx } else { img.mx }
	y1 := if this.sy < img.my { this.sy } else { img.my }

	x2 := if this.sx < img.mx { img.mx } else { this.sx }
	y2 := if this.sy < img.my { img.my } else { this.sy }

	c := img.app.get_color()

	if this.sx != -1 {
		// Calculate the center and radius
		center_x := (x1 + x2) / 2
		center_y := (y1 + y2) / 2
		radius_x := (x2 - x1) / 2
		radius_y := (y2 - y1) / 2

		mut change := Multichange.new()

		for angle in 0 .. 360 {
			rad := f32(angle) * (f32(math.pi) / 180.0)
			x := int(radius_x * math.cos(rad))
			y := int(radius_y * math.sin(rad))

			for xx in 0 .. size {
				for yy in 0 .. size {
					img.set_raw(center_x + x - half_size + xx, center_y + y - half_size + yy,
						c, mut change)
				}
			}
		}
		img.push(change)
	}

	img.refresh()

	// Reset
	this.sx = -1
	this.sy = -1
}
