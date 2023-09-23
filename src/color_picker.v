module main

import iui as ui
import gx
import math

struct ColorPicker {
	btn &ui.Button
mut:
	bw      int = 250
	modal   &ui.Modal
	slid    &ui.Slider
	aslid   &ui.Slider
	mx      int
	my      int
	h       f64
	s       int
	v       f64
	h_field &ui.TextField
	s_field &ui.TextField
	v_field &ui.TextField
	r_field &ui.TextField
	// g_field &ui.TextField
	// b_field &ui.TextField
	a_field &ui.TextField
	color   gx.Color
}

fn modal_draw(mut e ui.DrawEvent) {
	h := e.target.height
	if h > 1 && h < 700 {
		mut tar := e.target
		if mut tar is ui.Modal {
			tar.top_off = 2
		}
	}
	if h > 700 {
		mut tar := e.target
		if mut tar is ui.Modal {
			tar.top_off = (tar.height / 2) - (tar.in_height)
		}
	}
}

fn color_picker(mut win ui.Window, val gx.Color) &ColorPicker {
	mut cim := 0
	if 'HSL' in win.id_map {
		hsl := &int(win.id_map['HSL'])
		cim = *hsl
	}

	mut btn := ui.button_with_icon(cim)
	btn.set_area_filled(false)
	btn.after_draw_event_fn = hsl_btn_draw_evnt

	mut slide := ui.Slider.new(
		min: 0
		max: 100
		dir: .vert
	)
	slide.after_draw_event_fn = slid_draw_evnt

	mut modal := ui.Modal.new(title: 'HSV Color Picker')
	modal.needs_init = false
	modal.in_width = 465
	modal.in_height = 335
	modal.top_off = 20
	modal.add_child(btn)
	modal.add_child(slide)
	modal.subscribe_event('draw', modal_draw)

	mut aslid := ui.Slider.new(
		min: 0
		max: 255
		dir: .vert
	)
	aslid.after_draw_event_fn = aslid_draw_evnt
	modal.add_child(aslid)

	mut close := modal.create_close_btn(mut win, false)
	y := 295

	close.subscribe_event('mouse_up', default_modal_close_fn)
	close.set_bounds(16, y, 216, 30)

	mut can := modal.create_close_btn(mut win, true)
	can.text = 'Cancel'
	can.set_bounds(245, y, 200, 30)

	mut vbox := ui.Panel.new(
		layout: ui.BoxLayout.new(ori: 1, vgap: 5, hgap: 0)
	)
	vbox.set_pos(364, 2)
	mut lbl := ui.Label.new(text: ' ')
	lbl.set_bounds(0, 1, 4, 23)

	aha, mut ah := number_sect('H')
	asa, mut ass := number_sect('S')
	ava, mut av := number_sect('V')

	mut rb, mut rf := number_sect('R')
	ab, mut af := number_sect('A')

	vbox.add_child(aha)
	vbox.add_child(asa)
	vbox.add_child(ava)
	vbox.add_child(lbl)
	vbox.add_child(ab)

	mut rgb_title := ui.Titlebox.new(text: 'RGB', children: [rb])
	rgb_title.set_bounds(320, 205, 35, 0)

	modal.add_child(rgb_title)

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
		// g_field: gf
		// b_field: bf
		a_field: af
	}

	btn.set_bounds(8, 2, cp.bw, cp.bw)
	slide.set_bounds(268, 2, 42, 256)
	aslid.set_bounds(315, 2, 35, 192)

	cp.load_rgb(val)
	win.id_map['color_picker'] = cp
	return cp
}

// pub fn default_modal_close_fn(mut win ui.Window, btn ui.Button) {
pub fn default_modal_close_fn(mut e ui.MouseEvent) {
	mut win := e.ctx.win
	mut cp := win.get[&ColorPicker]('color_picker')
	mut app := win.get[&App]('app')
	app.set_color(cp.color)
	win.components = win.components.filter(mut it !is ui.Modal)
}

fn (mut cp ColorPicker) load_rgb(color gx.Color) {
	h, s, v := rgb_to_hsv(color)
	cp.load_hsv(h, int(s * 100), v)
	cp.a_field.text = '${color.a}'
	cp.color.a = color.a
	cp.update_text(1)
	cp.a_field.text = '${color.a}'
	cp.aslid.cur = 255 - color.a
}

fn (mut cp ColorPicker) load_hsv(h f64, s int, v f64) {
	w := cp.bw

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
	cp.s_field.text = '${s * 100}' // roun(s, 4)
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
		color := hsv_to_rgb(cp.h, f32(cp.s) / 100, vp)
		y := com.ry + int(7.75 * i)
		win.gg.draw_rect_filled(com.rx, y + 1, com.width - 1, 8, color)
	}

	if mut com is ui.Slider {
		mut per := com.cur / com.max
		ts := 12
		wid := (com.height * per) - per * ts
		if com.is_mouse_down {
			val := 100 - com.cur
			strv := if cp.v == 100 { '100' } else { roun(val, 2) }
			cp.v_field.text = strv //'${100 - com.cur}'
		}
		win.gg.draw_rounded_rect_filled(com.rx, com.ry + wid, com.width, ts, 32, win.theme.scroll_bar_color)
		win.gg.draw_rounded_rect_empty(com.rx, com.ry + wid, com.width, ts, 32, gx.blue)
	}
}

