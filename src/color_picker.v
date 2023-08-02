module main

import iui as ui
import gx
import math

struct ColorPicker {
	btn   &ui.Button
	modal &ui.Modal
mut:
	slid    &ui.Slider
	aslid   &ui.Slider
	mx      int
	my      int
	h       f64
	s       f64
	v       f64
	h_field &ui.TextField
	s_field &ui.TextField
	v_field &ui.TextField
	r_field &ui.TextField
	g_field &ui.TextField
	b_field &ui.TextField
	a_field &ui.TextField
	color   gx.Color
}

fn color_picker(mut win ui.Window, val gx.Color) &ColorPicker {
	mut cim := 0
	if 'HSL' in win.id_map {
		hsl := &int(win.id_map['HSL'])
		cim = *hsl
	}

	mut btn := ui.button_with_icon(cim)
	btn.set_area_filled(false)
	btn.set_bounds(14, 8, 256, 256)
	btn.after_draw_event_fn = hsl_btn_draw_evnt

	mut slide := ui.new_slider(
		min: 0
		max: 100
		dir: .vert
	)
	slide.after_draw_event_fn = slid_draw_evnt

	slide.set_bounds(280, 8, 41, 256)

	mut modal := ui.modal(win, 'HSV Color Picker')
	modal.needs_init = false
	modal.in_width = 510
	modal.in_height = 390
	modal.top_off = 25
	modal.add_child(btn)
	modal.add_child(slide)

	mut aslid := ui.new_slider(
		min: 0
		max: 255
		dir: .vert
	)
	aslid.set_bounds(333, 8, 28, 256)
	aslid.after_draw_event_fn = aslid_draw_evnt
	modal.add_child(aslid)

	mut close := modal.create_close_btn(mut win, false)
	y := 345

	close.set_click(default_modal_close_fn)
	close.set_bounds(16, y, 222, 30)

	mut can := modal.create_close_btn(mut win, true)
	can.text = 'Cancel'
	can.set_bounds(252, y, 222, 30)

	mut vbox := ui.vbox(win)
	vbox.set_pos(376, 8)
	mut lbl := ui.label(win, ' ')
	lbl.set_bounds(0, 1, 4, 40)

	aha, mut ah := number_sect(win, 'H')
	asa, mut ass := number_sect(win, 'S')
	ava, mut av := number_sect(win, 'V')

	rb, mut rf := number_sect(win, 'R')
	gb, mut gf := number_sect(win, 'G')
	bb, mut bf := number_sect(win, 'B')
	ab, mut af := number_sect(win, 'A')

	vbox.add_child(aha)
	vbox.add_child(asa)
	vbox.add_child(ava)
	vbox.add_child(lbl)
	vbox.add_child(rb)
	vbox.add_child(gb)
	vbox.add_child(bb)
	vbox.add_child(ab)

	modal.add_child(vbox)

	mut cp := &ColorPicker{
		btn: btn
		slid: slide
		aslid: aslid
		modal: modal
		h_field: ah
		s_field: ass
		v_field: av
		r_field: rf
		g_field: gf
		b_field: bf
		a_field: af
	}
	cp.load_rgb(val)
	win.id_map['color_picker'] = cp
	return cp
}

pub fn default_modal_close_fn(mut win ui.Window, btn ui.Button) {
	mut cp := win.get[&ColorPicker]('color_picker')
	mut app := win.get[&App]('app')
	app.set_color(cp.color)
	win.components = win.components.filter(mut it !is ui.Modal)
}

fn (mut cp ColorPicker) load_rgb(color gx.Color) {
	h, s, v := rgb_to_hsv(color)
	cp.load_hsv(h, s, v)
	cp.a_field.text = '${color.a}'
	cp.color.a = color.a
	cp.update_text()
	cp.a_field.text = '${color.a}'
	cp.aslid.cur = 255 - color.a
}

fn (mut cp ColorPicker) load_hsv(h f64, s f64, v f64) {
	w := 256

	my := int((((s * w) - w) * -1) + 0)
	mx := int(h * w)

	cp.mx = mx
	cp.my = my

	cur := 100 - f32(100 * v)
	cp.slid.scroll = false
	cp.aslid.scroll = false
	cp.slid.cur = cur
	cp.v = 100 * v
	cp.h = h
	cp.s = s

	cp.h_field.text = roun(h, 4)
	cp.s_field.text = roun(s, 4)
	cp.v_field.text = '${int(v * 100)}'
}

fn roun(a f64, place int) string {
	return '${a}'.substr_ni(0, place)
}

fn slid_draw_evnt(mut win ui.Window, mut com ui.Component) {
	mut cp := win.get[&ColorPicker]('color_picker')

	for i in 0 .. 33 {
		v := 100 - (i * 3)
		vp := f32(v) / 100
		color := hsv_to_rgb(cp.h, cp.s, vp)
		y := com.ry + int(7.75 * i)
		win.gg.draw_rect_filled(com.rx, y + 1, com.width - 1, 8, color)
	}

	if mut com is ui.Slider {
		mut per := com.cur / com.max
		ts := 12
		wid := (com.height * per) - per * ts
		if com.is_mouse_down {
			cp.v_field.text = '${100 - com.cur}'
		}
		win.gg.draw_rounded_rect_filled(com.rx, com.ry + wid, com.width, ts, 32, win.theme.scroll_bar_color)
		win.gg.draw_rounded_rect_empty(com.rx, com.ry + wid, com.width, ts, 32, gx.blue)
	}
}

