module main

import iui as ui
import math

// Line Tool
struct LineTool {
	tool_name string = 'Line'
mut:
	count int
	sx    int  = -1
	sy    int  = -1
	round bool = true
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

	round := this.round && size > 1 && img.app.settings.round_ends

	// Square Edges
	if this.sx != -1 && !round {
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

	// Round Edges
	if this.sx != -1 && round {
		pp := bresenham(this.sx, this.sy, img.mx, img.my)
		mut change := Multichange.new()
		for p in pp {
			for x in -half_size .. half_size {
				for y in -half_size .. half_size {
					if x * x + y * y <= half_size * half_size {
						img.set_raw(p.x + x, p.y + y, img.app.get_color(), mut change)
					}
				}
			}
		}

		// Draw circles at the start and end points to round the ends
		for x in -half_size .. half_size {
			for y in -half_size .. half_size {
				if x * x + y * y <= half_size * half_size {
					img.set_raw(this.sx + x, this.sy + y, img.app.get_color(), mut change)
					img.set_raw(img.mx + x, img.my + y, img.app.get_color(), mut change)
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

		mut last_x := 0
		mut last_y := 0

		for angle in 0 .. 360 {
			rad := f32(angle) * (f32(math.pi) / 180.0)
			x := int(radius_x * math.cos(rad))
			y := int(radius_y * math.sin(rad))

			px := center_x + x - half_size
			py := center_y + y - half_size

			if last_x != 0 && last_y != 0 {
				pp := bresenham(last_x, last_y, px, py)
				for p in pp {
					for xx in 0 .. size {
						for yy in 0 .. size {
							img.set_raw(p.x + xx, p.y + yy, c, mut change)
						}
					}
				}
			} else {
				for xx in 0 .. size {
					for yy in 0 .. size {
						img.set_raw(px + xx, py + yy, c, mut change)
					}
				}
			}

			last_x = px
			last_y = py
		}
		img.push(change)
	}

	img.refresh()

	// Reset
	this.sx = -1
	this.sy = -1
}

// Triangle Tool
struct TriangleTool {
	tool_name string = 'Triangle'
mut:
	count int
	sx    int = -1
	sy    int = -1
}

fn (mut this TriangleTool) draw_hover_fn(a voidptr, ctx &ui.GraphicsContext) {
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

fn (mut this TriangleTool) draw_down_fn(a voidptr, g &ui.GraphicsContext) {
	mut img := unsafe { &Image(a) }

	if this.sx == -1 {
		this.sx = img.mx
		this.sy = img.my
	}

	size := img.app.brush_size

	x_bottom_left := if img.mx >= this.sx { this.sx } else { img.mx }
	x_bottom_right := if img.mx >= this.sx { img.mx } else { this.sx }
	x_top_middle := (x_bottom_right + x_bottom_left) / 2

	y_bottom := if img.my >= this.sy { img.my } else { this.sy }
	y_top := if img.my >= this.sy { this.sy } else { img.my }

	if this.sx != -1 {
		// Draw triangle preview
		img.draw_line(x_top_middle, y_top, x_bottom_left, y_bottom, size, g)
		img.draw_line(x_bottom_left, y_bottom, x_bottom_right, y_bottom, size, g)
		img.draw_line(x_bottom_right, y_bottom, x_top_middle, y_top, size, g)
	}
}

fn (mut img Image) draw_line(x1 int, y1 int, x2 int, y2 int, size int, g &ui.GraphicsContext) {
	dx := abs(x2 - x1)
	dy := abs(y2 - y1)
	sx := if x1 < x2 { 1 } else { -1 }
	sy := if y1 < y2 { 1 } else { -1 }
	mut err := dx - dy

	mut x := x1
	mut y := y1

	// no_round := true // !img.app.settings.round_ends

	for {
		aa, bb := img.get_point_screen_pos(x, y)
		g.gg.draw_rect_empty(aa - ((size / 2) * img.zoom), bb - ((size / 2) * img.zoom),
			img.zoom * size, img.zoom * size, g.theme.accent_fill)

		if x == x2 && y == y2 {
			break
		}
		e2 := 2 * err
		if e2 > -dy {
			err -= dy
			x += sx
		}
		if e2 < dx {
			err += dx
			y += sy
		}
	}

	// Draw rounded edges
	// TODO
	// if !no_round {
	// draw_circle_filled(mut img, x1, y1, size / 2, c, mut change)
	// draw_circle_filled(mut img, x2, y2, size / 2, c, mut change)
	// }
}

fn (mut this TriangleTool) draw_click_fn(a voidptr, b &ui.GraphicsContext) {
	mut img := unsafe { &Image(a) }

	size := img.app.brush_size

	c := img.app.get_color()

	mut change := Multichange.new()

	x_bottom_left := if img.mx >= this.sx { this.sx } else { img.mx }
	x_bottom_right := if img.mx >= this.sx { img.mx } else { this.sx }
	x_top_middle := (x_bottom_right + x_bottom_left) / 2

	y_bottom := if img.my >= this.sy { img.my } else { this.sy }
	y_top := if img.my >= this.sy { this.sy } else { img.my }

	if this.sx != -1 {
		// Draw the sides of the triangle with the specified size
		img.set_line(x_top_middle, y_top, x_bottom_left, y_bottom, c, size, mut change)
		img.set_line(x_bottom_left, y_bottom, x_bottom_right, y_bottom, c, size, mut change)
		img.set_line(x_bottom_right, y_bottom, x_top_middle, y_top, c, size, mut change)
	}

	img.push(change)
	img.refresh()

	// Reset
	this.sx = -1
	this.sy = -1
}

// Diamond Tool
struct DiamondTool {
	tool_name string = 'Diamond'
mut:
	count int
	sx    int = -1
	sy    int = -1
}

fn (mut this DiamondTool) draw_hover_fn(a voidptr, ctx &ui.GraphicsContext) {
	mut img := unsafe { &Image(a) }

	pix := img.zoom

	ctx.gg.draw_rounded_rect_filled(img.sx, img.sy, pix, pix, 4, ctx.theme.accent_fill)
	ctx.gg.draw_rounded_rect_filled(img.sx + 1, img.sy + 1, pix - 2, pix - 2, 4, img.app.get_color())
}

fn (mut this DiamondTool) draw_down_fn(a voidptr, g &ui.GraphicsContext) {
	mut img := unsafe { &Image(a) }

	if this.sx == -1 {
		this.sx = img.mx
		this.sy = img.my
	}

	size := img.app.brush_size

	x_left := if img.mx >= this.sx { this.sx } else { img.mx }
	x_right := if img.mx >= this.sx { img.mx } else { this.sx }
	x_middle := (x_right + x_left) / 2

	y_bottom := if img.my >= this.sy { img.my } else { this.sy }
	y_top := if img.my >= this.sy { this.sy } else { img.my }
	y_middle := (y_top + y_bottom) / 2

	if this.sx != -1 {
		// Draw diamond preview
		img.draw_line(x_middle, y_top, x_left, y_middle, size, g)
		img.draw_line(x_left, y_middle, x_middle, y_bottom, size, g)
		img.draw_line(x_middle, y_bottom, x_right, y_middle, size, g)
		img.draw_line(x_right, y_middle, x_middle, y_top, size, g)
	}
}

fn (mut this DiamondTool) draw_click_fn(a voidptr, b &ui.GraphicsContext) {
	mut img := unsafe { &Image(a) }

	size := img.app.brush_size

	c := img.app.get_color()

	mut change := Multichange.new()

	x_left := if img.mx >= this.sx { this.sx } else { img.mx }
	x_right := if img.mx >= this.sx { img.mx } else { this.sx }
	x_middle := (x_right + x_left) / 2

	y_bottom := if img.my >= this.sy { img.my } else { this.sy }
	y_top := if img.my >= this.sy { this.sy } else { img.my }
	y_middle := (y_top + y_bottom) / 2

	if this.sx != -1 {
		// Draw the sides of the diamond with the specified size
		img.set_line(x_middle, y_top, x_left, y_middle, c, size, mut change)
		img.set_line(x_left, y_middle, x_middle, y_bottom, c, size, mut change)
		img.set_line(x_middle, y_bottom, x_right, y_middle, c, size, mut change)
		img.set_line(x_right, y_middle, x_middle, y_top, c, size, mut change)
	}

	img.push(change)
	img.refresh()

	// Reset
	this.sx = -1
	this.sy = -1
}