fn aslid_draw_evnt(mut win ui.Window, mut com ui.Component) {
	mut cp := win.get[&ColorPicker]('color_picker')

	cpc := cp.color
	len := 12
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
			cp.update_text(2)
		}
		win.gg.draw_rounded_rect_filled(com.rx, com.ry + wid, com.width, ts, 32, win.theme.scroll_bar_color)
		win.gg.draw_rounded_rect_empty(com.rx, com.ry + wid, com.width, ts, 32, gx.blue)
	}
}

fn (mut cp ColorPicker) update_text(typ u8) {
	cp.h_field.text = roun(cp.h, 5)
	cp.s_field.text = '${cp.s}' // roun(cp.s, 5)
	cp.v_field.text = if cp.v == 100 { '100' } else { roun(cp.v, 2) }

	color := hsv_to_rgb(cp.h, f32(cp.s) / 100, f32(cp.v) / 100)
	// cp.r_field.text = '${color.r}'
	// cp.g_field.text = '${color.g}'
	// cp.b_field.text = '${color.b}'

	cp.r_field.text = '${color.r}, ${color.g}, ${color.b}'

	cp.h_field.carrot_left = cp.h_field.text.len
	cp.s_field.carrot_left = cp.s_field.text.len
	cp.v_field.carrot_left = cp.v_field.text.len

	if typ == 0 {
		cp.r_field.carrot_left = cp.r_field.text.len
	}

	// cp.r_field.carrot_left = cp.r_field.text.len
	// cp.g_field.carrot_left = cp.g_field.text.len
	/// cp.b_field.carrot_left = cp.b_field.text.len
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

		w := cp.bw
		cp.h = (f32(cp.mx) / w)
		cp.s = int((f32(w - (cp.my)) / w) * 100)
		cp.v = 100 - cp.slid.cur

		cp.update_text(0)

		color := hsv_to_rgb(cp.h, f32(cp.s) / 100, f32(cp.v) / 100)
		cp.color = gx.rgba(color.r, color.g, color.b, cp.a_field.text.u8())
	}
	nv := 100 - cp.slid.cur

	if cp.v != nv {
		cp.update_text(2)
	}
	cp.v = nv
	x := cp.mx - 7 + com.rx
	win.gg.draw_rounded_rect_empty(x, cp.my - 7 + com.ry, 16, 16, 32, gx.white)
	win.gg.draw_rounded_rect_empty(x - 1, cp.my - 8 + com.ry, 16, 16, 32, gx.blue)

	y := cp.btn.ry - 32

	ty := cp.btn.ry + cp.btn.height + 4

	cp.modal.text = '${cp.color.to_css_string()}'

	win.gg.draw_rect_filled(cp.btn.rx, ty, cp.bw, 24, cp.color)

	tcolor := gx.rgb(255 - cp.color.r, 255 - cp.color.g, 255 - cp.color.b)

	br := f32(cp.color.r) * 299
	bg := f32(cp.color.g) * 587
	bb := f32(cp.color.b) * 114
	o := (br + bg + bb) / 1000
	tco := if o > 125 { gx.black } else { gx.white }

	win.gg.draw_text(cp.btn.rx + 5, ty + 4, '${cp.color.to_css_string()}', gx.TextCfg{
		size: win.font_size
		color: tco
	})
}

fn hsv_num_box_change_evnt(win &ui.Window, mut com ui.TextField) {
	mut cp := win.get[&ColorPicker]('color_picker')

	h := cp.h_field.text.f64()
	s := cp.s_field.text.int()
	v := cp.v_field.text.f64() / 100

	cp.load_hsv(h, s, v)
}

fn rgb_num_box_change_evnt(win &ui.Window, mut com ui.TextField) {
	mut cp := win.get[&ColorPicker]('color_picker')

	colors := cp.r_field.text.replace(' ', '').split(',')

	if colors.len < 3 {
		mut nt := []string{}
		for col in colors {
			nt << col
		}
		for nt.len < 3 {
			nt << '0'
		}
		cp.r_field.text = nt.join(', ')

		return
	}

	r := colors[0].u8()
	g := colors[1].u8()
	b := colors[2].u8()

	if colors.len > 3 {
		dump(colors.len)
		cp.r_field.text = '0, 0, 0'
	}

	a := cp.a_field.text.u8()

	cp.load_rgb(gx.rgba(r, g, b, a))
}

fn numfield_draw_evnt(mut e ui.DrawEvent) {
	if e.target.text.contains(',') {
		e.target.width = e.ctx.text_width('255, 255, 255') + 20
		return
	}
	e.target.width = e.ctx.text_width('25555') + 20
}

fn number_sect(txt string) (&ui.Panel, &ui.TextField) {
	mut p := ui.Panel.new(
		layout: ui.BoxLayout.new(hgap: 0, vgap: 0)
	)

	mut numfield := ui.numeric_field(255)
	numfield.set_bounds(0, 0, 80, 0)
	if txt == 'H' || txt == 'S' || txt == 'V' {
		numfield.text_change_event_fn = hsv_num_box_change_evnt
	} else {
		numfield.text_change_event_fn = rgb_num_box_change_evnt
	}
	numfield.subscribe_event('draw', numfield_draw_evnt)

	if txt == 'R' {
		p.add_child(numfield)
		return p, numfield
	}

	mut lbl := ui.Label.new(text: txt)
	lbl.pack()
	lbl.set_y(4)

	p.add_child(numfield)
	p.add_child(lbl)
	return p, numfield
}
