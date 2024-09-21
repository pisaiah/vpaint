module main

import iui as ui
import gx
import math

const hue_deg = 359

@[heap]
pub struct ColorPicker {
mut:
	btn     &ui.Button
	modal   &ui.Modal
	slid    &ui.Slider
	aslid   &ui.Slider
	bw      int = 250
	mx      int
	my      int
	color   gx.Color
	h       f64
	s       int
	v       f64
	h_field &ui.TextField
	s_field &ui.TextField
	v_field &ui.TextField
	r_field &ui.TextField
	a_field &ui.TextField
}

pub fn (mut cp ColorPicker) default_modal_close_fn(mut e ui.MouseEvent) {
	mut win := e.ctx.win
	mut app := win.get[&App]('app')
	app.set_color(cp.color)
	win.components = win.components.filter(mut it !is ui.Modal)
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

pub fn ColorPicker.new(c gx.Color) &ColorPicker {
	mut modal := ui.Modal.new(title: 'HSV Color Picker')
	modal.needs_init = false
	modal.in_width = 465
	modal.in_height = 335
	modal.top_off = 20
	modal.subscribe_event('draw', modal_draw)

	mut btn := ui.Button.new(icon: -1)
	btn.set_area_filled(false)

	mut slide := ui.Slider.new(
		min: 0
		max: 101
		dir: .vert
	)

	mut aslid := ui.Slider.new(
		min: 0
		max: 256
		dir: .vert
	)

	mut cp := &ColorPicker{
		btn:     btn
		modal:   modal
		slid:    slide
		aslid:   aslid
		h_field: ui.numeric_field(255)
		s_field: ui.numeric_field(255)
		v_field: ui.numeric_field(255)
		r_field: ui.numeric_field(255)
		a_field: ui.numeric_field(255)
	}
	slide.after_draw_event_fn = cp.slid_draw_evnt
	aslid.after_draw_event_fn = cp.aslid_draw_evnt

	aha := cp.number_sect('H', mut cp.h_field)
	asa := cp.number_sect('S', mut cp.s_field)
	ava := cp.number_sect('V', mut cp.v_field)
	ab := cp.number_sect('A', mut cp.a_field)

	mut rb := cp.number_sect('R', mut cp.r_field)

	mut vbox := ui.Panel.new(
		layout: ui.BoxLayout.new(ori: 1, vgap: 5, hgap: 0)
	)
	vbox.set_pos(355, 2)

	vbox.add_child(aha)
	vbox.add_child(asa)
	vbox.add_child(ava)
	// vbox.add_child(lbl)
	vbox.add_child(ab)

	mut rgb_title := ui.Titlebox.new(
		text:     'RGB'
		children: [rb]
		padding:  4
	)
	rgb_title.set_bounds(320, 205, 35, 0)

	modal.add_child(rgb_title)

	modal.add_child(vbox)

	// Load Given gx.Color
	cp.set_hsv_button_to_rgb(c)
	cp.update_fields(0)

	btn.after_draw_event_fn = cp.hsl_btn_draw_evnt

	btn.set_bounds(8, 2, cp.bw, cp.bw)
	slide.set_bounds(268, 2, 42, 256)
	aslid.set_bounds(315, 2, 35, 192)

	modal.add_child(btn)
	modal.add_child(slide)
	modal.add_child(aslid)

	// close btn
	mut close := modal.make_close_btn(false)
	y := 295

	close.subscribe_event('mouse_up', cp.default_modal_close_fn)
	close.set_bounds(16, y, 216, 30)

	mut can := modal.make_close_btn(true)
	can.text = 'Cancel'
	can.set_bounds(245, y, 200, 30)

	return cp
}

fn roun(a f64, place int) string {
	return '${a}'.substr_ni(0, place)
}

fn (mut cp ColorPicker) slid_draw_evnt(mut win ui.Window, mut com ui.Component) {
	for i in 0 .. 51 {
		v := 100 - (i * 2)
		vp := f32(v) / 100
		color := hsv_to_rgb(cp.h, f32(cp.s) / 100, vp)
		y := com.ry + (5 * i)
		win.gg.draw_rect_filled(com.rx, y, com.width - 1, 5, color)
	}

	if mut com is ui.Slider {
		mut per := com.cur / com.max
		ts := 12
		wid := (com.height * per) - per * ts
		if com.is_mouse_down {
			val := 101 - com.cur
			strv := if cp.v == 100 { '100' } else { roun(val, 2) }
			cp.v_field.text = strv
		}
		win.gg.draw_rounded_rect_filled(com.rx, com.ry + wid, com.width, ts, 32, win.theme.scroll_bar_color)
		win.gg.draw_rounded_rect_empty(com.rx, com.ry + wid, com.width, ts, 32, gx.blue)
	}
}

fn (mut cp ColorPicker) aslid_draw_evnt(mut win ui.Window, mut com ui.Component) {
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
		y := com.ry + space * i

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
			if com.cur == 256 {
				com.cur = 255
			}
			cur := 255 - u8(com.cur)
			cp.a_field.text = '${cur}'
			cp.update_fields(0)
		}
		win.gg.draw_rounded_rect_filled(com.rx, com.ry + wid, com.width, ts, 32, win.theme.scroll_bar_color)
		win.gg.draw_rounded_rect_empty(com.rx, com.ry + wid, com.width, ts, 32, gx.blue)
	}
}