fn aslid_draw_evnt(mut win ui.Window, mut com ui.Component) {
	mut cp := win.get[&ColorPicker]('color_picker')

	cpc := cp.color
	len := 16
	spa := 16

	aa := gx.rgb(150, 150, 150)
	bb := gx.rgb(255, 255, 255)

	mut cc := false
	for i in 0 .. len {
		val := 255 - (i * spa)
		space := spa
		color := gx.rgba(cpc.r, cpc.g, cpc.b, u8(val))
		y := com.ry + int(space * i)

		ca := if cc { aa } else { bb }
		cb := if cc { bb } else { aa }
		fw := com.width / 2

		win.gg.draw_rect_filled(com.rx, y, fw, space, ca)
		win.gg.draw_rect_filled(com.rx + fw, y, fw - 1, space, cb)

		win.gg.draw_rect_filled(com.rx, y, com.width - 1, space, color)
		cc = !cc
	}

	if mut com is ui.Slider {
		com.thumb_wid = 1
		mut per := com.cur / com.max
		ts := 12
		wid := (com.height * per) - per * ts
		if com.is_mouse_down {
			cur := 255 - u8(com.cur)
			cp.a_field.text = '${cur}'
			cp.update_text()
		}
		win.gg.draw_rounded_rect_filled(com.rx, com.ry + wid, com.width, ts, 32, win.theme.scroll_bar_color)
		win.gg.draw_rounded_rect_empty(com.rx, com.ry + wid, com.width, ts, 32, gx.blue)
	}
}

fn (mut cp ColorPicker) update_text() {
	cp.h_field.text = roun(cp.h, 5)
	cp.s_field.text = roun(cp.s, 5)
	cp.v_field.text = roun(cp.v, 2)

	color := hsv_to_rgb(cp.h, cp.s, f32(cp.v) / 100)
	cp.r_field.text = '${color.r}'
	cp.g_field.text = '${color.g}'
	cp.b_field.text = '${color.b}'

	cp.h_field.carrot_left = cp.h_field.text.len
	cp.s_field.carrot_left = cp.s_field.text.len
	cp.v_field.carrot_left = cp.v_field.text.len
	cp.r_field.carrot_left = cp.r_field.text.len
	cp.g_field.carrot_left = cp.g_field.text.len
	cp.b_field.carrot_left = cp.b_field.text.len
	cp.a_field.carrot_left = cp.a_field.text.len
	cp.color = gx.rgba(color.r, color.g, color.b, cp.a_field.text.u8())
}

fn hsl_btn_draw_evnt(mut win ui.Window, com &ui.Component) {
	mut cp := win.get[&ColorPicker]('color_picker')
	if com.is_mouse_down {
		cp.mx = math.min(win.mouse_x, cp.btn.rx + cp.btn.width)
		cp.my = math.min(win.mouse_y, cp.btn.ry + cp.btn.height)
		cp.mx = math.max(cp.btn.rx, cp.mx) - cp.btn.rx
		cp.my = math.max(cp.btn.ry, cp.my) - cp.btn.ry

		w := 256
		cp.h = (f32(cp.mx) / w)
		cp.s = (f32(w - (cp.my)) / w)
		cp.v = 100 - cp.slid.cur

		cp.update_text()

		color := hsv_to_rgb(cp.h, cp.s, f32(cp.v) / 100)
		cp.color = gx.rgba(color.r, color.g, color.b, cp.a_field.text.u8())
	}
	nv := 100 - cp.slid.cur

	if cp.v != nv {
		cp.update_text()
	}
	cp.v = nv
	x := cp.mx - 7 + com.rx
	win.gg.draw_rounded_rect_empty(x, cp.my - 7 + com.ry, 16, 16, 32, gx.white)
	win.gg.draw_rounded_rect_empty(x - 1, cp.my - 8 + com.ry, 16, 16, 32, gx.blue)

	y := cp.btn.ry + cp.btn.height + 12
	win.gg.draw_rect_filled(cp.btn.rx, y, 454, 24, cp.color)
	win.gg.draw_text(cp.btn.rx, y + 30, 'Result: ${cp.color.to_css_string()}', gx.TextCfg{
		size: win.font_size
	})
}

fn hsv_num_box_change_evnt(win &ui.Window, mut com ui.TextField) {
	mut cp := win.get[&ColorPicker]('color_picker')

	h := cp.h_field.text.f64()
	s := cp.s_field.text.f64()
	v := cp.v_field.text.f64() / 100

	cp.load_hsv(h, s, v)
}

fn rgb_num_box_change_evnt(win &ui.Window, mut com ui.TextField) {
	mut cp := win.get[&ColorPicker]('color_picker')

	r := cp.r_field.text.u8()
	g := cp.g_field.text.u8()
	b := cp.b_field.text.u8()
	a := cp.a_field.text.u8()

	cp.load_rgb(gx.rgba(r, g, b, a))
}

fn number_sect(win &ui.Window, txt string) (&ui.HBox, &ui.TextField) {
	mut hbox := ui.hbox(win)

	mut numfield := ui.numeric_field(255)
	numfield.set_bounds(0, 0, 95, 26)
	if txt == 'H' || txt == 'S' || txt == 'V' {
		numfield.text_change_event_fn = hsv_num_box_change_evnt
	} else {
		numfield.text_change_event_fn = rgb_num_box_change_evnt
	}

	mut lbl := ui.label(win, txt)
	lbl.pack()
	lbl.draw_event_fn = fn (mut win ui.Window, mut com ui.Component) {
		com.x = 4
		com.y = 5
		com.width = 14
	}

	hbox.add_child(numfield)
	hbox.add_child(lbl)
	hbox.set_bounds(0, 4, 300, 35)
	return hbox, numfield
}
