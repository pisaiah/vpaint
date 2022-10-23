module main

// import gg
import gx
import iui as ui

fn (mut app App) make_hsl_image(data []u8) &ui.Button {
	mut win := app.win
	mut gg := win.gg
	gg_im := gg.create_image_from_byte_array(data)

	mut cim := 0
	if 'HSL' in win.id_map {
		hsl := &int(win.id_map['HSL'])
		cim = *hsl
	} else {
		cim = gg.cache_image(gg_im)
		win.id_map['HSL'] = &cim
		return unsafe { nil }
	}

	mut btn := ui.button_with_icon(cim)
	btn.set_bounds(16, 16, 256, 256)
	btn.after_draw_event_fn = hsl_draw_evnt

	// if 'color_data' in win.id_map {
	// mut color_data := &HSLData(win.id_map['color_data'])
	app.color_data.set_color(app.get_color())
	btn.user_data = app.color_data
	/*} else {
		mut color_data := &HSLData{
			//win: win
		}
		color_data.set_color(gx.black)
		btn.user_data = color_data
		win.id_map['color_data'] = color_data
	}*/

	return btn
}

struct HSLData {
mut:
	slid  &ui.Slider
	vs    int
	mx    int
	my    int
	rx    int
	ry    int
	color gx.Color
	h     int
	s     int
	v     f32
	a     u8 = 255
}

fn (mut data HSLData) set_hsv(h int, s int, v int) {
}

fn (mut data HSLData) set_color(c gx.Color) {
	data.set_rgb(c.r, c.g, c.b, c.a)
}

fn (mut data HSLData) set_rgb(r u8, g u8, b u8, a u8) {
	h, s, v := rgb_to_hsv(gx.rgba(r, g, b, a))

	data.h = int(h * 360)
	data.s = int(s * 100)
	data.v = f32(v)
	data.a = a
	mut rgb := hsv_to_rgb(h, s, f32(data.v) / 100)
	rgb.a = a
	data.color = gx.rgba(r, g, b, a)

	mx := (h * 256) + data.rx
	my := (-((s * 256) - 256)) + data.ry

	data.mx = int(mx)
	data.my = int(my)

	vs := -(f32(v * 100) - 100)
	data.vs = int(vs)
	data.a = a
}

fn (mut data HSLData) clamp_values(rx int, ry int, w int, h int) {
	if data.mx > rx + w {
		data.mx = rx + w
	}

	if data.my > ry + h {
		data.my = ry + h
	}

	if data.mx < rx {
		data.mx = rx
	}

	if data.my < ry {
		data.my = ry
	}
}

fn hsl_draw_evnt(win &ui.Window, mut com ui.Component) {
	mut mx := win.mouse_x
	mut my := win.mouse_y

	if mut com is ui.Button {
		mut data := &HSLData(com.user_data)
		data.rx = com.rx
		data.ry = com.ry

		mut v_slide := &ui.Slider(win.id_map['v_slide'])

		if data.vs != v_slide.cur && data.vs > -1 {
			v_slide.cur = data.vs
			data.vs = -1
		}

		if com.is_mouse_down || 100 - v_slide.cur != data.v {
			if mx <= com.rx + com.width {
				data.mx = mx
				data.my = my
				data.clamp_values(com.rx, com.ry, com.width, com.height)
			}

			h_per := f32(data.mx - com.rx) / 256
			s_per := f32(256 - (data.my - com.ry)) / 256

			data.h = int(h_per * 360)
			data.s = int(s_per * 100)
			data.v = 100 - v_slide.cur
			mut rgb := hsv_to_rgb(h_per, s_per, f32(data.v) / 100)
			rgb.a = data.a
			data.color = rgb

			mut r_box := &ui.TextField(win.id_map['rgb-r'])
			mut g_box := &ui.TextField(win.id_map['rgb-g'])
			mut b_box := &ui.TextField(win.id_map['rgb-b'])
			mut a_box := &ui.TextField(win.id_map['rgb-a'])

			r_box.text = '$rgb.r'
			g_box.text = '$rgb.g'
			b_box.text = '$rgb.b'

			// a_box.text = '$rgb.a'
		}
		data.clamp_values(com.rx, com.ry, com.width, com.height)
		mx = data.mx
		my = data.my

		mut debug := &ui.Label(win.id_map['color_debug'])

		debug.text = 'Debug:\nhsv($data.h, $data.s, $data.v)\nrgb($data.color)'
		debug.pack()
		win.gg.draw_rect_filled(debug.rx, debug.ry + debug.height, 128, 64, data.color)
	}

	win.gg.draw_rounded_rect_empty(mx - 8, my - 8, 16, 16, 16, gx.blue)
}

