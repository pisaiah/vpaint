module main

import gg
import iui as ui
import gx

struct Point {
	x int
	y int
}

fn mouse_down_loop(mut win ui.Window, mut this ui.Component) {
	if this.is_mouse_down && win.bar.tik > 90 {
		mut pixels := &KA(win.id_map['pixels'])
		zoom := win.extra_map['zoom'].f32()

		mut x_slide := &ui.Slider(win.get_from_id('x_slide'))
		mut y_slide := &ui.Slider(win.get_from_id('y_slide'))

		size := gg.window_size()

		mut cx := int((win.mouse_x - (this.x - int(x_slide.cur))) / zoom)
		mut cy := int((win.mouse_y - (this.y - int(y_slide.cur))) / zoom)

		if win.mouse_y < (size.height - 25) && cy < this.height && cx < this.width
			&& (cy * zoom) >= 0 && (cx * zoom) >= 0 {
			gx_color := pixels.color
			color := gx.Color{gx_color.r, gx_color.g, gx_color.b, gx_color.a}
			dsize := pixels.draw_size
			pixels.brush.set_pixels(pixels, cx, cy, color, dsize)

			if pixels.lx != -1 && pixels.cl > 1 {
				mut mids := []Point{}
				mids << Point{pixels.lx, pixels.ly}

				for _ in 0 .. 9 {
					last := mids[mids.len - 1]
					midx_3 := ((last.x + cx) / 2)
					midy_3 := ((last.y + cy) / 2)
					mut dooo := true
					for point in mids {
						if point.x == midx_3 && point.y == midy_3 {
							dooo = false
						}
					}

					if dooo {
						pixels.brush.set_pixels(pixels, midx_3, midy_3, color, dsize)
					}
					mids << Point{midx_3, midy_3}
				}
			}

			pixels.lx = cx
			pixels.ly = cy
			pixels.cl += 1

			// Update canvas
			make_gg_image(mut pixels, mut win, false)
		}
	}
}

fn draw_image(mut win ui.Window, com &ui.Component) {
	mut pixels := &KA(win.id_map['pixels'])
	zoom := win.extra_map['zoom'].f32()
	mut this := *com

	mut x_slide := &ui.Slider(win.get_from_id('x_slide'))
	mut y_slide := &ui.Slider(win.get_from_id('y_slide'))

	mouse_down_loop(mut win, mut this)

	this.height = int(pixels.height * zoom) + 1
	this.width = int(pixels.width * zoom) + 1

	if this.is_mouse_rele {
		pixels.lx = -1
		pixels.ly = -1
		pixels.brush.down_x = -1
		pixels.brush.down_y = -1
		this.is_mouse_rele = false
	}

	if pixels.ggim == -1 {
		make_gg_image(mut pixels, mut win, true)
	}

	// Draw Image
	config := gg.DrawImageConfig{
		img_id: pixels.ggim
		img_rect: gg.Rect{
			x: this.x - int(x_slide.cur)
			y: this.y - int(y_slide.cur)
			width: this.width
			height: this.height
		}
		part_rect: gg.Rect{0, 0, pixels.width, pixels.height}
	}
	gg := win.gg

	// Draw canvas border
	gg.draw_rect_empty(this.x - int(x_slide.cur * zoom), this.y - int(y_slide.cur * zoom),
		this.width + 1, this.height + 1, gx.rgb(215, 215, 215))

	// Draw box-shadow
	draw_box_shadow(this, y_slide, x_slide, gg, win.theme)

	// Draw Image
	gg.draw_image_with_config(config)

	// Draw brush hint
	cx := int((win.mouse_x - this.x) / zoom)
	cy := int((win.mouse_y - this.y) / zoom)

	dsize := pixels.draw_size
	pixels.brush.draw_hint(win, this.x, this.y, cx, cy, pixels.color, dsize)
}

fn color_from_string(st string) gx.Color {
	val := st.split('{')[1].split('}')[0]
	spl := val.split(', ')
	return gx.rgb(spl[0].u8(), spl[1].u8(), spl[2].u8())
}

//
// Draw box shadow around image canvas
//
fn draw_box_shadow(this ui.Component, y_slide &ui.Slider, x_slide &ui.Slider, gg gg.Context, theme ui.Theme) {
	mut shadows := [gx.rgb(171, 183, 203), gx.rgb(176, 188, 207),
		gx.rgb(182, 193, 212), gx.rgb(187, 198, 215), gx.rgb(193, 203, 220),
		gx.rgb(198, 208, 225), gx.rgb(204, 213, 230), gx.rgb(209, 218, 234)]

	tn := theme.name
	if tn.contains('Dark') || tn.contains('Black') {
		// TODO: Dark shadow
		return
	}

	mut si := this.y + this.height + 2
	mut sx := this.x + this.width + 2
	for mut shadow in shadows {
		gg.draw_line(this.x + 10 - int(x_slide.cur), si - int(y_slide.cur), this.width + this.x + 1 - int(x_slide.cur),
			si - int(y_slide.cur), shadow)
		gg.draw_line(sx - int(x_slide.cur), this.y + 10 - int(y_slide.cur), sx - int(x_slide.cur),
			this.y + this.height + 1 - int(y_slide.cur), shadow)
		si += 1
		sx += 1
	}
}

//
// Update the canvas image
//
fn make_gg_image(mut storage KA, mut win ui.Window, first bool) {
	if first {
		storage.ggim = win.gg.new_streaming_image(storage.file.width, storage.file.height,
			4, gg.StreamingImageConfig{
			pixel_format: .rgba8
			mag_filter: .nearest
		})
		win.gg.set_bg_color(gx.rgb(210, 220, 240))
	}
	win.gg.update_pixel_data(storage.ggim, storage.file.data)
}

// Create an new ui.Image
fn make_icon(mut win ui.Window, width int, height int, data []u8) int {
	ggim := win.gg.new_streaming_image(width, height, 4, gg.StreamingImageConfig{
		pixel_format: .rgba8
	})
	win.gg.update_pixel_data(ggim, data.data)
	return ggim
}

//
// Change Window Theme
//
fn theme_click(mut win ui.Window, com ui.MenuItem) {
	text := com.text
	mut theme := ui.theme_by_name(text)
	win.set_theme(theme)

	if text.contains('Dark') {
		background := gx.rgb(25, 42, 77)
		win.gg.set_bg_color(gx.rgb(25, 42, 77))
		win.id_map['background'] = &background
	} else if text.contains('Black') {
		win.gg.set_bg_color(gx.rgb(0, 0, 0))
		background := gx.rgb(0, 0, 0)
		win.id_map['background'] = &background
	} else {
		win.gg.set_bg_color(gx.rgb(210, 220, 240))
		background := gx.rgb(210, 220, 240)
		win.id_map['background'] = &background
	}
}