fn (mut cp ColorPicker) hsv_num_box_change_evnt(win &ui.Window, mut com ui.TextField) {
	h := cp.h_field.text.int()
	s := cp.s_field.text.int()
	v := cp.v_field.text.int()

	if h > 360 {
		cp.h_field.text = '359'
	}

	if s > 100 {
		cp.s_field.text = '100'
	}

	if v > 100 {
		cp.v_field.text = '100'
	}

	cp.load_hsv_int(h, s, v)
	cp.update_hsv_m()
}

fn numfield_draw_evnt(mut e ui.DrawEvent) {
	if e.target.text.contains(',') {
		e.target.width = e.ctx.text_width('255, 255, 255') + 20
		return
	}
	e.target.width = e.ctx.text_width('255,255') + 20
}

fn (mut cp ColorPicker) rgb_num_box_change_evnt(win &ui.Window, mut com ui.TextField) {
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
		cp.r_field.text = '0, 0, 0'
	}

	a := cp.a_field.text.u8()

	cp.load_rgb(gx.rgba(r, g, b, a))
}

fn (mut cp ColorPicker) number_sect(txt string, mut numfield ui.TextField) &ui.Panel {
	mut p := ui.Panel.new(
		layout: ui.BoxLayout.new(hgap: 4, vgap: 0)
	)

	numfield.set_bounds(0, 0, 80, 0)
	if txt == 'H' || txt == 'S' || txt == 'V' {
		numfield.text_change_event_fn = cp.hsv_num_box_change_evnt
	} else {
		numfield.text_change_event_fn = cp.rgb_num_box_change_evnt
	}
	numfield.subscribe_event('draw', numfield_draw_evnt)

	if txt == 'R' {
		p.add_child(numfield)
		return p
	}

	mut lbl := ui.Label.new(text: txt)
	lbl.pack()
	lbl.set_y(4)

	p.add_child(numfield)
	p.add_child(lbl)
	return p // , numfield
}

// Set the ColorPicker's HSV to the provided gx.Color
fn (mut cp ColorPicker) set_hsv_button_to_rgb(c gx.Color) {
	mut h, s, v := rgb_to_hsv(c)

	cp.h = h
	cp.s = int(f32(s) * 100)
	cp.v = 100 * v
	color := hsv_to_rgb(cp.h, f32(cp.s) / 100, f32(cp.v) / 100)
	alpha := c.a // cp.a_field.text.u8()
	cp.color = gx.rgba(color.r, color.g, color.b, alpha)

	cp.slid.scroll = false
	cp.aslid.scroll = false
	cp.slid.cur = f32(101 - cp.v)
	cp.aslid.cur = 255 - c.a // cp.a_field.text.u8()
	cp.a_field.text = '${c.a}'

	cp.update_hsv_m()
}

fn (mut cp ColorPicker) update_fields_text(typ int) {
	cp.h_field.text = '${int(cp.h * hue_deg)}'
	cp.s_field.text = '${cp.s}'
	cp.v_field.text = '${int(cp.v)}'

	cp.h_field.carrot_left = cp.h_field.text.len
	cp.s_field.carrot_left = cp.s_field.text.len
	cp.v_field.carrot_left = cp.v_field.text.len

	cp.r_field.text = '${cp.color.r}, ${cp.color.g}, ${cp.color.b}'
}

// Update fields
fn (mut cp ColorPicker) update_fields(typ int) {
	cp.update_fields_text(typ)

	if typ == 0 && !cp.r_field.is_selected {
		cp.r_field.carrot_left = cp.r_field.text.len
	}

	color := hsv_to_rgb(cp.h, f32(cp.s) / 100, f32(cp.v) / 100)
	alpha := cp.a_field.text.u8()
	cp.color = gx.rgba(color.r, color.g, color.b, alpha)
}

