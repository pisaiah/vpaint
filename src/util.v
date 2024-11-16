// Excerpt from https://github.com/vlang/ui/blob/master/src/extra_draw.v
module main

import gx
import math

fn wasm_keyboard_show(val bool) {
	$if emscripten ? {
		value := if val { '"keyboard-show"' } else { 'keyboard-hide' }
		C.emscripten_run_script(cstr('iui.trigger = ' + value))
	}
}

// h, s, l in [0,1]
pub fn hsv_to_rgb(h f64, s f64, v f64) gx.Color {
	c := v * s
	x := c * (1.0 - math.abs(math.fmod(h * 6.0, 2.0) - 1.0))
	m := v - c
	mut r, mut g, mut b := 0.0, 0.0, 0.0
	h6 := h * 6.0
	if h6 < 1.0 {
		r, g = c, x
	} else if h6 < 2.0 {
		r, g = x, c
	} else if h6 < 3.0 {
		g, b = c, x
	} else if h6 < 4.0 {
		g, b = x, c
	} else if h6 < 5.0 {
		r, b = x, c
	} else {
		r, b = c, x
	}
	return gx.rgb(u8((r + m) * 255.0), u8((g + m) * 255.0), u8((b + m) * 255.0))
}

pub fn rgb_to_hsv(col gx.Color) (f64, f64, f64) {
	r, g, b := f64(col.r) / 255.0, f64(col.g) / 255.0, f64(col.b) / 255.0
	v, m := f64_max(f64_max(r, g), b), -f64_max(f64_max(-r, -g), -b)
	d := v - m
	mut h, mut s := 0.0, 0.0
	if v == m {
		h = 0
	} else if v == r {
		if g > b {
			h = ((g - b) / d) / 6.0
		} else {
			h = (6.0 - (g - b) / d) / 6
		}
	} else if v == g {
		h = ((b - r) / d + 2.0) / 6.0
	} else if v == b {
		h = ((r - g) / d + 4.0) / 6.0
	}

	if v != 0 {
		s = d / v
	}

	// mirror correction
	if h > 1.0 {
		h = 2.0 - h
	}

	return h, s, v
}

fn abs(a int) int {
	if a < 0 {
		return -a
	}
	return a
}

struct Point {
	x int
	y int
}

@[unsafe]
fn (data &Point) free() {
	// ...
	unsafe {
		free(data.x)
		free(data.y)
		free(data)
	}
}

// https://en.wikipedia.org/wiki/Bresenham%27s_line_algorithm
fn bresenham(x int, y int, x1 int, y1 int) []Point {
	mut x0 := x
	mut y0 := y

	dx := abs(x1 - x0)
	dy := abs(y1 - y0)
	sx := if x0 < x1 { 1 } else { -1 }
	sy := if y0 < y1 { 1 } else { -1 }
	mut err := dx - dy

	mut pp := []Point{}
	pp << Point{x1, y1}

	for x0 != x1 || y0 != y1 {
		pp << Point{x0, y0}
		e2 := 2 * err
		if e2 > -dy {
			err -= dy
			x0 += sx
		}
		if e2 < dx {
			err += dx
			y0 += sy
		}
	}
	return pp
}