fn rgb_btn_click(mut win ui.Window, btn voidptr, dataa voidptr) {
	mut app := &App(win.id_map['app'])

	mut modal := ui.modal(win, 'Edit Colors')
	modal.in_width = 600
	modal.in_height = 410
	modal.top_off = 25
	modal.draw_event_fn = rgb_modal_draw_event
	modal.needs_init = false

	mut close := modal.create_close_btn(mut win, false)
	y := 363
	close.set_click(default_modal_close_fn)
	close.set_bounds(32, y, 260, 30)

	mut can := modal.create_close_btn(mut win, true)
	can.text = 'Cancel'
	can.set_bounds(310, y, 260, 30)

	img_file := $embed_file('assets/test.png')
	file_data := img_file.to_bytes()
	mut hsl_im := app.make_hsl_image(file_data)

	mut v_slide := ui.new_slider(
		min: 0
		max: 100
		dir: .vert
	)
	v_slide.thumb_wid = 15
	v_slide.scroll = false
	v_slide.set_bounds(290, 16, 42, 256)
	win.id_map['v_slide'] = v_slide

	v_slide.after_draw_event_fn = fn (mut win ui.Window, mut com ui.Component) {
		mut app := &App(win.id_map['app'])
		mut data := app.color_data
		mut v := 99

		h := f32(data.h) / 360
		s := f32(data.s) / 100

		hei := 8
		for i in 0 .. 32 {
			mut rgb := hsv_to_rgb(h, s, f32(v) / 100)
			y := com.ry + 1
			win.gg.draw_rect_filled(com.rx + 1, y + (i * hei), com.width - 3, hei, rgb)
			v -= 3
		}

		if mut com is ui.Slider {
			mut per := com.cur / com.max
			wid := (com.height * per) - per * com.thumb_wid
			win.gg.draw_rounded_rect_filled(com.rx, com.ry + wid, com.width, com.thumb_wid,
				32, win.theme.scroll_bar_color)
			win.gg.draw_rounded_rect_empty(com.rx, com.ry + wid, com.width, com.thumb_wid,
				32, gx.blue)
		}
	}

	app.color_data.slid = v_slide

	mut debug := ui.label(win, 'Debug:')
	debug.set_bounds(355, 24, 200, 256)
	win.id_map['color_debug'] = &debug

	mut vbox := ui.vbox(win)

	mut r_box := app.num_field('rgb-r', 'Red', 0)
	mut g_box := app.num_field('rgb-g', 'Green', 0)
	mut b_box := app.num_field('rgb-b', 'Blue', 0)
	mut a_box := app.num_field('rgb-a', 'Alpha', 255)

	mut lbl := ui.label(win, 'RGBA:')
	lbl.pack()

	vbox.add_child(lbl)
	vbox.add_child(r_box)
	vbox.add_child(g_box)
	vbox.add_child(b_box)
	vbox.add_child(a_box)
	vbox.set_pos(370, 150)
	vbox.pack()

	modal.add_child(hsl_im)
	modal.add_child(v_slide)
	modal.add_child(debug)
	modal.add_child(vbox)
	modal.add_child(close)
	modal.add_child(can)
	win.add_child(modal)
}

fn (mut app App) num_field(id string, name string, val int) &ui.HBox {
	mut hbox := ui.hbox(app.win)
	mut box := ui.numeric_field(val)
	box.set_id(mut app.win, id)
	box.set_bounds(0, 0, 100, 32)
	box.text_change_event_fn = num_box_change_evnt
	hbox.add_child(box)

	mut lbl := ui.label(app.win, name)
	lbl.set_bounds(8, 8, 120, 32)
	hbox.add_child(lbl)
	hbox.pack()

	return hbox
}

fn num_box_change_evnt(win &ui.Window, mut com ui.TextField) {
	val := com.text.int()

	mut app := &App(win.id_map['app'])

	r_box := &ui.TextField(win.id_map['rgb-r'])
	g_box := &ui.TextField(win.id_map['rgb-g'])
	b_box := &ui.TextField(win.id_map['rgb-b'])
	a_box := &ui.TextField(win.id_map['rgb-a'])

	app.color_data.set_rgb(r_box.text.u8(), g_box.text.u8(), b_box.text.u8(), a_box.text.u8())

	dump(val)
}

pub fn default_modal_close_fn(mut win ui.Window, btn ui.Button) {
	mut app := &App(win.id_map['app'])

	app.set_color(app.color_data.color)
	win.components = win.components.filter(mut it !is ui.Modal)
}

fn rgb_modal_draw_event(mut win ui.Window, mut com ui.Component) {
	bottom_color := gx.rgb(230, 230, 230)
	bottom_border := gx.rgb(210, 210, 210)

	if mut com is ui.Modal {
		x := com.xs + 5
		y := com.top_off + 377
		wid := 589

		win.gg.draw_rect_filled(x, y, wid, 60, bottom_color)
		win.gg.draw_line(x, y, x + wid, y, bottom_border)
	}
}