fn (mut cp ColorPicker) update_hsv_m() {
	w := cp.bw
	cp.mx = int(cp.h * w)
	cp.my = (-(cp.s * w) / 100) + w
}

fn (mut cp ColorPicker) get_slid_v() f32 {
	val := 101 - cp.slid.cur
	if val < 0 {
		return 0
	}
	if val > 100 {
		return 100
	}

	return val
}

// Turn mouse down (mx, my) into HSV
fn (mut cp ColorPicker) do_hsv_mouse_down(wmx int, wmy int) {
	cp.mx = math.min(wmx, cp.btn.rx + cp.btn.width)
	cp.my = math.min(wmy, cp.btn.ry + cp.btn.height)
	cp.mx = math.max(cp.btn.rx, cp.mx) - cp.btn.rx
	cp.my = math.max(cp.btn.ry, cp.my) - cp.btn.ry

	w := cp.bw
	cp.h = (f32(cp.mx) / w)
	cp.s = int((f32(w - (cp.my)) / w) * 100)
	cp.v = cp.get_slid_v()

	color := hsv_to_rgb(cp.h, f32(cp.s) / 100, f32(cp.v) / 100)
	alpha := cp.a_field.text.u8()

	cp.color = gx.rgba(color.r, color.g, color.b, alpha)

	cp.update_fields(0)
}

fn (mut cp ColorPicker) hsl_btn_draw_evnt(mut win ui.Window, com &ui.Component) {
	if com.is_mouse_down {
		cp.do_hsv_mouse_down(win.mouse_x, win.mouse_y)
	}

	if cp.btn.icon == -1 {
		mut cim := 0
		if 'HSL' in win.id_map {
			hsl := &int(unsafe { win.id_map['HSL'] })
			cim = *hsl
		}
		cp.btn.icon = cim
	}

	nv := cp.get_slid_v()
	if cp.v != nv {
		cp.update_fields(0)
	}
	cp.v = nv

	x := cp.mx - 7 + com.rx
	win.gg.draw_rounded_rect_empty(x, cp.my - 7 + com.ry, 16, 16, 32, gx.white)
	win.gg.draw_rounded_rect_empty(x - 1, cp.my - 8 + com.ry, 16, 16, 32, gx.blue)

	ty := cp.btn.ry + cp.btn.height + 4

	cp.modal.text = '${cp.color.to_css_string()}'

	win.gg.draw_rect_filled(cp.btn.rx, ty, cp.bw, 24, cp.color)

	br := f32(cp.color.r) * 299
	bg := f32(cp.color.g) * 587
	bb := f32(cp.color.b) * 114
	o := (br + bg + bb) / 1000
	tco := if o > 125 { gx.black } else { gx.white }

	win.gg.draw_text(cp.btn.rx + 5, ty + 4, '${cp.color.to_css_string()}', gx.TextCfg{
		size:  win.font_size
		color: tco
	})

	win.gg.draw_rect_empty(com.rx, com.ry, com.width, com.height, gx.black)
	win.gg.draw_rect_empty(com.rx - 1, com.ry - 1, com.width + 2, com.height + 2, cp.color)
}

fn (mut cp ColorPicker) load_rgb(color gx.Color) {
	mut h, s, v := rgb_to_hsv(color)

	cp.h = h
	cp.s = int(f32(s) * 100)
	cp.v = 100 * v
	alpha := cp.a_field.text.u8()

	cp.color = gx.rgba(color.r, color.g, color.b, alpha)

	cp.update_hsv_m()
	cp.update_fields_text(0)
}

fn (mut cp ColorPicker) load_hsv_int(h int, s int, v int) {
	cp.h = f32(h) / hue_deg
	cp.s = s
	cp.v = v

	color := hsv_to_rgb(cp.h, f32(cp.s) / 100, f32(cp.v) / 100)
	alpha := cp.a_field.text.u8()
	cp.color = gx.rgba(color.r, color.g, color.b, alpha)

	cp.update_hsv_m()
	cp.update_fields(0)

	cp.slid.scroll = false
	cp.aslid.scroll = false
	cp.slid.cur = f32(101 - cp.v)
	cp.aslid.cur = 255 - cp.a_field.text.u8()
}

fn (mut cp ColorPicker) load_hsv(h f64, s int, v f64) {
}
